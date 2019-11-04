//
//  XHVideoPlayToolView.m
//  XHKitDemo
//
//  Created by 向洪 on 2019/10/29.
//  Copyright © 2019 向洪. All rights reserved.
//

#import "XHVideoPlayToolView.h"
#import "XHVideoRecordDefines.h"

@interface XHVideoPlayToolView ()

//@property (nonatomic, strong) UIButton *pauseButton;
@property (nonatomic, strong) UIButton *fullScreenButton;
@property (nonatomic, strong) UILabel *timeLabel;

@property (nonatomic, strong) CAShapeLayer *playShapeLayer;
@property (nonatomic, strong) CAShapeLayer *loadedShapeLayer;

@end


@implementation XHVideoPlayToolView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    

    _timeLabel = [[UILabel alloc] init];
    _timeLabel.textColor = [UIColor whiteColor];
    _timeLabel.font = [UIFont systemFontOfSize:13];
    [self addSubview:_timeLabel];
    _fullScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_fullScreenButton setImage:XHVideoImage(@"icon_video_player_full") forState:UIControlStateNormal];
    [_fullScreenButton setImage:XHVideoImage(@"icon_video_player_notfull") forState:UIControlStateSelected];
    [_fullScreenButton addTarget:self action:@selector(fullScreenAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_fullScreenButton];
    
    //-- 全屏问题等待实现
    _fullScreenButton.hidden = YES;
    
    _timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _fullScreenButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSMutableArray *constraints = [NSMutableArray array];
    
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[_timeLabel]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_timeLabel)]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_timeLabel]-10-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_timeLabel)]];
    
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_fullScreenButton(24)]-4-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_fullScreenButton)]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-4-[_fullScreenButton(24)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_fullScreenButton)]];
    
    [self addConstraints:constraints];
    
    
    // 进度
    _progressColor = [UIColor colorWithRed:20/255.f green:208/255.f blue:137/255.f alpha:1];
    
    _loadedShapeLayer = [CAShapeLayer layer];
    _loadedShapeLayer.contentsScale = [UIScreen mainScreen].scale;
    _loadedShapeLayer.strokeColor = [UIColor colorWithWhite:1 alpha:0.8].CGColor;
    _loadedShapeLayer.fillColor = [UIColor colorWithWhite:1 alpha:0.5].CGColor;
    _loadedShapeLayer.lineWidth = 2;
    _loadedShapeLayer.strokeStart = 0;
    _loadedShapeLayer.strokeEnd = 0;
    _loadedShapeLayer.lineCap = kCALineCapRound;
    
    [self.layer addSublayer:_loadedShapeLayer];
    
    _playShapeLayer = [CAShapeLayer layer];
    _playShapeLayer.contentsScale = [UIScreen mainScreen].scale;
    _playShapeLayer.strokeColor = _progressColor.CGColor;
    _playShapeLayer.fillColor = [UIColor colorWithWhite:1 alpha:0.5].CGColor;
    _playShapeLayer.lineWidth = 2;
    _playShapeLayer.strokeStart = 0;
    _playShapeLayer.strokeEnd = 0;
    _playShapeLayer.lineCap = kCALineCapRound;
//
    [self.layer addSublayer:_playShapeLayer];
    
    UITapGestureRecognizer *top = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizer:)];
    [self addGestureRecognizer:top];
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = CGRectGetWidth(self.frame);
    CGFloat height = CGRectGetHeight(self.frame);
    _playShapeLayer.frame = CGRectMake(0, height-2, width, 2);
    _loadedShapeLayer.frame = _playShapeLayer.frame;
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:CGPointMake(0, 1)];
    [bezierPath addLineToPoint:CGPointMake(width, 1)];
    _playShapeLayer.path = bezierPath.CGPath;
    _loadedShapeLayer.path = bezierPath.CGPath;
    
}

- (void)setPlayProgress:(CGFloat)playProgress {
    _playProgress = playProgress;
    _playShapeLayer.strokeEnd = playProgress;
}

- (void)setLoadedProgress:(CGFloat)loadedProgress {
    _loadedProgress = loadedProgress;
    _loadedShapeLayer.strokeEnd = loadedProgress;
}

- (void)setProgressColor:(UIColor *)progressColor {
    _progressColor = progressColor;
    _playShapeLayer.strokeColor = progressColor.CGColor;
    _loadedShapeLayer.strokeColor = progressColor.CGColor;
}

#pragma mark - 事件

- (void)fullScreenAction:(UIButton *)sender {
    if (_delegate && [_delegate conformsToProtocol:@protocol(XHVideoPlayToolViewDelegate)] && [_delegate respondsToSelector:@selector(videoPlayToolViewDidFullScreen:isFullScreen:)]) {
        [_delegate videoPlayToolViewDidFullScreen:self isFullScreen:sender.selected];
    }
}

- (void)tapGestureRecognizer:(UITapGestureRecognizer *)tapGesture {
    if (_delegate && [_delegate conformsToProtocol:@protocol(XHVideoPlayToolViewDelegate)] && [_delegate respondsToSelector:@selector(videoPlayToolViewDidTapGestureRecognizer:)]) {
        [_delegate videoPlayToolViewDidTapGestureRecognizer:self];
    }
}
@end
