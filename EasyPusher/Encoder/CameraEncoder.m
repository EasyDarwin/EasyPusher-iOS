//
//  CameraEncoder.m
//  EasyCapture
//
//  Created by lyy on 9/7/18.
//  Copyright © 2018 lyy. All rights reserved.
//

#import "CameraEncoder.h"
#include <pthread.h>
#import "H264HWEncoder.h"
#import "AACEncoder.h"
//#import "X264Encoder.h"
#import "AVAssetWriteManager.h"
#import "FolderUtil.h"
#import "URLTool.h"

static CameraEncoder *selfClass = nil;

@interface CameraEncoder ()<H264HWEncoderDelegate, /*X264EncoderDelegate,*/ AACEncoderDelegate, AVAssetWriteManagerDelegate> {
    Easy_Handle handle;
    
    CGSize tempOutputSize;
    
    pthread_mutex_t releaseLock;
    
    CMSimpleQueueRef vbuffQueue;
    CMSimpleQueueRef abuffQueue;
}

@property (nonatomic, strong) dispatch_queue_t encodeQueue;
@property (nonatomic, strong) dispatch_queue_t videoQueue;
@property (nonatomic, strong) dispatch_queue_t audioQueue;

// 负责从 AVCaptureDevice 获得输入数据
@property (nonatomic, strong) AVCaptureDeviceInput *captureDeviceInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;

@property (nonatomic, strong) AVCaptureConnection *videoConnection;
@property (nonatomic, strong) AVCaptureConnection *audioConnection;

@property (nonatomic, strong) AVCaptureSession *videoCaptureSession;

//@property (nonatomic, strong) X264Encoder *x264Encoder;
@property (nonatomic, strong) H264HWEncoder *h264Encoder;
@property (nonatomic, strong) AACEncoder *aacEncoder;

@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic, assign) int sendFrameLength;

@property (nonatomic, strong, readwrite) NSURL *videoUrl;
@property (nonatomic, strong) AVAssetWriteManager *writeManager;
@property (nonatomic, assign) FMRecordState recordState;

@end

@implementation CameraEncoder

#pragma mark - lifecycle

- (int) initCameraWithOutputSize:(CGSize)size resolution:(AVCaptureSessionPreset)resolution {
    self.outputSize = size;
    
    pthread_mutex_init(&releaseLock, 0);
    
    self.encodeQueue = dispatch_queue_create("encodeQueue", NULL);
    
    // 初始化硬编码
    self.h264Encoder = [[H264HWEncoder alloc] init];
    self.h264Encoder.delegate = self;
    
#if TARGET_OS_IPHONE
    self.aacEncoder = [[AACEncoder alloc] init];
    self.aacEncoder.delegate = self;
#endif
    
    self.running = NO;
    
    CMSimpleQueueCreate(kCFAllocatorDefault, 2, &vbuffQueue);
    CMSimpleQueueCreate(kCFAllocatorDefault, 2, &abuffQueue);
    
    self.videoCaptureSession = [[AVCaptureSession alloc] init];
    
    [self setupAudioCapture];
    [self setupVideoCapture:resolution];
    
    selfClass = self;
    
    return 9999;
}

- (void)dealloc {
#if TARGET_OS_IPHONE
    [self.h264Encoder invalidate];
    
    [self teardown];
#endif
    self.running = NO;
    
    pthread_mutex_destroy(&releaseLock);
}

#pragma mark - setter

- (void) setOutputSize:(CGSize)outputSize {
    _outputSize = outputSize;
    
    if (_outputSize.width > 0) {
        tempOutputSize = CGSizeMake(_outputSize.width, _outputSize.height);
    }
}

- (void) setOrientation:(AVCaptureVideoOrientation)orientation {
    _orientation = orientation;
    
    if (self.videoConnection) {
        self.videoConnection.videoOrientation = self.orientation;
    }
}

#pragma mark - 设置采集的 Video 和 Audio 格式，这两个是分开设置的，也就是说，你可以只采集视频

