//
//  CameraEncoder.h
//  EasyCapture
//
//  Created by lyy on 9/7/18.
//  Copyright © 2018 lyy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

#import "H264HWEncoder.h"

#import <UIKit/UIKit.h>
#import "AACEncoder.h"
#import "EasyPusherAPI.h"

@protocol ConnectDelegate<NSObject>

- (void)getConnectStatus:(NSString *)status isFist:(int)tag;

- (void)sendPacketFrameLength:(unsigned int)length;

@end

/**
 采集、编码、推流
 */
@interface CameraEncoder : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, weak) id<ConnectDelegate> delegate;

@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, assign) AVCaptureVideoOrientation orientation;
@property (nonatomic, assign) CGSize outputSize;

@property (nonatomic, assign) BOOL running;
@property (nonatomic, assign) BOOL onlyAudio;

// 初始化
- (int) initCameraWithOutputSize:(CGSize)size resolution:(AVCaptureSessionPreset)resolution;
- (void) startCapture;

// 开始推流/结束推流
- (void) startCamera:(NSString *)hostUrl;
- (void) stopCamera;

// 切换属性
- (void) changeCameraStatus:(BOOL) onlyAudio;
- (void) swapResolution:(AVCaptureSessionPreset)resolution;
- (void) swapFrontAndBackCameras;

- (void)startRecord;
- (void)stopRecord;

@end
