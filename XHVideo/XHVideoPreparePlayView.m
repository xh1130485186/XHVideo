//
//  XHVideoPreparePlayView.m
//  BSGrowthViewing
//
//  Created by 向洪 on 2019/10/28.
//  Copyright © 2019 向洪. All rights reserved.
//

#import "XHVideoPreparePlayView.h"
#import "XHVideoRecordDefines.h"

@interface XHVideoPreparePlayView ()

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIImageView *playImageView;
@property (nonatomic, strong) UILabel *timeLabel;

@end

@implementation XHVideoPreparePlayView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    
    self.backgroundColor = [UIColor clearColor];
    
    _playImageView = [[UIImageView alloc] init];
    [_playImageView setImage:XHVideoImage(@"icon_video_player_play")];
    [self addSubview:_playImageView];
    
    _timeLabel = [[UILabel alloc] init];
    _timeLabel.textColor = [UIColor whiteColor];
    _timeLabel.font = [UIFont systemFontOfSize:13];
    [self addSubview:_timeLabel];
    
    _playImageView.translatesAutoresizingMaskIntoConstraints = NO;
    _timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSMutableArray *constraints = [NSMutableArray array];
    
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_playImageView(20)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_playImageView)]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_playImageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_playImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_playImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_playImageView attribute:NSLayoutAttributeHeight multiplier:1 constant:0]];
    
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_timeLabel]-10-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_timeLabel)]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_timeLabel]-10-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_timeLabel)]];
    
    [self addConstraints:constraints];
    
    
    UITapGestureRecognizer *top = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizer:)];
    [self addGestureRecognizer:top];
}

#pragma mark - 手势

- (void)tapGestureRecognizer:(UITapGestureRecognizer *)tapGesture {
    if (self.didTapGestureRecognizerForPlayHandler) {
        self.didTapGestureRecognizerForPlayHandler();
    }
}

- (UIImageView *)backgroundImageView {
    if (!_backgroundImageView) {
        _backgroundImageView = [[UIImageView alloc] init];
        _backgroundImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self insertSubview:_backgroundImageView atIndex:0];
        NSMutableArray *constraints = [NSMutableArray array];
        
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_backgroundImageView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_backgroundImageView)]];
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_backgroundImageView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_backgroundImageView)]];
        
        [self addConstraints:constraints];
    }
    return _backgroundImageView;
}
 
@end
