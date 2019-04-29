//
//  EasyDarwinInfoViewController.m
//  EasyPusher
//
//  Created by yingengyue on 2017/3/4.
//  Copyright © 2017年 phylony. All rights reserved.
//

#import "InfoViewController.h"
#import "WebViewController.h"
#import "URLTool.h"

@interface InfoViewController ()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@end

@implementation InfoViewController

- (instancetype) initWithStoryboard {
    return [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"InfoViewController"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"关于";
    
    NSString *name = @"EasyRTSP iOS 推流器";
    NSString *content;
    UIColor *color;
    
    int activeDays = [URLTool activeDay];
    if (activeDays >= 9999) {
        content = @"激活码永久有效";
        color = UIColorFromRGB(0x2cff1c);
    } else if (activeDays > 0) {
        content = [NSString stringWithFormat:@"激活码还剩%ld天可用", (long)activeDays];
        color = UIColorFromRGB(0xeee604);
    } else {
        content = [NSString stringWithFormat:@"激活码已过期%ld天", (long)activeDays];
        color = UIColorFromRGB(0xf64a4a);
    }
    
    NSString *str = [NSString stringWithFormat:@"%@(%@)", name, content];
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:str];
    
    NSRange range = [str rangeOfString:content];
    NSDictionary *dict = @{ NSForegroundColorAttributeName:color };
    
    [attr setAttributes:dict range:range];
    
    self.nameLabel.attributedText = attr;
    self.nameLabel.numberOfLines = 0;
}

- (IBAction)easyDSS:(id)sender {
    UIButton *btn = (UIButton *)sender;
    
    WebViewController *controller = [[WebViewController alloc] init];
    controller.title = @"EasyDSS";
    controller.url = btn.titleLabel.text;
    [self basePushViewController:controller];
}

- (IBAction)github:(id)sender {
    UIButton *btn = (UIButton *)sender;
    
    WebViewController *controller = [[WebViewController alloc] init];
    controller.title = @"EasyPlayPro";
    controller.url = btn.titleLabel.text;
    [self basePushViewController:controller];
}


@end