// 音频采集配置
- (void)setupAudioCapture {
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    NSError *error = nil;
    AVCaptureDeviceInput *audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioDevice error:&error];
    if (error) {
        NSLog(@"Error getting audio input device:%@", error.description);
    }
    
    if ([self.videoCaptureSession canAddInput:audioInput]) {
        [self.videoCaptureSession addInput:audioInput];
    }
    
    self.audioQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
    AVCaptureAudioDataOutput *audioOutput = [AVCaptureAudioDataOutput new];
    
    [audioOutput setSampleBufferDelegate:self queue:self.audioQueue];
    
    if ([self.videoCaptureSession canAddOutput:audioOutput]) {
        [self.videoCaptureSession addOutput:audioOutput];
    }
    self.audioConnection = [audioOutput connectionWithMediaType:AVMediaTypeAudio];
}

// 视频采集配置
- (void)setupVideoCapture:(AVCaptureSessionPreset)resolution {
    if ([self.videoCaptureSession canSetSessionPreset:resolution]) {
        self.videoCaptureSession.sessionPreset = resolution;
    }
    
    // 配置采集输入源(摄像头)
    NSError *error = nil;
    // 获得一个采集设备, 例如前置/后置摄像头
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // 用设备初始化一个采集的输入对象
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if (error) {
        NSLog(@"Error getting video input device:%@", error.description);
    }
    
    if ([self.videoCaptureSession canAddInput:videoInput]) {
        [self.videoCaptureSession addInput:videoInput];
    }
    
    // 配置采集输出,即我们取得视频图像的接口
    self.videoQueue = dispatch_queue_create("Video Capture Queue", DISPATCH_QUEUE_SERIAL);
    self.videoOutput = [AVCaptureVideoDataOutput new];
    [self.videoOutput setSampleBufferDelegate:self queue:_videoQueue];
    
    // 配置输出视频图像格式
    [self.videoOutput setVideoSettings:@{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)}];
    self.videoOutput.alwaysDiscardsLateVideoFrames = NO;
//    self.videoOutput.alwaysDiscardsLateVideoFrames = YES;//立即丢弃旧帧，节省内存，默认YES
    if ([self.videoCaptureSession canAddOutput:self.videoOutput]) {
        [self.videoCaptureSession addOutput:self.videoOutput];
    }
    // 设置采集图像的方向,如果不设置，采集回来的图形会是旋转90度的
    self.videoConnection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    self.videoConnection.videoOrientation = self.orientation;
    // 保存Connection,用于SampleBufferDelegate中判断数据来源(video or audio?)
    self.videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
    self.videoConnection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    
    // 将当前硬件采集视频图像显示到屏幕
    // 添加预览
    self.previewLayer = [AVCaptureVideoPreviewLayer  layerWithSession:self.videoCaptureSession];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
}

#pragma mark - public method

