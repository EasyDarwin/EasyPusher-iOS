//
//  PromptView.h
//  AcrossAnHui
//
//  Created by liyy on 2017/5/24.
//  Copyright © 2017年 安徽畅通行. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^PromptRefreshListener)(void);
typedef void (^PromptOperationListener)(void);

/**
 数据为空／网络请求失败之后的提示View
 */
@interface PromptView : UIView {
    void (^refreshListener)(void);
}

@property (nonatomic, strong) PromptRefreshListener promptRefreshListener;
@property (nonatomic, strong) PromptOperationListener promptOperationListener;

/**
 设置 数据为空时的 图标 提示 按钮

 @param path 图标名称
 @param tint 提示内容
 @param title nil则表示不显示按钮；否则则显示按钮
 */
- (void) setNilDataWithImagePath:(NSString *) path tint:(NSString *)tint btnTitle:(NSString *)title;
- (void) setNilDataWithImagePath:(NSString *) path tint:(NSString *)tint btnTitle:(NSString *)title isNeedAddData:(BOOL) isAdd;

// 默认的 网络请求失败的view
- (void) setRequestFailureImageView;
/**
 网络请求失败的图标 提示

 @param path 图标名称
 @param tint 提示内容
 */
- (void) setRequestFailureWithImagePath:(NSString *) path tint:(NSString *)tint;

/**
 获取label的名称

 @return label的名称
 */
- (NSString *) getLabelName;

@end
