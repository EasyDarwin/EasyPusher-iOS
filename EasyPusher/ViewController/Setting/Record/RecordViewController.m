//
//  RecordViewController.m
//  EasyRTMP
//
//  Created by mac on 2018/7/9.
//  Copyright © 2018年 phylony. All rights reserved.
//

#import "RecordViewController.h"
#import "VideoViewController.h"
#import "PhotoViewController.h"

@interface RecordViewController ()<UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *transactionBtn;
@property (strong, nonatomic) IBOutlet UIButton *transferBtn;

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrolllLineWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrolllLineLeft;

@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (strong, nonatomic) NSMutableArray *pages;

@property (strong, nonatomic) UIScrollView *scrollView;

@property (nonatomic, assign) int lastPosX;

@end

@implementation RecordViewController

- (instancetype) initWithStoryborad {
    return [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"RecordViewController"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"文件夹";
    
    // 添加子ViewController
    VideoViewController *controller1 = [[VideoViewController alloc] init];
    PhotoViewController *controller2 = [[PhotoViewController alloc] init];
    
    [self.pages addObject:controller1];
    [self.pages addObject:controller2];
    
    // 添加子View
    [self addChildViewController:self.pageViewController];
    [self.contentView addSubview:self.pageViewController.view];
    
    [self findScrollView];
    
    // 跳转到第一个controller
    if ([self.pages count] > self.currentIndex) {
        [self.pageViewController setViewControllers:@[self.pages[self.currentIndex]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];
        
        self.scrolllLineLeft.constant = EasyScreenWidth / 2 * self.currentIndex;
    }
    
    // 设置UI
    [self.transactionBtn setTitleColor:UIColorFromRGB(EasyTextBlackColor) forState:UIControlStateNormal];
    [self.transactionBtn setTitleColor:UIColorFromRGB(ThemeColor) forState:UIControlStateSelected];
    [self.transferBtn setTitleColor:UIColorFromRGB(EasyTextBlackColor) forState:UIControlStateNormal];
    [self.transferBtn setTitleColor:UIColorFromRGB(ThemeColor) forState:UIControlStateSelected];
    self.transactionBtn.selected = YES;
    self.transferBtn.selected = NO;
    
    self.scrolllLineWidth.constant = EasyScreenWidth / 2.0;
    
    // 按钮事件
    [[self.transactionBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        UIPageViewControllerNavigationDirection direction = UIPageViewControllerNavigationDirectionReverse;
        if (0 >= [self.pages indexOfObject:[self.pageViewController.viewControllers lastObject]]) {
            direction = UIPageViewControllerNavigationDirectionForward;
        }
        
        @weakify(self)
        [self.pageViewController setViewControllers:@[self.pages[0]] direction:direction animated:NO completion:^(BOOL finished) {
            @strongify(self)
            self.scrolllLineLeft.constant = 0;
        }];
    }];
    
    [[self.transferBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        UIPageViewControllerNavigationDirection direction = UIPageViewControllerNavigationDirectionReverse;
        if (1 > [self.pages indexOfObject:[self.pageViewController.viewControllers lastObject]]) {
            direction = UIPageViewControllerNavigationDirectionForward;
        }
        
        @weakify(self)
        [self.pageViewController setViewControllers:@[self.pages[1]] direction:direction animated:NO completion:^(BOOL finished) {
            @strongify(self)
            self.scrolllLineLeft.constant = EasyScreenWidth / 2.0;
        }];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSUInteger index = [self.pages indexOfObject:viewController];
    
    if ((index == NSNotFound) || (index == 0)) {
        return nil;
    }
    
    return self.pages[--index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSUInteger index = [self.pages indexOfObject:viewController];
    
    if ((index == NSNotFound)||(index+1 >= [self.pages count])) {
        return nil;
    }
    
    return self.pages[++index];
}

- (void)pageViewController:(UIPageViewController *)viewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    if (!completed) {
        return;
    }
    
    if ([self.pages indexOfObject:[viewController.viewControllers lastObject]] == 0) {
        self.transactionBtn.selected = YES;
        self.transferBtn.selected = NO;
    } else {
        self.transactionBtn.selected = NO;
        self.transferBtn.selected = YES;
    }
}

#pragma mark - UIScrollViewDelegate

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    UIViewController *vc = self.pages.firstObject;
    CGPoint p = [vc.view convertPoint:CGPointZero toView:self.pageViewController.view];
    if (p.x >= 0 || p.x < -EasyScreenWidth) {
        return;
    }
    
    self.scrolllLineLeft.constant = (-p.x) / 2;
}

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
}

// https://www.jianshu.com/p/4cc4638f44e4
-(void)findScrollView {
    for(id subview in self.pageViewController.view.subviews) {
        if([subview isKindOfClass:UIScrollView.class]) {
            self.scrollView = subview;
            break;
        }
    }
    
    self.scrollView.delegate = self;
}

#pragma mark - getter/setter

- (NSMutableArray *)pages {
    if (!_pages) {
        _pages = [[NSMutableArray alloc] init];
    }
    return _pages;
}

- (UIPageViewController *) pageViewController {
    if (!_pageViewController) {
        _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
        _pageViewController.view.frame = CGRectMake(0, 0, self.contentView.frame.size.width, self.contentView.frame.size.height);
        [_pageViewController setDataSource:self];
        [_pageViewController setDelegate:self];
        [_pageViewController.view setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
    }
    
    return _pageViewController;
}

@end