// 切换前后摄像头
- (void)swapFrontAndBackCameras {
    // Assume the session is already _running
    NSArray *inputs = self.videoCaptureSession.inputs;
    for (AVCaptureDeviceInput *input in inputs) {
        AVCaptureDevice *device = input.device;
        if ([device hasMediaType:AVMediaTypeVideo]) {
            CATransition *animation = [CATransition animation];
            animation.duration = .5f;
            animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            animation.type = @"oglFlip";
            
            AVCaptureDevice *newCamera = nil;
            if (device.position == AVCaptureDevicePositionFront) {
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
                animation.subtype = kCATransitionFromLeft;  // 动画翻转方向
            } else {
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
                animation.subtype = kCATransitionFromRight; // 动画翻转方向
            }
            
            [self.previewLayer addAnimation:animation forKey:nil];
            
            // beginConfiguration ensures that pending changes are not applied immediately
            [self.videoCaptureSession beginConfiguration];
            [self.videoCaptureSession removeInput:input];
            AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
            
            if ([self.videoCaptureSession canAddInput:newInput]) {
                [self.videoCaptureSession addInput:newInput];
            } else {
                [self.videoCaptureSession addInput:input];
            }
            
            [self.videoCaptureSession removeOutput:self.videoOutput];
            AVCaptureVideoDataOutput *new_videoOutput = [AVCaptureVideoDataOutput new];
            self.videoOutput = new_videoOutput;
            [new_videoOutput setSampleBufferDelegate:self queue:_videoQueue];
            // 配置输出视频图像格式
            NSDictionary *captureSettings = @{(NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
            new_videoOutput.videoSettings = captureSettings;
            new_videoOutput.alwaysDiscardsLateVideoFrames = YES;//立即丢弃旧帧，节省内存，默认YES
            if ([self.videoCaptureSession canAddOutput:new_videoOutput]) {
                [self.videoCaptureSession addOutput:new_videoOutput];
            }
            // 设置采集图像的方向,如果不设置，采集回来的图形会是旋转90度的
            _videoConnection = [new_videoOutput connectionWithMediaType:AVMediaTypeVideo];
            _videoConnection.videoOrientation = self.orientation;
            // 保存Connection,用于SampleBufferDelegate中判断数据来源(video or audio?)
            _videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
            _videoConnection = [new_videoOutput connectionWithMediaType:AVMediaTypeVideo];
            
            // Changes take effect once the outermost commitConfiguration is invoked.
            [self.videoCaptureSession commitConfiguration];
            
            break;
        }
    }
}

// 切换分辨率
- (void) swapResolution:(AVCaptureSessionPreset)resolution {
    [self.videoCaptureSession beginConfiguration];
    
    if ([self.videoCaptureSession canSetSessionPreset:resolution]) {
        self.videoCaptureSession.sessionPreset = resolution;
    }
    
    [self.videoCaptureSession commitConfiguration];
}

- (void) changeCameraStatus:(BOOL) onlyAudio {
    self.onlyAudio = onlyAudio;

//    NSArray *inputs = self.videoCaptureSession.inputs;
//    if (self.onlyAudio) {
//        // 只传音频，则删除视频源
//        for (AVCaptureDeviceInput *input in inputs) {
//            AVCaptureDevice *device = input.device;
//            if ([device hasMediaType:AVMediaTypeVideo]) {
//                [self.videoCaptureSession beginConfiguration];
//
//                [self.videoCaptureSession removeInput:input];
//                [self.videoCaptureSession removeOutput:self.videoOutput];
//
//                [self.videoCaptureSession commitConfiguration];
//            }
//        }
//    } else {
//        if (inputs.count < 2) {
//            AVCaptureDevice *newCamera = nil;
//            AVCaptureDeviceInput *newInput = nil;
//            newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
//            newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
//
//            [self.videoCaptureSession beginConfiguration];
//
//            if ([self.videoCaptureSession canAddInput:newInput]) {
//                [self.videoCaptureSession addInput:newInput];
//            }
//
//            AVCaptureVideoDataOutput *new_videoOutput = [AVCaptureVideoDataOutput new];
//            _videoOutput = new_videoOutput;
//            [new_videoOutput setSampleBufferDelegate:self queue:_videoQueue];
//
//            // 配置输出视频图像格式
//            NSDictionary *captureSettings = @{(NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
//            new_videoOutput.videoSettings = captureSettings;
//            new_videoOutput.alwaysDiscardsLateVideoFrames = YES;
//            if ([self.videoCaptureSession canAddOutput:new_videoOutput]) {
//                [self.videoCaptureSession addOutput:new_videoOutput];
//            }
//
//            // 设置采集图像的方向,如果不设置，采集回来的图形会是旋转90度的
//            _videoConnection = [new_videoOutput connectionWithMediaType:AVMediaTypeVideo];
//            _videoConnection.videoOrientation = self.orientation;
//            // 保存Connection,用于SampleBufferDelegate中判断数据来源(video or audio?)
//            _videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
//            _videoConnection = [new_videoOutput connectionWithMediaType:AVMediaTypeVideo];
//
//            // Changes take effect once the outermost commitConfiguration is invoked.
//            [self.videoCaptureSession commitConfiguration];
//        }
//    }
}

- (void)startRecord {
    if (self.recordState != FMRecordStateRecording) {
        [self.writeManager startWrite];
        self.recordState = FMRecordStateRecording;
    }
}

- (void)stopRecord {
    [self.writeManager stopWrite];
    self.recordState = FMRecordStateFinish;
    
    [self reset];
}

- (void)reset {
    self.recordState = FMRecordStateInit;
    [self setUpWriter];
}

- (void)setUpWriter {
    self.videoUrl = [[NSURL alloc] initFileURLWithPath:[FolderUtil createVideoFilePath]];
    self.writeManager = [[AVAssetWriteManager alloc] initWithURL:self.videoUrl viewType:TypeFullScreen];
    self.writeManager.delegate = self;
}

#pragma mark - private method

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
        if (device.position == position)
            return device;
    
    return nil;
}

- (void) recordCaptureOutput:(AVCaptureOutput*)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection*)connection {
    if (self.recordState != FMRecordStateRecording) {
        return;
    }
    
    @autoreleasepool {
        if(connection == self.videoConnection) {// 视频
            if (!self.writeManager.outputVideoFormatDescription) {
                @synchronized(self) {
                    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
                    self.writeManager.outputVideoFormatDescription = formatDescription;
                }
            } else {
                @synchronized(self) {
                    if (self.writeManager.writeState == FMRecordStateRecording) {
                        [self.writeManager appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeVideo];
                    }
                }
            }
        } else if(connection == self.audioConnection) {// 音频
            if (!self.writeManager.outputAudioFormatDescription) {
                @synchronized(self) {
                    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
                    self.writeManager.outputAudioFormatDescription = formatDescription;
                }
            }
            @synchronized(self) {
                if (self.writeManager.writeState == FMRecordStateRecording) {
                    [self.writeManager appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeAudio];
                }
            }
        }
    }
}

