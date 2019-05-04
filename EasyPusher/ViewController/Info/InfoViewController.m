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
@property (weak, nonatomic) IBOutlet UILabel *descLabel;

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
    
    NSString *html = @"EasyPusher是EasyDarwin流媒体团队开发的一个RTSP/RTP流媒体音/视频直播推送产品组件，全平台支持(包括Windows/Linux(32 & 64)，ARM各平台，Android、iOS)，通过EasyPusher我们就可以避免接触到稍显复杂的RTSP/RTP/RTCP推送流程，只需要调用EasyPusher的几个API接口，就能轻松、稳定地把流媒体音视频数据推送给RTSP流媒体服务器进行转发和分发，尤其是与EasyDarwin开源RTSP流媒体服务器、EasyPlayer-RTSP播放器可以无缝衔接，EasyPusher经过长时间的企业用户和项目检验，稳定性非常高。";
    NSData *data = [html dataUsingEncoding:NSUnicodeStringEncoding];
    
    NSDictionary *options = @{ NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType,
                               NSCharacterEncodingDocumentAttribute : @(NSUTF8StringEncoding) };
    
    // 设置富文本
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithData:data options:options documentAttributes:nil error:nil];
    
    // 设置段落格式
    NSMutableParagraphStyle *para = [[NSMutableParagraphStyle alloc] init];
    para.lineSpacing = 7;
    para.paragraphSpacing = 10;
    [attrStr addAttribute:NSParagraphStyleAttributeName value:para range:NSMakeRange(0, attrStr.length)];
    
    [attrStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:16] range:NSMakeRange(0, attrStr.length)];
    [attrStr addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(0x4c4c4c) range:NSMakeRange(0, attrStr.length)];
    
    self.descLabel.attributedText = attrStr;
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
