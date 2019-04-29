//
//  FolderUtil.h
//  EasyRTMP
//
//  Created by mac on 2018/7/24.
//  Copyright © 2018年 phylony. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FolderUtil : NSObject

// 写入的视频路径
+ (NSString *)createVideoFilePath;

// 存放视频的文件夹
+ (NSString *)videoFolder;

// 删除文件
+ (void) deleteFilePath:(NSString *)path;

+ (NSArray *)listFilesInDirectoryAtPath:(NSString *)path;

@end
