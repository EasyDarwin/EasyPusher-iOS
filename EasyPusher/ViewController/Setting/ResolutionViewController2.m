//
//  EasyResolutionViewController.m
//  EasyPusher
//
//  Created by yingengyue on 2017/3/3.
//  Copyright © 2017年 phylony. All rights reserved.
//

#import "ResolutionViewController2.h"
#import "URLTool.h"
#import "Masonry.h"

@interface ResolutionViewController2 ()

@property (nonatomic, strong) NSArray *resolutionArray;

@end

@implementation ResolutionViewController2

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor =UIColorFromRGBA(0x000000, 0.3);
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, HRGScreenWidth, HRGScreenHeight)];
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeView)];
    [view addGestureRecognizer:gesture];
    [self.view addSubview:view];
    
    self.tableView = [[UITableView alloc] init];
    CGFloat w = 200, h = 54 * 4 + 70 + 10;
    self.tableView.frame = CGRectMake((HRGScreenWidth - w) / 2, (HRGScreenHeight - h) / 2, w, h);
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 54.0;
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
    
    cell.textLabel.font = [UIFont systemFontOfSize:15];
    cell.textLabel.text = self.resolutionArray[indexPath.row];
    
    if ([[URLTool gainResolition] isEqualToString:cell.textLabel.text]) {
        cell.textLabel.textColor = UIColorFromRGB(ThemeColor);
        cell.imageView.image = [UIImage imageNamed:@"selected"];
    } else {
        cell.textLabel.textColor = UIColorFromRGB(0x4c4c4c);
        cell.imageView.image = [UIImage imageNamed:@"select"];
    }
    
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 70;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UILabel *label = [[UILabel alloc] init];
    label.backgroundColor = [UIColor whiteColor];
    label.text = @"推送屏幕分辨率";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColorFromRGB(0x4c4c4c);
    label.font = [UIFont systemFontOfSize:18.0];
    
    return label;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    // 保存分辨率
    [URLTool saveResolition:self.resolutionArray[indexPath.row]];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) closeView {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
