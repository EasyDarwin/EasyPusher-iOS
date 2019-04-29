//
//  VideoViewController.m
//  EasyRTMP
//
//  Created by mac on 2018/7/10.
//  Copyright © 2018年 phylony. All rights reserved.
//

#import "VideoViewController.h"
#import "PlayRecordViewController.h"
#import "PromptView.h"
#import "VideoCell.h"
#import "FolderUtil.h"

@interface VideoViewController ()<UICollectionViewDelegate, UICollectionViewDataSource> {
    PromptView *promptView;
    int countPerPage;// 每页的个数
}

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *records;

@end

@implementation VideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"文件夹";
    self.view.backgroundColor = [UIColor whiteColor];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = 0;
    layout.minimumLineSpacing = 0;
    [layout setScrollDirection:UICollectionViewScrollDirectionVertical];// 设置collectionView的滚动方向
    
    CGRect frame = CGRectMake(2, 0, HRGScreenWidth - 4, HRGScreenHeight - HRGBarHeight - HRGNavHeight - 47);
    self.collectionView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:layout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.showsVerticalScrollIndicator = NO;
    
    // 注册collectionViewcell:WWCollectionViewCell是我自定义的cell的类型
    [self.collectionView registerClass:[VideoCell class] forCellWithReuseIdentifier:@"VideoCell"];
    // 注册collectionView头部的view，需要注意的是这里的view需要继承自UICollectionReusableView
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header"];
    // // 注册collectionView尾部的view
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"footer"];
    [self.view addSubview:self.collectionView];
    
    [self gainVideoData];
}

#pragma mark - UICollectionViewDataSource

// 每组cell的个数
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.records.count;
}

// cell的内容
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    VideoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"VideoCell" forIndexPath:indexPath];
    
    NSString *name = self.records[indexPath.row];
    cell.label.text = [name stringByReplacingOccurrencesOfString:@".mp4" withString:@""];
    
    // 长按删除
    UILongPressGestureRecognizer* longgs = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpress:)];
    [cell addGestureRecognizer:longgs];//为cell添加手势
    longgs.minimumPressDuration = 0.6;//定义长按识别时长
    longgs.view.tag = indexPath.row;//将手势和cell的序号绑定
    
    return cell;
}

- (void)longpress:(UILongPressGestureRecognizer *) ges {
    if (ges.state == UIGestureRecognizerStateBegan) {
        
        UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"确认删除这个录像吗？"
                                                                            message:@""
                                                                     preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            // 获取目标cell
            NSInteger row = ges.view.tag;
            
            NSString *name = self.records[row];
            NSString *file = [NSString stringWithFormat:@"%@/%@", [FolderUtil videoFolder], name];
            [FolderUtil deleteFilePath:file];
            
            [self gainVideoData];
        }];
        [controller addAction:cancelAction];
        [controller addAction:okAction];
        
        [self presentViewController:controller animated:YES completion:nil];
    }
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *name = self.records[indexPath.row];
    NSString *file = [NSString stringWithFormat:@"%@/%@", [FolderUtil videoFolder], name];
    
    PlayRecordViewController *controller = [[PlayRecordViewController alloc] init];
    controller.path = file;
    controller.title = name;
    [self basePushViewController:controller];
}

#pragma mark - UICollectionViewDelegateFlowLayout

// 每个cell的尺寸
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat w = self.collectionView.bounds.size.width / 3;
    return CGSizeMake(w, w);
}

// 头部的尺寸
-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(HRGScreenWidth, 0);
}

// 尾部的尺寸
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeMake(HRGScreenWidth, 0);
}

// section的margin
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark - setter

// 读取本地录像
- (void) gainVideoData {
    self.records = [FolderUtil listFilesInDirectoryAtPath:[FolderUtil videoFolder]];
    
    if (self.records.count == 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self addNilDataView];
        });
    } else {
        [self.collectionView reloadData];
    }
}

- (void) addNilDataView {
    if (!promptView) {
        promptView = [[PromptView alloc] initWithFrame:self.view.bounds];
        [promptView setNilDataWithImagePath:@"" tint:@"没有录像" btnTitle:@""];
    }
    
    [self.view addSubview:promptView];
}

@end