#pragma mark - AVAssetWriteManagerDelegate

- (void)updateWritingProgress:(CGFloat)progress {
//    if (self.delegate && [self.delegate respondsToSelector:@selector(updateRecordingProgress:)]) {
//        [self.delegate updateRecordingProgress:progress];
//    }
}

- (void)finishWriting {
//    self.recordState = FMRecordStateFinish;
}

#pragma mark - 推流流程

- (void)startCapture {
    [self.videoCaptureSession startRunning];
    
    [self setUpWriter];
}

- (void) startCamera:(NSString *)hostUrl {
    NSLog(@"推流地址：%@", hostUrl);
    
    if (handle) {
        return;
    }
    
    if (_outputSize.width <= 0) {
        _outputSize = CGSizeMake(tempOutputSize.width, tempOutputSize.height);
    }
    
    if (handle == NULL) {
        handle = EasyPusher_Create();
        EasyPusher_SetEventCallback(handle, easyPusher_Callback, 1, "123");
    }
    
    EASY_MEDIA_INFO_T mediainfo;
    memset(&mediainfo, 0, sizeof(EASY_MEDIA_INFO_T));
    mediainfo.u32VideoCodec = EASY_SDK_VIDEO_CODEC_H264;
    if (self.onlyAudio) {
        mediainfo.u32VideoFps = ~0; //~0只传音频
    } else {
        mediainfo.u32VideoFps = 20;
    }
    
    mediainfo.u32AudioCodec = EASY_SDK_AUDIO_CODEC_AAC;// SDK output Audio PCMA
    mediainfo.u32AudioSamplerate = 44100;
    mediainfo.u32AudioChannel = 2;
    mediainfo.u32AudioBitsPerSample = 16;
    
    // 解析推流地址（例如hostUrl：rtsp://cloud.easydarwin.org:554/404802.sdp）
    NSString *cutIp = @"";
    NSString *cutPort = @"";
    NSString *cutName = @"";
    
    @try {
        NSString *url = [hostUrl stringByReplacingOccurrencesOfString:@"rtsp://" withString:@""];
        NSArray *arr = [url componentsSeparatedByString:@":"];
        NSArray *arr1 = [arr[1] componentsSeparatedByString:@"/"];
        
        cutIp = arr[0];
        cutPort = arr1[0];
        cutName = arr1[1];
    } @catch (NSException *e) {
        NSLog(@"解析流地址出错：%@", e);
    }
    
    // ip地址
    const char *exprIp = [cutIp UTF8String];
    char *ip = malloc(strlen(exprIp)+1);
    strcpy(ip, exprIp);
    
    // 端口号
    const char *expPort = [cutPort cStringUsingEncoding:NSUTF8StringEncoding];
    char *port = malloc(strlen(expPort) + 1);
    strcpy(port, expPort);
    
    // name
    NSString *nameString = [cutName copy];
    const char *exName = [nameString cStringUsingEncoding:NSUTF8StringEncoding];
    char *name = malloc(strlen(exName)+1);
    strcpy(name, exName);
    
    EasyPusher_StartStream(handle,
                           ip, atoi(port), name,
                           EASY_RTP_OVER_TCP,
                           "admin", "admin",
                           &mediainfo,
                           1024,
                           false);//1M缓冲区
    free(ip);
    free(port);
    free(name);
    
    [self initX264Encoder];
}

