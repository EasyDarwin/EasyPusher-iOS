//
//  URLTool.m
//  EasyRTMP
//
//  Created by mac on 2018/7/9.
//  Copyright © 2018年 phylony. All rights reserved.
//

#import "URLTool.h"

static NSString *ConfigUrlKey = @"ConfigUrl";
static NSString *ResolitionKey = @"resolition";
static NSString *OnlyAudioKey = @"OnlyAudioKey";
static NSString *X264Encoder = @"X264Encoder";
static NSString *activeDay = @"activeDay";

@implementation URLTool

#pragma mark - url

+ (void) saveURL:(NSString *)url {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:url forKey:ConfigUrlKey];
    [defaults synchronize];
}

+ (NSString *) gainURL {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *url = [defaults objectForKey:ConfigUrlKey];
    
    // 设置默认url
    if (!url || [url isEqualToString:@""] || [url containsString:@"www.easydss"]) {
        // 因为rtsp流服务器没开启，暂时用rtmp测试
//        NSMutableString *address = [[NSMutableString alloc] initWithString:@"rtsp://cloud.easydarwin.org:554/"];
        NSMutableString *address = [[NSMutableString alloc] initWithString:@"rtmp://demo.easydss.com:10085/hls/stream_"];
        for (int i = 0; i < 6; i++) {
            int num = arc4random() % 10;
            [address appendString:[NSString stringWithFormat:@"%d",num]];
        }
        [address appendString:@".sdp"];
        [self saveURL:address];
        
        url = address;
    }
    
    return url;
}

#pragma mark - resolition

+ (void) saveResolition:(NSString *)resolition {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:resolition forKey:ResolitionKey];
    [defaults synchronize];
}

+ (NSString *)gainResolition {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *resolition = [defaults objectForKey:ResolitionKey];
    
    // 设置默认分辨率
    if (!resolition || [resolition isEqualToString:@""]) {
        [self saveResolition:@"480*640"];
    }
    
    return resolition;
}

#pragma mark - only audio

+ (void) saveOnlyAudio:(BOOL) isAudio {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:isAudio forKey:OnlyAudioKey];
    [defaults synchronize];
}

+ (BOOL) gainOnlyAudio {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:OnlyAudioKey];
}

#pragma mark - 编码方式：是否是X264软编码

+ (void) saveX264Enxoder:(BOOL) value {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:value forKey:X264Encoder];
    [defaults synchronize];
}

+ (BOOL) gainX264Enxoder {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:X264Encoder];
}

#pragma mark - key有效期

+ (void) setActiveDay:(int)value {
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:activeDay];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (int) activeDay {
    return (int)[[NSUserDefaults standardUserDefaults] integerForKey:activeDay];
}

@end
