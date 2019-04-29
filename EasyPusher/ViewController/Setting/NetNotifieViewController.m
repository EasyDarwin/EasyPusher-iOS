//
//  NoNetNotifieViewController.m
//  EasyPusher
//
//  Created by yingengyue on 2017/3/11.
//  Copyright © 2017年 phylony. All rights reserved.
//

#import "NetNotifieViewController.h"

@interface NetNotifieViewController ()

@end

@implementation NetNotifieViewController

- (instancetype) initWithStoryboard {
    return [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"NetNotifieViewController"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"解决方案";
}

@end
