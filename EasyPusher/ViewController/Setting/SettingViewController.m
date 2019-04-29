//
//  EasySetingViewController.m
//  EasyPusher
//
//  Created by yingengyue on 2017/1/10.
//  Copyright © 2017年 phylony. All rights reserved.
//

#import "SettingViewController.h"
#import "ScanViewController.h"
//#import "RecordViewController.h"
#import "VideoViewController.h"
#import "URLTool.h"

@interface SettingViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UITextField *textView;
@property (weak, nonatomic) IBOutlet UIButton *scanBtn;
@property (weak, nonatomic) IBOutlet UIButton *codeBtn;
@property (weak, nonatomic) IBOutlet UIButton *markBtn;
@property (weak, nonatomic) IBOutlet UIButton *audioBtn;
@property (weak, nonatomic) IBOutlet UIButton *recordBtn;
@property (weak, nonatomic) IBOutlet UIButton *saveBtn;

@end

@implementation SettingViewController

- (instancetype) initWithStoryboard {
    return [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"SettingViewController"];
}

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"设置";
    
    HRGViewBorderRadius(self.topView, 3.0, 1.5, UIColorFromRGB(ThemeColor));
    HRGViewBorderRadius(self.recordBtn, 3.0, 0, [UIColor clearColor]);
    HRGViewBorderRadius(self.saveBtn, 3.0, 0, [UIColor clearColor]);

    [self.codeBtn setImage:[UIImage imageNamed:@"set_select"] forState:UIControlStateNormal];
    [self.codeBtn setImage:[UIImage imageNamed:@"set_selected"] forState:UIControlStateSelected];
    [self.markBtn setImage:[UIImage imageNamed:@"set_select"] forState:UIControlStateNormal];
    [self.markBtn setImage:[UIImage imageNamed:@"set_selected"] forState:UIControlStateSelected];
    [self.audioBtn setImage:[UIImage imageNamed:@"set_select"] forState:UIControlStateNormal];
    [self.audioBtn setImage:[UIImage imageNamed:@"set_selected"] forState:UIControlStateSelected];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 读取设置的值
    self.textView.text = [URLTool gainURL];
    
    if ([URLTool gainOnlyAudio]) {
        self.audioBtn.selected = YES;
    }
    
    if ([URLTool gainX264Enxoder]) {
        self.codeBtn.selected = YES;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - click

// 扫描二维码
- (IBAction)scan:(id)sender {
    ScanViewController *controller = [[ScanViewController alloc] initWithStoryboard];
    [self presentViewController:controller animated:YES completion:nil];
}

// 软编码
- (IBAction)code:(id)sender {
    self.codeBtn.selected = !self.codeBtn.selected;
    
    [URLTool saveX264Enxoder:self.codeBtn.selected];
}

// 水印
- (IBAction)mark:(id)sender {
    self.markBtn.selected = !self.markBtn.selected;
    
    // TODO
}

// 仅推送音频
- (IBAction)onlyAudio:(id)sender {
    self.audioBtn.selected = !self.audioBtn.selected;
    
    [URLTool saveOnlyAudio:self.audioBtn.selected];
}

// 录像文件
- (IBAction)record:(id)sender {
//    RecordViewController *controllr = [[RecordViewController alloc] initWithStoryborad];
    VideoViewController *controllr = [[VideoViewController alloc] init];
    [self basePushViewController:controllr];
}

// 保存
- (IBAction)save:(id)sender {
    [URLTool saveURL:self.textView.text];
    
    if (self.audioBtn.selected) {
        [URLTool saveOnlyAudio:YES];
    } else {
        [URLTool saveOnlyAudio:NO];
    }
    
    if (self.delegate) {
        [self.delegate setFinish];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
