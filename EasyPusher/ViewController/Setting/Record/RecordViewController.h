//
//  RecordViewController.h
//  EasyRTMP
//
//  Created by leo on 2018/7/9.
//  Copyright © 2018年 leo. All rights reserved.
//

#import "BaseViewController.h"

/**
 录像文件夹
 */
@interface RecordViewController : BaseViewController<UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (nonatomic, assign) int currentIndex;

- (instancetype) initWithStoryborad;

@end
