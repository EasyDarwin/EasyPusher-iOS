//
//  EasySetingViewController.h
//  EasyPusher
//
//  Created by yingengyue on 2017/1/10.
//  Copyright © 2017年 phylony. All rights reserved.
//

#import "BaseViewController.h"

@protocol SetDelegate<NSObject>

- (void)setFinish;

@end

@interface SettingViewController : BaseViewController

@property (nonatomic, assign) id<SetDelegate> delegate;

- (instancetype) initWithStoryboard;

@end
