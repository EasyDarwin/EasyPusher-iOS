//
//  EasyResolutionViewController.m
//  EasyPusher
//
//  Created by yingengyue on 2017/3/3.
//  Copyright © 2017年 phylony. All rights reserved.
//

#import "ResolutionViewController.h"
#import "URLTool.h"
#import "Masonry.h"

@interface ResolutionViewController ()

@property (nonatomic, strong) NSArray *resolutionArray;

@end

@implementation ResolutionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, HRGScreenWidth, HRGScreenHeight)];
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeView)];
    [view addGestureRecognizer:gesture];
    [self.view addSubview:view];
    
    self.tableView = [[UITableView alloc] init];
    self.tableView.frame = CGRectMake(70, HRGBarHeight + 16, 110, 44*4);
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 44.0;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = UIColorFromRGB(0xffffff);
    self.tableView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.tableView];
    
    HRGViewBorderRadius(self.tableView, 5.0, 0, [UIColor clearColor]);
}

- (NSArray *)resolutionArray{
    if (!_resolutionArray) {
        _resolutionArray = @[@"288*352",@"480*640",@"720*1280",@"1080*1920"];
    }
    
    return _resolutionArray;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.resolutionArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIden = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIden];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIden];
    }
    
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.font = [UIFont systemFontOfSize:15];
    cell.textLabel.text = self.resolutionArray[indexPath.row];
    
    if ([[URLTool gainResolition] isEqualToString:cell.textLabel.text]) {
        cell.textLabel.textColor = UIColorFromRGB(ThemeColor);
    } else {
        cell.textLabel.textColor = UIColorFromRGB(0x4c4c4c);
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    // 保存分辨率
    [URLTool saveResolition:self.resolutionArray[indexPath.row]];
    
    // 通知推流页修改显示的值
    if (_delegate) {
        [_delegate onSelecedesolution:indexPath.row];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) closeView {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