- (void) stopCamera {
    if (handle == NULL) {
        return;
    }
    
    self.running = NO;
    [self.h264Encoder invalidate];
    
    // EasyPusher_StopStream完成后，才能继续
    pthread_mutex_lock(&releaseLock);
    
    EasyPusher_StopStream(handle);
    handle = NULL;
    
    pthread_mutex_unlock(&releaseLock);
    
    [self stopRecord];
}

#pragma mark - 连接状态回调

int easyPusher_Callback(int _id, EASY_PUSH_STATE_T _state, EASY_AV_Frame *_frame, void *_userptr) {
    if (_state == EASY_PUSH_STATE_CONNECTING) {
        if (selfClass.delegate) {
            [selfClass.delegate getConnectStatus:@"连接中" isFist:0];
            NSLog(@"连接中");
        }
    } else if (_state == EASY_PUSH_STATE_CONNECTED) {
        if (selfClass.delegate) {
            [selfClass.delegate getConnectStatus:@"连接成功" isFist:0];
            NSLog(@"连接成功");
            selfClass.running = YES;
        }
    } else if (_state == EASY_PUSH_STATE_CONNECT_FAILED) {
        if (selfClass.delegate) {
            [selfClass.delegate getConnectStatus:@"连接失败" isFist:0];
            NSLog(@"连接失败");
        }
    } else if (_state == EASY_PUSH_STATE_CONNECT_ABORT) {
        if (selfClass.delegate) {
            [selfClass.delegate getConnectStatus:@"连接异常中断" isFist:0];
            NSLog(@"连接异常中断");
        }
    } else if (_state == EASY_PUSH_STATE_PUSHING) {
        if (selfClass.delegate) {
            [selfClass.delegate getConnectStatus:@"推流中" isFist:0];
            NSLog(@"推流中");
        }
    } else if (_state == EASY_PUSH_STATE_DISCONNECTED) {
        if (selfClass.delegate) {
            [selfClass.delegate getConnectStatus:@"断开连接" isFist:0];
            NSLog(@"断开连接");
        }
    }
    
    return 0;
}

#pragma mark - AVCaptureAudioDataOutputSampleBufferDelegate

