//
//  XHBaseVideoPlayer.m
//  XHKitDemo
//
//  Created by 向洪 on 2019/10/28.
//  Copyright © 2019 向洪. All rights reserved.
//

#import "XHBaseVideoPlayer.h"
#import <objc/runtime.h>

#define IOS_VERSION_10_BELOW ([[[UIDevice currentDevice] systemVersion] floatValue])<10.f
#define kContentOffset @"contentOffset"

@interface XHVideoPlayContentView : UIView

@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@end

@implementation XHVideoPlayContentView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor colorWithWhite:0/250.f alpha:1];
        
    
        _playerLayer = [[AVPlayerLayer alloc] init];
        
        UIView *playerLayerContentView = [[UIView alloc] init];
        [playerLayerContentView.layer addSublayer:_playerLayer];
        
        [self addSubview:playerLayerContentView];

        playerLayerContentView.translatesAutoresizingMaskIntoConstraints = NO;
        NSMutableArray *constraints = [NSMutableArray array];
        
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[playerLayerContentView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(playerLayerContentView)]];
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[playerLayerContentView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(playerLayerContentView)]];
        
        [self addConstraints:constraints];

    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _playerLayer.frame = self.bounds;
}

@end

@interface XHBaseVideoPlayer () {
    XHVideoPlayContentView *_playView;
    id _timeObserve;
}

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) XHVideoPlayContentView *playView;;
@property (nonatomic, strong) UIImageView *placeholderImageView;

@property (nonatomic, assign) XHVideoPlayStatus playStatus;

@property (nonatomic, assign) NSTimeInterval duration; ///< 总时间
@property (nonatomic, assign) NSTimeInterval loadedTime;   ///< 加载了多少时间
@property (nonatomic, assign) NSTimeInterval currentTime;  ///< 当前播放的时间

@property (nonatomic, assign) CGSize presentationSize;  ///< 视频size

@end

@implementation XHBaseVideoPlayer

- (instancetype)init {
    self = [super init];
    if (self) {
        self.pauseWhenScrollDisappeared = YES;
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)url {
    self = [self init];
    if (self) {
        self.url = url;
    }
    return self;
}

- (void)setUrl:(NSURL *)url {
    
    _url = url;
    
    _asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    
    AVPlayerItem *item = [[AVPlayerItem alloc] initWithAsset:_asset];
    
    if (!_player) {
        [self createPlayerWithItem:item];
    } else {
        [_player.currentItem removeObserver:self forKeyPath:@"status"];
        [_player.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [_player.currentItem removeObserver:self forKeyPath:@"presentationSize"];
        [_player.currentItem removeObserver:self forKeyPath:@"duration"];
        
        if (@available(iOS 10.0, *)) {
            
        } else {
            [_player.currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        }
        [self stop];
        [_player replaceCurrentItemWithPlayerItem:item];
    }
    
    self.playStatus = XHVideoPlayStatusInit;
    self.presentationSize = CGSizeZero;
    
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:@"presentationSize" options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:@"duration" options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
    if (@available(iOS 10.0, *)) {
//        self.timeControlStatus = (XHPlayerTimeControlStatus)_player.timeControlStatus;
    } else {
//        self.timeControlStatus = XHPlayerTimeControlStatusPaused;
        [item addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    }
}

/// 创建播放器
- (void)createPlayerWithItem:(AVPlayerItem *)item {
    
    __weak __typeof(self)weakSelf = self;
    _player = [[AVPlayer alloc] initWithPlayerItem:item];
    _playView.playerLayer.player = _player;
    
    if (@available(iOS 10, *)) {
        [_player addObserver:self forKeyPath:@"timeControlStatus" options:NSKeyValueObservingOptionNew context:nil];
    } else {
        /// 声音被打断的通知（电话打来）
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionInterruption:) name:AVAudioSessionInterruptionNotification object:nil];
        /// 耳机插入和拔出的通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(routeChange:) name:AVAudioSessionRouteChangeNotification object:nil];
        /// 进入后台
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resignActive:) name:UIApplicationWillResignActiveNotification object:nil];
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playDidEnd:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playDidFailed:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playDidStalled:) name:AVPlayerItemPlaybackStalledNotification object:nil];
    
    _timeObserve = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        CGFloat currentTime = CMTimeGetSeconds(time);
        weakSelf.currentTime = currentTime;
        if (weakSelf.periodicTimeObserverForIntervalHandler) {
            weakSelf.periodicTimeObserverForIntervalHandler(weakSelf, currentTime, weakSelf.duration);
        }
    }];
}

