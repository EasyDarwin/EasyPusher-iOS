//
//  VideoCell.m
//  EasyRTMP
//
//  Created by mac on 2018/7/10.
//  Copyright © 2018年 phylony. All rights reserved.
//

#import "VideoCell.h"

@interface VideoCell()

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIImageView *playIV;

@end

@implementation VideoCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor whiteColor];
        
        CGRect f = CGRectMake(3, 3, self.contentView.bounds.size.width-6, self.contentView.bounds.size.height-6);
        _imageView = [[UIImageView alloc] initWithFrame:f];
        _imageView.layer.masksToBounds = YES;
        _imageView.backgroundColor = [UIColor grayColor];
        [self.contentView addSubview:_imageView];
        
        float size = 30;
        CGFloat w = self.contentView.bounds.size.width;
        CGFloat h = self.contentView.bounds.size.height+10;
        _playIV = [[UIImageView alloc] initWithFrame:CGRectMake((w - size) / 2, (h - size) / 2, size, size)];
        _playIV.layer.masksToBounds = YES;
        _playIV.image = [UIImage imageNamed:@"player"];
        [self.contentView addSubview:_playIV];
        
        _label = [[UILabel alloc] init];
        _label.frame = CGRectMake(0, self.contentView.bounds.size.height-18, self.contentView.bounds.size.width, 18);
        _label.textColor = [UIColor whiteColor];
        _label.font = [UIFont systemFontOfSize:13.0];
        _label.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_label];
    }
    
    return self;
}

@end
