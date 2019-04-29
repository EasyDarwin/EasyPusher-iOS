//
//  HRGBaseViewController.h
//  SHAREMEDICINE_SHOP_iOS
//
//  Created by mac on 2018/5/10.
//  Copyright © 2018年 liyy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RTRootNavigationController/RTRootNavigationController.h>

@interface BaseViewController : UIViewController

@property (nonatomic, assign) BOOL isCanPushViewController;// 保证push ViewController只会被调用一次

// 统一的push处理
- (void) basePushViewController:(UIViewController *)controller;
- (void) basePushViewController:(UIViewController *)controller removeSelf:(BOOL)remove;

@end