#pragma mark - 公开方法

- (void)play {

    if (IOS_VERSION_10_BELOW) {
        _playStatus = XHVideoPlayStatusPlayIng;
    }
    if (_playStatus == XHVideoPlayStatusEnd) {
        [_player seekToTime:CMTimeMake(0.0, 1.0)];
    }
    [_player play];
}

- (void)playWithSeekTime:(NSTimeInterval)seekTime {
    if (IOS_VERSION_10_BELOW) {
        _playStatus = XHVideoPlayStatusPlayIng;
    }
    [_player seekToTime:CMTimeMake(seekTime, 1.0)];
    [_player play];
}

- (void)pause {
    
    if (IOS_VERSION_10_BELOW) {
        _playStatus = XHVideoPlayStatusPase;
    }
    
    [_player pause];
}

- (void)stop {
    
    _playStatus = XHVideoPlayStatusEnd;
    
    [_player pause];
}

#pragma mark - 时间处理

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {

    // 状态更改
    if ([keyPath isEqualToString:@"status"]) {
        
        AVPlayerItemStatus status = [change[NSKeyValueChangeNewKey] integerValue];
        if (status == AVPlayerItemStatusReadyToPlay) {
            // 播放器准备好播放
//            CGFloat duration = CMTimeGetSeconds(_player.currentItem.duration);
//            self.duration = duration;
//            self.presentationSize = _player.currentItem.presentationSize;
            if (self.didReadyToPlayHandler) {
                self.didReadyToPlayHandler(self);
            }
        } else if (status == AVPlayerItemStatusFailed) {
            // 播放器加载资源失败
            self.playStatus = XHVideoPlayStatusFailed;
        } else if (status == AVPlayerItemStatusUnknown) {
            // 将要加载资源
            self.playStatus = XHVideoPlayStatusInit;
        }
        
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSArray *array = change[NSKeyValueChangeNewKey];
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue]; //本次缓冲的时间范围
        NSTimeInterval totalBuffer = CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration);
        self.loadedTime = totalBuffer;
        if (self.loadedTimeRangesObserverHandler) {
            self.loadedTimeRangesObserverHandler(self, totalBuffer, self.duration);
        }
    }  else if ([keyPath isEqualToString:@"timeControlStatus"]) {
        if (@available(iOS 10.0, *)) {
            AVPlayerTimeControlStatus timeControlStatus = [change[NSKeyValueChangeNewKey] integerValue];
            if (timeControlStatus == AVPlayerTimeControlStatusPaused) {
                // 暂停
                if (self.playStatus != XHVideoPlayStatusEnd) {
                    self.playStatus = XHVideoPlayStatusPase;
                }
            } else if (timeControlStatus == AVPlayerTimeControlStatusWaitingToPlayAtSpecifiedRate) {
                // 缓冲
                self.playStatus = XHVideoPlayStatusWaitingBuff;
            } else if (timeControlStatus == AVPlayerTimeControlStatusPlaying) {
                // 播放
                self.playStatus = XHVideoPlayStatusPlayIng;
            }
//            NSLog(@"timeControlStatus = %ld", timeControlStatus);
        } else {
            // Fallback on earlier versions
        }
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        if (IOS_VERSION_10_BELOW) {
            if (_playStatus == XHVideoPlayStatusPlayIng || _playStatus == XHVideoPlayStatusWaitingBuff) {
                BOOL playbackBufferEmpty = [change[NSKeyValueChangeNewKey] boolValue];
                if (playbackBufferEmpty) {
                    self.playStatus = XHVideoPlayStatusWaitingBuff;
                } else {
                    self.playStatus = XHVideoPlayStatusPlayIng;
                }
            }
        }
    } else if ([keyPath isEqualToString:@"presentationSize"]) {
        CGSize presentationSize = [change[NSKeyValueChangeNewKey] CGSizeValue];
        self.presentationSize = presentationSize;
//        NSLog(@"%@", NSStringFromCGSize(presentationSize));
    } else if ([keyPath isEqualToString:@"duration"]) {
        CMTime time = [change[NSKeyValueChangeNewKey] CMTimeValue];
        CGFloat duration = CMTimeGetSeconds(time);
        self.duration = duration;
//        NSLog(@"duration = %lf", duration);
    } else if ([keyPath isEqualToString:kContentOffset]) {
        // 滑动事件
        NSNumber *number = change[NSKeyValueChangeNewKey];
        [self scollViewObserver:self.scollView contentOffsex:[number CGPointValue]];
    }
}

