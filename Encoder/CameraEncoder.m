//
//  CameraEncoder.m
//  EasyCapture
//
//  Created by phylony on 9/11/16.
//  Copyright © 2016 phylony. All rights reserved.
//
#import "CameraEncoder.h"

//char* ConfigIP		= "121.40.50.44";	//Default EasyDarwin Address
//char* ConfigIP		= "114.55.107.180";
////char* ConfigPort	= "554";			//Default EasyDarwin Port
//char* ConfigPort	= "10554";

char* ConfigName	= "ios11.sdp";//Default Push StreamName
char* ConfigUName	= "admin";			//SDK UserName
char* ConfigPWD		= "admin";			//SDK Password
char* ConfigDHost	= "192.168.66.189";	//SDK Host
char* ConfigDPort	= "80";				//SDK Port
char *ProgName;		//Program Name

static CameraEncoder *selfClass =nil;

@interface CameraEncoder () {
    H264HWEncoder *h264Encoder;
    
    AACEncoder *aacEncoder;
    Easy_I32 isActivated;
    Easy_Pusher_Handle handle;
    
    dispatch_queue_t encodeQueue;
    
//    NSString *h264File;
//    NSString *aacFile;
//    NSFileHandle *fileH264Handle;
//    NSFileHandle *fileAACHandle;
}

@property (nonatomic , strong)AVAssetWriter *videoWriter;
@property (nonatomic , strong)AVAssetWriterInput *videoWriterInput;
@property(nonatomic , strong)AVAssetWriterInputPixelBufferAdaptor *adaptor;
@property(nonatomic ,strong)AVAssetWriterInput *audioWriterInput;

@end

@implementation CameraEncoder

@synthesize running;

- (void)initCameraWithOutputSize:(CGSize)size {
    h264Encoder = [[H264HWEncoder alloc] init];
    [h264Encoder setOutputSize:size];
    h264Encoder.delegate = self;
    
#if TARGET_OS_IPHONE
    aacEncoder = [[AACEncoder alloc] init];
    aacEncoder.delegate = self;
#endif
    
    running = NO;
    /*
     *激活授权码，
     *本Key为3个月临时授权License，如需商业使用，请邮件至support@easydarwin.org申请此产品的授权。
     */
    if (EasyPusher_Activate("6A36334A742F2B32734B77416F6F745A706E5264532F564659584E355548567A614756794931634D5671442F532B424859585A7062695A4359574A76633246414D6A41784E6B566863336C4559584A33615735555A5746745A57467A65513D3D") == 0) {
        if (_delegate) {
            [_delegate getConnectStatus:@"激活成功" isFist:1];
        }
    } else {
        [_delegate getConnectStatus:@"激活失败" isFist:1];
    }
    
    handle = EasyPusher_Create();
    EasyPusher_SetEventCallback(handle,easyPusher_Callback, 1, "123");
    
    _encodeVideoQueue = dispatch_queue_create( "encodeVideoQueue", DISPATCH_QUEUE_SERIAL );
    _encodeAudioQueue = dispatch_queue_create( "encodeAudioQueue", DISPATCH_QUEUE_SERIAL );
    CMSimpleQueueCreate(kCFAllocatorDefault, 2, &vbuffQueue);
    CMSimpleQueueCreate(kCFAllocatorDefault, 2, &abuffQueue);
    _videoCaptureSession = [[AVCaptureSession alloc] init];
    [self setupAudioCapture];
    [self setupVideoCapture];
    
    encodeQueue = dispatch_queue_create("encodeQueue", NULL);
     selfClass =self;
    [self initVideoAudioWriter];
}

- (void)dealloc {
#if TARGET_OS_IPHONE
    [h264Encoder invalidate];
#endif
    running = NO;
}

#pragma mark - Camera Control

