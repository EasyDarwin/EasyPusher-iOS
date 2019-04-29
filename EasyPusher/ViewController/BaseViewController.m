//
//  HRGBaseViewController.m
//  SHAREMEDICINE_SHOP_iOS
//
//  Created by mac on 2018/5/10.
//  Copyright © 2018年 liyy. All rights reserved.
//

#import "BaseViewController.h"

@interface BaseViewController ()

@end

@implementation BaseViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.barTintColor = UIColorFromRGB(ThemeColor);// 导航栏背景颜色
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];// item字体颜色
    
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    // 默认使用的是RTRoot框架内部的导航效果和返回按钮，如果要自定义，必须将此属性设置为NO，然后实现下方方法；
    self.rt_navigationController.useSystemBackBarButtonItem = NO;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.isCanPushViewController = YES;// 每次进入，重新置为YES,表示可以push ViewController
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    NSLog(@"%@ dealloc", NSStringFromClass([self class]));
}

#pragma mark - StatusBar

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - private method

- (UIBarButtonItem *)rt_customBackItemWithTarget:(id)target action:(SEL)action {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    [btn sizeToFit];
    [btn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    
    return [[UIBarButtonItem alloc] initWithCustomView:btn];
}

#pragma mark - public method

- (void) basePushViewController:(UIViewController *)controller {
    [self basePushViewController:controller removeSelf:NO];
}

- (void) basePushViewController:(UIViewController *)controller removeSelf:(BOOL)remove {
    if (self.isCanPushViewController) {
        self.isCanPushViewController = NO;
        
        // 注意这里push的时候需要使用rt_navigation push出去
        [self.navigationController pushViewController:controller animated:YES];
//        [self.rt_navigationController pushViewController:controller animated:YES complete:^(BOOL finished) {
//            if (remove) {
//                [self.rt_navigationController removeViewController:self];
//            }
//        }];
    }
}

@end
