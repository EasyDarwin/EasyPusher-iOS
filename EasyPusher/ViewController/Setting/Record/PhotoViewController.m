//
//  PhotoViewController.m
//  EasyRTMP
//
//  Created by mac on 2018/7/10.
//  Copyright © 2018年 phylony. All rights reserved.
//

#import "PhotoViewController.h"
#import "PromptView.h"

@interface PhotoViewController () {
    PromptView *promptView;
}

@end

@implementation PhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    promptView = [[PromptView alloc] initWithFrame:self.view.bounds];
    [promptView setNilDataWithImagePath:@"" tint:@"没有抓拍" btnTitle:@""];
    [self.view addSubview:promptView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