/// 播放完成
- (void)playDidEnd:(NSNotification *)noti {
    NSLog(@"播放完成");
    if ([noti.object isEqual:_player.currentItem]) {
        self.playStatus = XHVideoPlayStatusEnd;
    }
}

/// 播放失败
- (void)playDidFailed:(NSNotification *)noti {
    NSLog(@"播放失败");
    if ([noti.object isEqual:_player.currentItem]) {
        self.playStatus = XHVideoPlayStatusFailed;
    }
}

/// 播放中断
- (void)playDidStalled:(NSNotification *)noti {
    //    if ([noti.object isEqual:_player.currentItem]) {
    //
    //    }
    NSLog(@"播放中断");
}

/// 声音被打断的通知（电话打来）
- (void)audioSessionInterruption:(NSNotification *)noti {
    NSLog(@"声音被打断的通知（电话打来）");
    if ([noti.object isEqual:_player.currentItem]) {
        if (self.playStatus == XHVideoPlayStatusWaitingBuff || self.playStatus == XHVideoPlayStatusPlayIng) {
            self.playStatus = XHVideoPlayStatusPase;
        }
    }
}

/// 耳机插入和拔出的通知
- (void)routeChange:(NSNotification *)noti {
    NSLog(@"耳机插入和拔出的通知");
    if ([noti.object isEqual:_player.currentItem]) {
        if (self.playStatus == XHVideoPlayStatusWaitingBuff || self.playStatus == XHVideoPlayStatusPlayIng) {
            self.playStatus = XHVideoPlayStatusPase;
        }
    }
}

/// 进入后台
- (void)resignActive:(NSNotification *)noti {
    NSLog(@"进入后台");
    if ([noti.object isEqual:_player.currentItem]) {
        if (self.playStatus == XHVideoPlayStatusWaitingBuff || self.playStatus == XHVideoPlayStatusPlayIng) {
            self.playStatus = XHVideoPlayStatusPase;
        }
    }
}

#pragma mark - Setter Methods

- (void)setPlayStatus:(XHVideoPlayStatus)playStatus {
    if (_playStatus != playStatus) {
        _playStatus = playStatus;
        if (self.playStatusObserverHandler) {
            self.playStatusObserverHandler(self, playStatus);
        }
    } else {
        _playStatus = playStatus;
    }
    
    if (_playStatus == XHVideoPlayStatusInit || _playStatus == XHVideoPlayStatusEnd) {
        _placeholderImageView.hidden = NO;
    } else {
        _placeholderImageView.hidden = YES;
    }
}

- (void)setPlaceholderImage:(UIImage *)placeholderImage {
    _placeholderImage = placeholderImage;
    self.placeholderImageView.image = placeholderImage;
}

