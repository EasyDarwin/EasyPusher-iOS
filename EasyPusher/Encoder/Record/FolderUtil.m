//
//  FolderUtil.m
//  EasyRTMP
//
//  Created by mac on 2018/7/24.
//  Copyright © 2018年 phylony. All rights reserved.
//

#import "FolderUtil.h"
#import "XCFileManager.h"

#define VIDEO_FOLDER @"videoFolder" //视频录制存放文件夹

@implementation FolderUtil

// 写入的视频路径
+ (NSString *)createVideoFilePath {
    NSDate *currentDate = [NSDate date];//获取当前时间，日期
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];// 创建一个时间格式化对象
    [dateFormatter setDateFormat:@"YYYYMMdd_hhmmss"];//设定时间格式,这里可以设置成自己需要的格式
    NSString *dateString = [dateFormatter stringFromDate:currentDate];//将时间转化成字符串
    
//    NSString *videoName = [NSString stringWithFormat:@"%@.mp4", [NSUUID UUID].UUIDString];
    NSString *videoName = [NSString stringWithFormat:@"%@.mp4", dateString];
    NSString *path = [[self videoFolder] stringByAppendingPathComponent:videoName];
    return path;
}

// 存放视频的文件夹
+ (NSString *)videoFolder {
    NSString *cacheDir = [XCFileManager cachesDir];
    NSString *direc = [cacheDir stringByAppendingPathComponent:VIDEO_FOLDER];
    if (![XCFileManager isExistsAtPath:direc]) {
        [XCFileManager createDirectoryAtPath:direc];
    }
    
    return direc;
}

// 删除文件
+ (void) deleteFilePath:(NSString *)path {
    if ([XCFileManager isExistsAtPath:path]) {
        [XCFileManager removeItemAtPath:path];
    }
}

+ (NSArray *)listFilesInDirectoryAtPath:(NSString *)path {
    return [XCFileManager listFilesInDirectoryAtPath:path deep:YES];
}

@end
