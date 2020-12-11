//
//  XHBaseVideoPlayer.h
//  XHKitDemo
//
//  Created by 向洪 on 2019/10/28.
//  Copyright © 2019 向洪. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

/// 播放状态
typedef NS_ENUM(NSInteger, XHVideoPlayStatus) {
    XHVideoPlayStatusInit = 0,
    XHVideoPlayStatusWaitingBuff,
    XHVideoPlayStatusPlayIng,
    XHVideoPlayStatusPase,
    XHVideoPlayStatusEnd,
    XHVideoPlayStatusFailed,
};

///// 缓冲播放状态
//typedef NS_ENUM(NSInteger, XHPlayerTimeControlStatus) {
//    XHPlayerTimeControlStatusPaused = 0,
//    XHPlayerTimeControlStatusWaitingToPlayAtSpecifiedRate = 1,
//    XHPlayerTimeControlStatusPlaying = 2,
//};

NS_ASSUME_NONNULL_BEGIN

@interface XHBaseVideoPlayer : NSObject

// 地址
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong, readonly) AVURLAsset *asset;
- (instancetype)initWithURL:(NSURL *)url;

/// 播放视图
@property (nonatomic, strong, readonly) UIView *playView;

/// 播放状态
@property (nonatomic, assign, readonly) XHVideoPlayStatus playStatus;

@property (nonatomic, assign, readonly) NSTimeInterval duration; ///< 总时间
@property (nonatomic, assign, readonly) NSTimeInterval loadedTime;   ///< 加载了多少时间
@property (nonatomic, assign, readonly) NSTimeInterval currentTime;  ///< 当前播放的时间

@property (nonatomic, assign, readonly) CGSize presentationSize;  ///< 视频size


/// 占位图
@property (nonatomic, strong) UIImage *placeholderImage;
@property (nonatomic, strong, readonly) UIImageView *placeholderImageView;

/// 是否正在播放
@property (nonatomic, assign, readonly, getter=isPlaying) BOOL playing;

- (void)play;
- (void)playWithSeekTime:(NSTimeInterval)seekTime;

- (void)pause;
- (void)stop;

/// 准备好播放回调
@property (nonatomic, copy, nullable) void(^didReadyToPlayHandler) (XHBaseVideoPlayer *player);
/// 播放状态发生改变回调
@property (nonatomic, copy, nullable) void(^playStatusObserverHandler) (XHBaseVideoPlayer *player, XHVideoPlayStatus playStatus);
/// 播放时间周期回调
@property (nonatomic, copy, nullable) void(^periodicTimeObserverForIntervalHandler) (XHBaseVideoPlayer *player, NSTimeInterval currentTime, NSTimeInterval duration);
/// 缓存变动回调
@property (nonatomic, copy, nullable) void(^loadedTimeRangesObserverHandler) (XHBaseVideoPlayer *player, NSTimeInterval loadedTime, NSTimeInterval duration);

@end

/// 如果要控制播放视图在滑出视图的视图的时候暂停播放，那么设置scollView
@interface XHBaseVideoPlayer (ScrollView)

@property (nonatomic, weak, nullable) UIScrollView *scollView;
/// 滑出视图的时候是否停止播放，default value is YES.
@property (nonatomic) BOOL pauseWhenScrollDisappeared;
/// 滑出视图的时调用
@property (nonatomic, copy, nullable) void(^playerViewWillDisappearHandler)(XHBaseVideoPlayer *videoPlayer);
- (void)scollViewObserver:(UIScrollView *)scrollView contentOffsex:(CGPoint)contentOffset;

@end

NS_ASSUME_NONNULL_END