#pragma mark - Getter Methods

- (XHVideoPlayContentView *)playView {
    if (!_playView) {
        _playView = [[XHVideoPlayContentView alloc] init];
        _playView.playerLayer.player = _player;
    }
    return _playView;
}

- (UIImageView *)placeholderImageView {
    if (!_placeholderImageView) {
        _placeholderImageView = [[UIImageView alloc] init];
        _placeholderImageView.backgroundColor = [UIColor clearColor];
        [_playView insertSubview:_placeholderImageView atIndex:0];
        _placeholderImageView.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSMutableArray *constraints = [NSMutableArray array];
        
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_placeholderImageView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_placeholderImageView)]];
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_placeholderImageView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_placeholderImageView)]];
        
        [self.playView addConstraints:constraints];
    }
    return _placeholderImageView;
}

#pragma mark - dealloc

- (void)dealloc {
    
    if (_player) {
        [_player.currentItem removeObserver:self forKeyPath:@"status"];
        [_player.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [_player.currentItem removeObserver:self forKeyPath:@"presentationSize"];
        [_player.currentItem removeObserver:self forKeyPath:@"duration"];

        if (@available(iOS 10.0, *)) {
            [_player removeObserver:self forKeyPath:@"timeControlStatus"];
        } else {
            [_player.currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        }
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    
    if (self.scollView) {
        [self.scollView removeObserver:self forKeyPath:kContentOffset];
    }
    
    if (_timeObserve) {
        [_player removeTimeObserver:_timeObserve];
        _timeObserve = nil;
    }
}

@end

@implementation XHBaseVideoPlayer (ScrollView)

- (void)setScollView:(UIScrollView *)scollView {
    UIScrollView *oldScrollView = objc_getAssociatedObject(self, @selector(scollView));
    if (oldScrollView) {
        [oldScrollView removeObserver:self forKeyPath:kContentOffset];
    }
    if (scollView) {
        [scollView addObserver:self forKeyPath:kContentOffset options:NSKeyValueObservingOptionNew context:nil];
    }
    objc_setAssociatedObject(self, @selector(scollView), scollView, OBJC_ASSOCIATION_ASSIGN);
}

- (UIScrollView *)scollView {
    return objc_getAssociatedObject(self, @selector(scollView));
}

- (void)setPauseWhenScrollDisappeared:(BOOL)pauseWhenScrollDisappeared {
    objc_setAssociatedObject(self, @selector(pauseWhenScrollDisappeared), @(pauseWhenScrollDisappeared), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)pauseWhenScrollDisappeared {
    return [objc_getAssociatedObject(self, @selector(pauseWhenScrollDisappeared)) boolValue];
}

- (void)setPlayerViewWillDisappearHandler:(void (^)(XHBaseVideoPlayer * _Nonnull))playerViewWillDisappearHandler {
    objc_setAssociatedObject(self, @selector(playerViewWillDisappearHandler), playerViewWillDisappearHandler, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(XHBaseVideoPlayer * _Nonnull))playerViewWillDisappearHandler {
    return objc_getAssociatedObject(self, @selector(playerViewWillDisappearHandler));
}

- (void)scollViewObserver:(UIScrollView *)scrollView contentOffsex:(CGPoint)contentOffset {
    
    if (scrollView && self.playView.superview) {
//        [[UIApplication sharedApplication] delegate].window;
        if (self.pauseWhenScrollDisappeared) {
            CGRect playViewRect = [self.playView convertRect:self.playView.bounds toView:nil];
            CGRect scrollViewRect = [scrollView convertRect:scrollView.bounds toView:nil];
            if (!CGRectIntersectsRect(scrollViewRect, playViewRect)) {
                // 不相交
                if (self.playStatus == XHVideoPlayStatusWaitingBuff || self.playStatus == XHVideoPlayStatusPlayIng) {
                    [self pause];
                }
            } else {
                // 相交
            }
        }
    }
}

@end
