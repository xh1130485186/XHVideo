//
//  XHLoadingView.h
//  BSGrowthViewing
//
//  Created by 向洪 on 2018/11/1.
//  Copyright © 2018 向洪. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    XHLoadingTreeDotAnimation,
    XHLoadingRingSpinningAnimation,
} XHLoadingAnimationType;

@interface XHLoadingView : UIView

+ (XHLoadingView *)show;
+ (XHLoadingView *)show:(UIView *)superView;
+ (XHLoadingView *)hide;
+ (XHLoadingView *)dismiss;

/// 初始化
/// @param animationType 动画类型
- (instancetype)initWithAnimationType:(XHLoadingAnimationType)animationType;
- (void)show;
- (void)show:(UIView *)superView;
- (void)hide;
- (void)dismiss;

@property (nonatomic, assign) XHLoadingAnimationType animationType;

@end

NS_ASSUME_NONNULL_END
