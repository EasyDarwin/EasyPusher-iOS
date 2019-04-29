//
//  URLTool.h
//  EasyRTMP
//
//  Created by mac on 2018/7/9.
//  Copyright © 2018年 phylony. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface URLTool : NSObject

// 推流地址
+ (void) saveURL:(NSString *)url;
+ (NSString *) gainURL;

// 分辨率
+ (void) saveResolition:(NSString *)resolition;
+ (NSString *)gainResolition;

// 是否只推送音频
+ (void) saveOnlyAudio:(BOOL) isAudio;
+ (BOOL) gainOnlyAudio;

// 编码方式：是否是X264软编码
+ (void) saveX264Enxoder:(BOOL) value;
+ (BOOL) gainX264Enxoder;

#pragma mark - key有效期

+ (void) setActiveDay:(int)value;

+ (int) activeDay;


@end