-(void) captureOutput:(AVCaptureOutput*)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection*)connection {
    [self recordCaptureOutput:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];
    
    if (self.running) {
        CFRetain(sampleBuffer);
        
        if(connection == self.videoConnection) {
            dispatch_async(self.encodeQueue, ^{
                if (!self.onlyAudio) {
                    
//                    if ([URLTool gainX264Enxoder]) {
//                        [self.x264Encoder encoding:sampleBuffer];
//                    } else {
                        [self.h264Encoder encode:sampleBuffer size:self.outputSize];
//                    }
                }
                self.outputSize = CGSizeMake(0, 0);// 输出尺寸置空，则不需要再初始化VTCompressionSessionRef
                CFRelease(sampleBuffer);
            });
        } else if(connection == self.audioConnection) {
            dispatch_async(self.encodeQueue, ^{
                [self.aacEncoder encode:sampleBuffer];
                CFRelease(sampleBuffer);
            });
        }
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    NSLog(@"drop frame");
}

#pragma mark - x264

- (void)initX264Encoder {
//    dispatch_sync(self.encodeQueue, ^{
//        NSString *resolution = [URLTool gainResolition];
//        NSArray *s = [resolution componentsSeparatedByString:@"*"];
//        CGSize size = CGSizeMake([s[0] floatValue], [s[1] floatValue]);
//
//        self.x264Encoder = [[X264Encoder alloc] initX264Encoder:size frameRate:30 maxKeyframeInterval:25 bitrate:1024*1000 profileLevel:@""];
//
//        self.x264Encoder.delegate = self;
//    });
}

- (void)teardown {
//    dispatch_sync(self.encodeQueue, ^{
//        [self.x264Encoder teardown];
//    });
}

//#pragma mark - X264EncoderDelegate
//
//- (void)gotX264EncoderData:(NSData *)packet keyFrame:(BOOL)keyFrame timestamp:(CMTime)timestamp error:(NSError*)error {
//    [self dealEncodedData:packet keyFrame:keyFrame timestamp:timestamp error:error];
//}

#pragma mark - H264HWEncoderDelegate declare

- (void)gotH264EncodedData:(NSData *)packet keyFrame:(BOOL)keyFrame timestamp:(CMTime)timestamp error:(NSError*)error {
    [self dealEncodedData:packet keyFrame:keyFrame timestamp:timestamp error:error];
}

- (void) dealEncodedData:(NSData *)packet keyFrame:(BOOL)keyFrame timestamp:(CMTime)timestamp error:(NSError*)error {
    EASY_AV_Frame frame;
    frame.pBuffer = (void*) packet.bytes;
    
    if (frame.pBuffer == NULL) {
        return;
    }
    
    frame.u32AVFrameFlag = EASY_SDK_VIDEO_FRAME_FLAG;
    frame.u32AVFrameLen = (Easy_U32)packet.length;
    frame.u32TimestampSec = 0;
    frame.u32TimestampUsec = 0;
    frame.u32VFrameType = keyFrame ? EASY_SDK_VIDEO_FRAME_I : EASY_SDK_VIDEO_FRAME_P;
    
    if(self.running) {
        int result = EasyPusher_PushFrame(handle, &frame);
        if (result == 0) {
            [self sendPacket:frame.u32AVFrameLen];
        }
    }
}

#if TARGET_OS_IPHONE
#pragma mark - AACEncoderDelegate declare

- (void)gotAACEncodedData:(NSData *)data timestamp:(CMTime)timestamp error:(NSError*)error {
    EASY_AV_Frame frame;
    frame.pBuffer = (void*)[data bytes];
    
    if (frame.pBuffer == NULL) {
        return;
    }
    
    frame.u32AVFrameLen = (Easy_U32)[data length];
    frame.u32VFrameType = EASY_SDK_AUDIO_CODEC_AAC;
    frame.u32AVFrameFlag = EASY_SDK_AUDIO_FRAME_FLAG;
    
    frame.u32TimestampSec= 0;//(Easy_U32)timestamp.value/timestamp.timescale;
    frame.u32TimestampUsec = 0;//timestamp.value%timestamp.timescale;
    
    if (self.running) {
        int result = EasyPusher_PushFrame(handle, &frame);
        if (result == 0) {
            [self sendPacket:frame.u32AVFrameLen];
        }
    }
}

#endif

#pragma mark - 流量检测

- (void) sendPacket:(unsigned int)u32AVFrameLen {
    self.sendFrameLength += u32AVFrameLen;
    
    if (!self.timer) {
        NSTimeInterval period = 1.0; // 设置时间间隔
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        dispatch_source_set_timer(_timer, dispatch_walltime(NULL, 0), period * NSEC_PER_SEC, 0);
        dispatch_source_set_event_handler(_timer, ^{
            [self.delegate sendPacketFrameLength:self.sendFrameLength / 1];
            self.sendFrameLength = 0;
        });
        
        dispatch_resume(self.timer);
    }
}

@end