- (void)setupAudioCapture {
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    NSError *error = nil;
    AVCaptureDeviceInput *audioInput = [[AVCaptureDeviceInput alloc]initWithDevice:audioDevice error:&error];
    
    if (error) {
        NSLog(@"Error getting audio input device:%@",error.description);
    }
    if ([self.videoCaptureSession canAddInput:audioInput]) {
        [self.videoCaptureSession addInput:audioInput];
    }
    
    self.AudioQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
    AVCaptureAudioDataOutput *audioOutput = [AVCaptureAudioDataOutput new];
    
    [audioOutput setSampleBufferDelegate:self queue:self.AudioQueue];
    
    if ([self.videoCaptureSession canAddOutput:audioOutput]) {
        
        [self.videoCaptureSession addOutput:audioOutput];
    }
    self.audioConnection = [audioOutput connectionWithMediaType:AVMediaTypeAudio];
}

- (void)swapResolution {
    [self.videoCaptureSession beginConfiguration];
    
    NSString *resolution = [[NSUserDefaults standardUserDefaults] objectForKey:@"resolition"];
    if ([resolution isEqualToString:@"480*640"]) {
        if ([self.videoCaptureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
            self.videoCaptureSession.sessionPreset = AVCaptureSessionPreset640x480;
        }
    } else if ([resolution isEqualToString:@"720*1280"]) {
        if ([self.videoCaptureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
            self.videoCaptureSession.sessionPreset = AVCaptureSessionPreset1280x720;
        }
    } else if ([resolution isEqualToString:@"1080*1920"]) {
        if ([self.videoCaptureSession canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
            self.videoCaptureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
        }
    } else if ([resolution isEqualToString:@"288*352"]) {
        if ([self.videoCaptureSession canSetSessionPreset:AVCaptureSessionPreset352x288]) {
            self.videoCaptureSession.sessionPreset = AVCaptureSessionPreset352x288;
        }
    }
    
    [self.videoCaptureSession commitConfiguration];
}

#pragma mark - 设置视频 capture  3
- (void)setupVideoCapture {
//    if ([self.videoCaptureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
//        // 设置分辨率
//        self.videoCaptureSession.sessionPreset = AVCaptureSessionPreset1280x720;
//    }
    
    NSString *resolution = [[NSUserDefaults standardUserDefaults] objectForKey:@"resolition"];
    if ([resolution isEqualToString:@"480*640"]) {
        if ([self.videoCaptureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
            self.videoCaptureSession.sessionPreset = AVCaptureSessionPreset640x480;
        }
    } else if ([resolution isEqualToString:@"720*1280"]) {
        if ([self.videoCaptureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
            self.videoCaptureSession.sessionPreset = AVCaptureSessionPreset1280x720;
        }
    } else if ([resolution isEqualToString:@"1080*1920"]) {
        if ([self.videoCaptureSession canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
            self.videoCaptureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
        }
    } else if ([resolution isEqualToString:@"288*352"]) {
        if ([self.videoCaptureSession canSetSessionPreset:AVCaptureSessionPreset352x288]) {
            self.videoCaptureSession.sessionPreset = AVCaptureSessionPreset352x288;
        }
    }
    
    //设置采集的 Video 和 Audio 格式，这两个是分开设置的，也就是说，你可以只采集视频。
    //配置采集输入源(摄像头)
    
    NSError *error = nil;
    //获得一个采集设备, 例如前置/后置摄像头
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //    videoDevice = [self cameraWithPosition:AVCaptureDevicePositionBack];
    //   videoDevice.position = AVCaptureDevicePositionBack;
    //用设备初始化一个采集的输入对象
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if (error) {
        NSLog(@"Error getting video input device:%@",error.description);
    }
    if ([self.videoCaptureSession canAddInput:videoInput]) {
        [self.videoCaptureSession addInput:videoInput];
    }
    //配置采集输出,即我们取得视频图像的接口
    _videoQueue = dispatch_queue_create("Video Capture Queue", DISPATCH_QUEUE_SERIAL);
    _videoOutput = [AVCaptureVideoDataOutput new];
    [_videoOutput setSampleBufferDelegate:self queue:_videoQueue];
    // 配置输出视频图像格式
    NSDictionary *captureSettings = @{(NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
    _videoOutput.videoSettings = captureSettings;
    _videoOutput.alwaysDiscardsLateVideoFrames = YES;
    if ([self.videoCaptureSession canAddOutput:_videoOutput]) {
        [self.videoCaptureSession addOutput:_videoOutput];
    }
    // 设置采集图像的方向,如果不设置，采集回来的图形会是旋转90度的
    _videoConnection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
    _videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    // 保存Connection,用于SampleBufferDelegate中判断数据来源(video or audio?)
    _videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
    _videoConnection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
    //将当前硬件采集视频图像显示到屏幕
    // 添加预览
    self.previewLayer = [AVCaptureVideoPreviewLayer  layerWithSession:self.videoCaptureSession];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices )
        if ( device.position == position )
            return device;
    return nil;
}

- (void)swapFrontAndBackCameras {
    // Assume the session is already running
    NSArray *inputs =self.videoCaptureSession.inputs;
    for (AVCaptureDeviceInput *input in inputs ) {
        AVCaptureDevice *device = input.device;
        if ( [device hasMediaType:AVMediaTypeVideo] ) {
            AVCaptureDevicePosition position = device.position;
            AVCaptureDevice *newCamera =nil;
            AVCaptureDeviceInput *newInput =nil;
            CATransition *animation = [CATransition animation];
            animation.duration = .5f;
            animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            animation.type = @"oglFlip";

            if (position ==AVCaptureDevicePositionFront){
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
                animation.subtype = kCATransitionFromLeft;//动画翻转方向
            }
            else{
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
                animation.subtype = kCATransitionFromRight;//动画翻转方向
            }
            
            newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
            [self.previewLayer addAnimation:animation forKey:nil];
            // beginConfiguration ensures that pending changes are not applied immediately
         
            [self.videoCaptureSession beginConfiguration];
            [self.videoCaptureSession removeInput:input];
            if ([self.videoCaptureSession canAddInput:newInput]) {
                [self.videoCaptureSession addInput:newInput];
                
            } else {
                 [self.videoCaptureSession addInput:input];
            }
            [self.videoCaptureSession removeOutput:_videoOutput];
            
            AVCaptureVideoDataOutput *  new_videoOutput = [AVCaptureVideoDataOutput new];
            _videoOutput = new_videoOutput;
            [new_videoOutput setSampleBufferDelegate:self queue:_videoQueue];
            // 配置输出视频图像格式
            NSDictionary *captureSettings = @{(NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
            new_videoOutput.videoSettings = captureSettings;
            new_videoOutput.alwaysDiscardsLateVideoFrames = YES;
            if ([self.videoCaptureSession canAddOutput:new_videoOutput]) {
                [self.videoCaptureSession addOutput:new_videoOutput];
            }
            // 设置采集图像的方向,如果不设置，采集回来的图形会是旋转90度的
            _videoConnection = [new_videoOutput connectionWithMediaType:AVMediaTypeVideo];
            _videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
            // 保存Connection,用于SampleBufferDelegate中判断数据来源(video or audio?)
            _videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
            _videoConnection = [new_videoOutput connectionWithMediaType:AVMediaTypeVideo];
           
            // Changes take effect once the outermost commitConfiguration is invoked.
            [self.videoCaptureSession commitConfiguration];
            break;
        }
    }
}

- (void)startCapture
{
    [self.videoCaptureSession startRunning];
}

#pragma mark --开始推流
- (void) startCamera:(NSString *)hostUrl
{
    EASY_MEDIA_INFO_T mediainfo;
    memset(&mediainfo, 0, sizeof(EASY_MEDIA_INFO_T));
    mediainfo.u32VideoCodec = EASY_SDK_VIDEO_CODEC_H264;
    mediainfo.u32VideoFps = 25;
    mediainfo.u32AudioCodec = EASY_SDK_AUDIO_CODEC_AAC;//SDK output Audio PCMA
    mediainfo.u32AudioSamplerate = 44100;
    mediainfo.u32AudioChannel = 2;
//    mediainfo.u32AudioSamplerate = 8000;
//    mediainfo.u32AudioChannel = 1;
    mediainfo.u32AudioBitsPerSample = 16;
    const char *expr = [[[NSUserDefaults standardUserDefaults] objectForKey:@"ConfigIP"] UTF8String];
    char *ConfigIP = malloc(strlen(expr)+1);
    strcpy(ConfigIP, expr);
    const char *exIp = [[[NSUserDefaults standardUserDefaults] objectForKey:@"ConfigPORT"] cStringUsingEncoding:NSUTF8StringEncoding];
    char *ConfigPort = malloc(strlen(exIp) + 1);
    strcpy(ConfigPort, exIp);
  
    NSString *nameString = [hostUrl copy];
    const char *exName = [nameString cStringUsingEncoding:NSUTF8StringEncoding];
    char *name = malloc(strlen(exName)+1);
    strcpy(name, exName);
    
    
    EasyPusher_StartStream(handle, ConfigIP, atoi(ConfigPort), name, "admin", "admin", &mediainfo, 1024, false);//1M缓冲区
    running = YES;
    free(ConfigIP);
    free(ConfigPort);
    free(name);
}

int easyPusher_Callback(int _id, EASY_PUSH_STATE_T _state, EASY_AV_Frame *_frame, void *_userptr)
{
//    const char *expr = [[[NSUserDefaults standardUserDefaults] objectForKey:@"ConfigIP"] UTF8String];
//    char *ConfigIP = malloc(strlen(expr)+1);
//    strcpy(ConfigIP, expr);
//    const char *exIp = [[[NSUserDefaults standardUserDefaults] objectForKey:@"ConfigPORT"] cStringUsingEncoding:NSUTF8StringEncoding];
//    char *ConfigPort = malloc(strlen(exIp) + 1);
//    strcpy(ConfigPort, exIp);
    if (_state == EASY_PUSH_STATE_CONNECTING)               {
        if (selfClass.delegate) {
            [selfClass.delegate getConnectStatus:@"连接中" isFist:0];
        }
    }
    else if (_state == EASY_PUSH_STATE_CONNECTED)           {
        if (selfClass.delegate) {
            [selfClass.delegate getConnectStatus:@"连接成功" isFist:0];
        }
    }

    else if (_state == EASY_PUSH_STATE_CONNECT_FAILED)       {
        if (selfClass.delegate) {
            [selfClass.delegate getConnectStatus:@"连接失败" isFist:0];
        }
    }

    else if (_state == EASY_PUSH_STATE_CONNECT_ABORT)        {
        if (selfClass.delegate) {
            [selfClass.delegate getConnectStatus:@"连接异常中断" isFist:0];
        }
    }

    else if (_state == EASY_PUSH_STATE_PUSHING)              {
        if (selfClass.delegate) {
            [selfClass.delegate getConnectStatus:@"推流中" isFist:0];
        }
    }
    else if (_state == EASY_PUSH_STATE_DISCONNECTED)         {
        if (selfClass.delegate) {
            [selfClass.delegate getConnectStatus:@"断开连接" isFist:0];
        }
    }
    
    return 0;
}

- (void) stopCamera
{
    running = NO;
    [h264Encoder invalidate];
    EasyPusher_StopStream(handle);
}

-(void) captureOutput:(AVCaptureOutput*)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection*)connection
{
    CFRetain(sampleBuffer);
    if(connection == self.videoConnection)
    {
//        static int frame1 = 0;
//        CMTime lastSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
//        
//        if( frame1 == 0 && _videoWriter.status != AVAssetWriterStatusWriting &&  _videoWriter.status != AVAssetWriterStatusFailed)
//            
//        {
//            BOOL success = [_videoWriter startWriting];
//            
//            //            [_videoWriter startSessionAtSourceTime:CMTimeMake(1, 25)];
//            [_videoWriter startSessionAtSourceTime:lastSampleTime];
//            
//        } if( _videoWriter.status > AVAssetWriterStatusWriting )
//            
//        {
//            
//            NSLog(@"Warning: writer status is %zd", _videoWriter.status);
//            if( _videoWriter.status == AVAssetWriterStatusFailed )
//                
//                NSLog(@"Error: %@",_videoWriter.error);
//            
//            return;
//            
//        }
//        if (_videoWriter.status == AVAssetWriterStatusWriting) {
//            if ([_videoWriterInput isReadyForMoreMediaData])
//            {
//               
//                if( ![_videoWriterInput appendSampleBuffer:sampleBuffer])
//                {
//                    NSLog(@"Unable to write to video input");
//                }
//                else
//                {
//                    NSLog(@"already write vidio");
//                }
//            }
//            frame1++;
//            
//        }
//        if (frame1 == 20) {
//            [_videoWriterInput markAsFinished];
//            [_videoWriter finishWritingWithCompletionHandler:^{
//                NSFileManager* manager = [NSFileManager defaultManager];
//                NSString *filePath = [NSHomeDirectory()stringByAppendingPathComponent:@"Documents/Movie.mp4"];
//                if ([manager fileExistsAtPath:filePath]){
//                    NSLog(@"%lld",[[manager attributesOfItemAtPath:filePath error:nil] fileSize]);
//                    
//                }
//            }];
//        }

        if (running)
        {
            dispatch_async(encodeQueue, ^{
                
                [h264Encoder encode:sampleBuffer];
                
                CFRelease(sampleBuffer);
            });
        }
    }
    else if(connection == self.audioConnection)
    {
        if (running)
        {
            dispatch_async(encodeQueue, ^{
                
                [aacEncoder encode:sampleBuffer];
                CFRelease(sampleBuffer);
            });
        }
        
    }
    
    if (!running)
    {
        CFRelease(sampleBuffer);
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    NSLog(@"drop frame");
}

#pragma mark -  H264HWEncoderDelegate declare

- (void)gotH264EncodedData:(NSData *)packet keyFrame:(BOOL)keyFrame timestamp:(CMTime)timestamp error:(NSError*)error
{
//    NSLog(@"gotH264EncodedData %d", (int)[packet length]);
//    
//    [fileH264Handle writeData:packet];
    
//    if(isReadyVideo && isReadyAudio) [rtp_h264 publish:packet timestamp:timestamp payloadType:98];
    
    CGFloat secs = CMTimeGetSeconds(timestamp);
//    UInt32 uSecs = (secs - (int)secs) * 1000 * 1000;

    EASY_AV_Frame frame;
    frame.pBuffer=(void*)packet.bytes;
    frame.u32AVFrameFlag=EASY_SDK_VIDEO_FRAME_FLAG;
    frame.u32AVFrameLen=(Easy_U32)packet.length;
//    frame.u32TimestampSec = secs; //(Easy_U32)timestamp.value/timestamp.timescale;
//    frame.u32TimestampUsec = uSecs;//timestamp.value%timestamp.timescale/1000;å
    frame.u32TimestampSec = 0;
    frame.u32TimestampUsec = 0;
    frame.u32VFrameType= keyFrame ? EASY_SDK_VIDEO_FRAME_I : EASY_SDK_VIDEO_FRAME_P;
    
    if(running)
    {
        EasyPusher_PushFrame(handle, &frame);
    }//[publish:packet timestamp:timestamp payloadType:98];
}

-(void) initVideoAudioWriter

{
    
    CGSize size = CGSizeMake(480, 320);
    
    NSString *betaCompressionDirectory = [NSHomeDirectory()stringByAppendingPathComponent:@"Documents/Movie.mp4"];
    
    
    
    NSError *error = nil;
    
    
    
    unlink([betaCompressionDirectory UTF8String]);
    
    
    
    //----initialize compression engine
    
    self.videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:betaCompressionDirectory]
                        
                                                 fileType:AVFileTypeMPEG4
                        
                                                    error:&error];
    
    NSParameterAssert(self.videoWriter);
    
    if(error)
        
        NSLog(@"error = %@", [error localizedDescription]);
    
    NSDictionary *videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
                                           
                                           [NSNumber numberWithDouble:128.0*1024.0],AVVideoAverageBitRateKey,
                                           
                                           nil ];
    
    
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey,
                                   
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   
                                   [NSNumber numberWithInt:size.height],AVVideoHeightKey,videoCompressionProps, AVVideoCompressionPropertiesKey, nil];
    
    self.videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    
    
    NSParameterAssert(self.videoWriterInput);
    
    
    
    self.videoWriterInput.expectsMediaDataInRealTime = YES;
    
    
    
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                                           
                                                           [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange], kCVPixelBufferPixelFormatTypeKey, nil];
    
    
    
    self.adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoWriterInput
                    
                                                                                    sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
    NSParameterAssert(self.videoWriterInput);
    
    NSParameterAssert([self.videoWriter canAddInput:self.videoWriterInput]);
    
//    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:nil];
    //提前create  CVPixelBufferRef，避免每次create
//    int cvRet = CVPixelBufferCreate(kCFAllocatorDefault,480, 320,kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef)(options),&_pixelBuffer);
    
    if ([self.videoWriter canAddInput:self.videoWriterInput])
    {
        NSLog(@"I can add this input");
    }else{
        NSLog(@"i can't add this input");
    }
    
    
    // Add the audio input
    
    AudioChannelLayout acl;
    
    bzero( &acl, sizeof(acl));
    
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
    
    
    
    NSDictionary* audioOutputSettings = nil;
    
    //    audioOutputSettings = [ NSDictionary dictionaryWithObjectsAndKeys:
    
    //                           [ NSNumber numberWithInt: kAudioFormatAppleLossless ], AVFormatIDKey,
    
    //                           [ NSNumber numberWithInt: 16 ], AVEncoderBitDepthHintKey,
    
    //                           [ NSNumber numberWithFloat: 44100.0 ], AVSampleRateKey,
    
    //                           [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
    
    //                           [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
    
    //                           nil ];
    
    audioOutputSettings = [ NSDictionary dictionaryWithObjectsAndKeys:
                           
                           [ NSNumber numberWithInt: kAudioFormatMPEG4AAC ], AVFormatIDKey,
                           
                           [ NSNumber numberWithInt:64000], AVEncoderBitRateKey,
                           
                           [ NSNumber numberWithFloat: 44100.0 ], AVSampleRateKey,
                           
                           [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
                           
                           [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
                           
                           nil ];
    
    //    _audioWriterInput = [AVAssetWriterInput
    //
    //                         assetWriterInputWithMediaType: AVMediaTypeAudio
    //
    //                         outputSettings: audioOutputSettings ];
    //
    //
    //
    //    _audioWriterInput.expectsMediaDataInRealTime = YES;
    //
    //    // add input
    //
    //    [_videoWriter addInput:_audioWriterInput];
    
    [_videoWriter addInput:_videoWriterInput];
}

#if TARGET_OS_IPHONE
#pragma mark - AACEncoderDelegate declare

- (void)gotAACEncodedData:(NSData *)data timestamp:(CMTime)timestamp error:(NSError*)error {
//    NSLog(@"gotAACEncodedData %d", (int)[data length]);
//
//    if (fileAACHandle != NULL)
//    {
//        [fileAACHandle writeData:data];
//    }

//    if(isReadyVideo && isReadyAudio) [rtp_aac publish:data timestamp:timestamp payloadType:97];
    CGFloat secs = CMTimeGetSeconds(timestamp);
    UInt32 uSecs = (secs - (int)secs) * 1000 * 1000;
    
    EASY_AV_Frame frame;
    frame.pBuffer=(void*)[data bytes];
    frame.u32AVFrameLen = (Easy_U32)[data length];
    frame.u32VFrameType = EASY_SDK_AUDIO_CODEC_AAC;
    frame.u32AVFrameFlag=EASY_SDK_AUDIO_FRAME_FLAG;
   
    frame.u32TimestampSec= secs;//(Easy_U32)timestamp.value/timestamp.timescale;
    frame.u32TimestampUsec = uSecs;//timestamp.value%timestamp.timescale;
    if(running)
    {
        EasyPusher_PushFrame(handle,&frame);
    }//[rtp_aac publish:data timestamp:timestamp payloadType:97];

}

#endif

@end
