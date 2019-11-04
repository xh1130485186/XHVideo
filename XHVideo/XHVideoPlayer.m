//
//  XHVideoPlayerView.m
//  BSGrowthViewing
//
//  Created by 向洪 on 2019/10/28.
//  Copyright © 2019 向洪. All rights reserved.
//

#import "XHVideoPlayer.h"
#import "XHVideoPreparePlayView.h"
#import "XHVideoFailedView.h"
#import "XHLoadingView.h"
#import "XHVideoPlayToolView.h"
#import <AVFoundation/AVFoundation.h>


@interface XHVideoPlayer () <XHVideoPlayToolViewDelegate>

@property (nonatomic, strong) XHVideoPreparePlayView *preparePlayView;
@property (nonatomic, strong) XHVideoPlayToolView *toolView;
@property (nonatomic, strong) XHVideoFailedView *videoFailedView;
@property (nonatomic, strong) XHLoadingView *loadingView;

@end

@implementation XHVideoPlayer

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize {

    __weak __typeof(self)weakSelf = self;
    
    _preparePlayView = [[XHVideoPreparePlayView alloc] init];
    _preparePlayView.didTapGestureRecognizerForPlayHandler = ^{
        [weakSelf play];
    };
    [self.playView addSubview:_preparePlayView];

    _preparePlayView.translatesAutoresizingMaskIntoConstraints = NO;
    NSMutableArray *constraints = [NSMutableArray array];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_preparePlayView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_preparePlayView)]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_preparePlayView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_preparePlayView)]];
    [self.playView addConstraints:constraints];
    
    self.playStatusObserverHandler = ^(XHBaseVideoPlayer * _Nonnull player, XHVideoPlayStatus playStatus) {
        
        if (playStatus == XHVideoPlayStatusWaitingBuff || playStatus == XHVideoPlayStatusPlayIng) {
            weakSelf.preparePlayView.hidden = YES;
        } else {
            weakSelf.preparePlayView.hidden = NO;
        }
        
        if (playStatus == XHVideoPlayStatusFailed) {
            [weakSelf showErrorView];
        }
        
        if (playStatus == XHVideoPlayStatusWaitingBuff) {
            [weakSelf.loadingView show:weakSelf.playView];
        } else {
            [weakSelf.loadingView dismiss];
        }
        
        if (playStatus == XHVideoPlayStatusPlayIng) {
            weakSelf.toolView.hidden = NO;
            weakSelf.toolView.loadedProgress = weakSelf.loadedTime/weakSelf.duration;
        } else {
            weakSelf.toolView.hidden = YES;
        }
    };
    
    self.didReadyToPlayHandler = ^(XHBaseVideoPlayer * _Nonnull player) {
        weakSelf.preparePlayView.timeLabel.text = [weakSelf timeFormatted:player.duration totalSeconds:player.duration];
    };
    
    self.periodicTimeObserverForIntervalHandler = ^(XHBaseVideoPlayer * _Nonnull player, NSTimeInterval currentTime, NSTimeInterval duration) {
        weakSelf.toolView.timeLabel.text = [NSString stringWithFormat:@"%@/%@", [weakSelf timeFormatted:currentTime totalSeconds:duration], [weakSelf timeFormatted:duration totalSeconds:duration]];
        if (duration != 0) {
            weakSelf.toolView.playProgress = currentTime/duration;
//            NSLog(@"playProgress = %lf", weakSelf.toolView.playProgress);
        }
    };
    self.loadedTimeRangesObserverHandler = ^(XHBaseVideoPlayer * _Nonnull player, NSTimeInterval loadedTime, NSTimeInterval duration) {
        if (weakSelf.playStatus == XHVideoPlayStatusPlayIng) {
            weakSelf.toolView.loadedProgress = loadedTime/duration;
//            NSLog(@"loadedProgress = %lf", weakSelf.toolView.loadedProgress);
        }
    };
}

- (NSString *)timeFormatted:(NSInteger)currentSeconds totalSeconds:(NSInteger)totalSeconds {
    
    NSInteger seconds = 0;
    NSInteger minutes = 0;
    NSInteger hours = 0;
    
    if (totalSeconds < 3600) {
        seconds = currentSeconds%60;
        minutes = (currentSeconds/60)%60;
        return [NSString stringWithFormat:@"%02zi:%02zi", minutes, seconds];
    } else {
        seconds = currentSeconds%60;
        minutes = (currentSeconds/60)%60;
        hours = currentSeconds/3600;
        return [NSString stringWithFormat:@"%02zi:%02zi:%02zi", hours, minutes, seconds];
    }
}

#pragma mark - videoFailedView

- (void)showErrorView {
    if (_videoFailedView.superview == nil) {
        [self.playView addSubview:self.videoFailedView];
        NSMutableArray *constraints = [NSMutableArray array];
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_videoFailedView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_videoFailedView)]];
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_videoFailedView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_videoFailedView)]];
        [self.playView addConstraints:constraints];
    }
}

- (XHVideoFailedView *)videoFailedView {
    if (!_videoFailedView) {
        _videoFailedView = [[XHVideoFailedView alloc] init];
        _videoFailedView.translatesAutoresizingMaskIntoConstraints = NO;
        __weak __typeof(self)weakSelf = self;
        _videoFailedView.retryHandler = ^(XHVideoFailedView * _Nonnull failedView) {
            [failedView removeFromSuperview];
            weakSelf.url = weakSelf.url;
        };
    }
    return _videoFailedView;
}

#pragma mark - toolView

- (XHVideoPlayToolView *)toolView {
    if (!_toolView) {
        _toolView = [[XHVideoPlayToolView alloc] init];
        _toolView.delegate = self;
        _toolView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.playView addSubview:_toolView];
        NSMutableArray *constraints = [NSMutableArray array];
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_toolView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_toolView)]];
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_toolView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_toolView)]];
        [self.playView addConstraints:constraints];
    }
    return _toolView;
}


- (void)videoPlayToolViewDidTapGestureRecognizer:(XHVideoPlayToolView *)toolView {
    [self pause];
}

- (void)videoPlayToolViewDidFullScreen:(XHVideoPlayToolView *)toolView isFullScreen:(BOOL)isFullScreen {
    
}

#pragma mark - loadingView

- (XHLoadingView *)loadingView {
    if (!_loadingView) {
        _loadingView = [[XHLoadingView alloc] initWithAnimationType:XHLoadingRingSpinningAnimation];
        _loadingView.backgroundColor = [UIColor clearColor];
    }
    return _loadingView;
}

@end
