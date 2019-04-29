//
//  PlayRecordViewController.m
//  EasyPlayerRTMP
//
//  Created by liyy on 2018/3/14.
//  Copyright © 2018年 cs. All rights reserved.
//

#import "PlayRecordViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

@interface PlayRecordViewController ()

@property (nonatomic, retain) AVPlayerViewController *playerViewController;

@end

@implementation PlayRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = self.title;
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSURL *url = [NSURL fileURLWithPath:self.path];
    AVPlayer *avPlayer = [AVPlayer playerWithURL:url];
    // player的控制器对象
    _playerViewController = [[AVPlayerViewController alloc] init];
    // 控制器的player播放器
    _playerViewController.player = avPlayer;
    // 试图的填充模式
    _playerViewController.videoGravity = AVLayerVideoGravityResizeAspect;
    // 是否显示播放控制条
    _playerViewController.showsPlaybackControls = YES;
    // 设置显示的Frame
    _playerViewController.view.frame = CGRectMake(0, 64, self.view.bounds.size.width, self.view.bounds.size.height - 64);
    // 将播放器控制器添加到当前页面控制器中
    [self addChildViewController:_playerViewController];
    // view一定要添加，否则将不显示
    [self.view addSubview:_playerViewController.view];
    // 播放
    [_playerViewController.player play];
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if (_playerViewController) {
        [_playerViewController.player pause];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
