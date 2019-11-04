//
//  XHVideoPlayToolView.h
//  XHKitDemo
//
//  Created by 向洪 on 2019/10/29.
//  Copyright © 2019 向洪. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XHVideoPlayToolView;

NS_ASSUME_NONNULL_BEGIN

@protocol XHVideoPlayToolViewDelegate <NSObject>

@optional
/// 点击事件
- (void)videoPlayToolViewDidTapGestureRecognizer:(XHVideoPlayToolView *)toolView;
/// 全屏事件
- (void)videoPlayToolViewDidFullScreen:(XHVideoPlayToolView *)toolView isFullScreen:(BOOL)isFullScreen;

@end

@interface XHVideoPlayToolView : UIView

/// 进度条颜色
@property (nonatomic, strong) UIColor *progressColor UI_APPEARANCE_SELECTOR;

/// 播放进度
@property (nonatomic, assign) CGFloat playProgress;

/// 加载进度
@property (nonatomic, assign) CGFloat loadedProgress;

/// 时间
@property (nonatomic, strong, readonly) UILabel *timeLabel;

/// 全屏按钮
@property (nonatomic, strong, readonly) UIButton *fullScreenButton;

@property (nonatomic, weak) id<XHVideoPlayToolViewDelegate> delegate;


@end

NS_ASSUME_NONNULL_END
