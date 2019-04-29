//
//  AVAssetWriteManager.h
//  EasyRTMP
//
//  Created by mac on 2018/7/24.
//  Copyright © 2018年 phylony. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

// 录制状态，（这里把视频录制与写入合并成一个状态）
typedef NS_ENUM(NSInteger, FMRecordState) {
    FMRecordStateInit = 0,
    FMRecordStatePrepareRecording,
    FMRecordStateRecording,
    FMRecordStateFinish,
    FMRecordStateFail,
};

// 录制视频的长宽比
typedef NS_ENUM(NSInteger, FMVideoViewType) {
    Type1X1 = 0,
    Type4X3,
    TypeFullScreen
};

// 录制协议
@protocol AVAssetWriteManagerDelegate <NSObject>

- (void)finishWriting;
- (void)updateWritingProgress:(CGFloat)progress;

@end

@interface AVAssetWriteManager : NSObject

@property (nonatomic, retain) __attribute__((NSObject)) CMFormatDescriptionRef outputVideoFormatDescription;
@property (nonatomic, retain) __attribute__((NSObject)) CMFormatDescriptionRef outputAudioFormatDescription;

@property (nonatomic, assign) FMRecordState writeState;
@property (nonatomic, weak) id <AVAssetWriteManagerDelegate> delegate;

- (instancetype)initWithURL:(NSURL *)URL viewType:(FMVideoViewType )type;

- (void)startWrite;
- (void)stopWrite;
- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer ofMediaType:(NSString *)mediaType;
- (void)destroyWrite;

@end
