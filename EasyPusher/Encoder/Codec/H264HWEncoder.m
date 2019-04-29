//
//  H264HWEncoder.m
//  EasyCapture
//
//  Created by phylony on 9/11/16.
//  Copyright © 2016 phylony. All rights reserved.
//

#import "H264HWEncoder.h"

@import VideoToolbox;
@import AVFoundation;

@implementation H264HWEncoder {
    VTCompressionSessionRef session;
}

- (void) dealloc {
    [self invalidate];
}

- (id) init {
    if (self = [super init]) {
        session = NULL;
    }
    
    return self;
}

void didCompressH264(void *outputCallbackRefCon, void *sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sampleBuffer) {
    H264HWEncoder* encoder = (__bridge H264HWEncoder*)outputCallbackRefCon;
    
    if (status == noErr) {
        return [encoder didReceiveSampleBuffer:sampleBuffer];
    }
    
    NSLog(@"Error %d : %@", (unsigned int)infoFlags, [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil]);
}

- (void)didReceiveSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (!sampleBuffer) {
        return;
    }
    
    CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    H264Packet *packet = [[H264Packet alloc] initWithCMSampleBuffer:sampleBuffer];
    
    if (self.delegate != nil) {
        [self.delegate gotH264EncodedData:packet.packet keyFrame:packet.keyFrame timestamp:timestamp error:nil];
    }
}

- (void) initSessionWithSize:(CGSize)size {
    OSStatus status = VTCompressionSessionCreate(kCFAllocatorDefault,
                                                 size.width,
                                                 size.height,
                                                 kCMVideoCodecType_H264,
                                                 NULL,
                                                 NULL,
                                                 NULL,
                                                 didCompressH264,
                                                 (__bridge void *)(self),
                                                 &session);
    if (status == noErr) {
        int fps = 20;
        
        // 设置码率
        int bt = (int)(size.width * size.height * 20 * 2 * 0.04f);
        if (size.width >= 1920 || size.height >= 1920) {
            bt *= 0.3;
        } else if (size.width >= 1280 || size.height >= 1280) {
            bt *= 0.4;
        } else if (size.width >= 720 || size.height >= 720) {
            bt *= 0.6;
        }
        
        // 设置编码码率(比特率)，如果不设置，默认将会以很低的码率编码，导致编码出来的视频很模糊
        status  = VTSessionSetProperty(session,
                                       kVTCompressionPropertyKey_AverageBitRate,
                                       (__bridge CFTypeRef)@(bt)); // bps
        status += VTSessionSetProperty(session,
                                       kVTCompressionPropertyKey_DataRateLimits,
                                       (__bridge CFArrayRef)@[@(bt * 2 / 8), @1]); // Bps
        NSLog(@"set bitrate return: %d", (int)status);
        
        const int32_t v = fps * 2; // 2-second kfi
        CFNumberRef ref = CFNumberCreate(NULL, kCFNumberSInt32Type, &v);
        VTSessionSetProperty(session,
                             kVTCompressionPropertyKey_MaxKeyFrameInterval,
                             ref);
        CFRelease(ref);
        
        ref = CFNumberCreate(NULL, kCFNumberSInt32Type, &fps);
        VTSessionSetProperty(session,
                             kVTCompressionPropertyKey_ExpectedFrameRate,
                             ref);
        CFRelease(ref);
        
        VTSessionSetProperty(session,
                             kVTCompressionPropertyKey_RealTime,
                             kCFBooleanTrue);
        VTSessionSetProperty(session,
                             kVTCompressionPropertyKey_ProfileLevel,
                             kVTProfileLevel_H264_Baseline_AutoLevel);
        
        // 开始编码
        status = VTCompressionSessionPrepareToEncodeFrames(session);
        NSLog(@"start encode  return: %d", (int)status);
    }
}

- (void) invalidate {
    if(session) {
        VTCompressionSessionCompleteFrames(session, kCMTimeInvalid);
        VTCompressionSessionInvalidate(session);
        CFRelease(session);
        session = NULL;
    }
}

- (void) encode:(CMSampleBufferRef)sampleBuffer size:(CGSize)size {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    if(session == NULL || size.width > 0) {
        [self initSessionWithSize:size];
    }
    
    if( session != NULL && sampleBuffer != NULL) {
        // Create properties
        CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
//        CMTime pts = CMTimeMake(CMTimeGetSeconds(timestamp), 1000.0);
//        NSLog(@"%f", CMTimeGetSeconds(pts));
       
        VTEncodeInfoFlags flags;
        
        VTCompressionSessionEncodeFrame(session, imageBuffer, timestamp, kCMTimeInvalid, NULL, NULL, &flags);
    }
}

@end
