//
//  EasyResolutionViewController.h
//  EasyPusher
//
//  Created by yingengyue on 2017/3/3.
//  Copyright © 2017年 phylony. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EasyResolutionDelegate <NSObject>

-(void)onSelecedesolution:(NSInteger)resolutionNo;

@end

@interface ResolutionViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, weak) id<EasyResolutionDelegate> delegate;

@end
