//
//  XHLoadingView.m
//  BSGrowthViewing
//
//  Created by 向洪 on 2018/11/1.
//  Copyright © 2018 向洪. All rights reserved.
//

#import "XHLoadingView.h"

#define DOT_W 16

@interface XHLoadingView ()

@property (nonatomic, strong) UIView *displayView;
@property (nonatomic, assign) NSInteger count;
@property (nonatomic, assign) BOOL isAnimation;

// XHLoadingTreeDotAnimation
@property (nonatomic, strong) UIView *dot;
@property (nonatomic, strong) UIView *dot1;
@property (nonatomic, strong) UIView *dot2;
@property (nonatomic, strong) UIView *dot3;

// XHLoadingRingSpinningAnimation
@property (nonatomic, strong, readonly) CAGradientLayer *ringSpinningGradientLayer;
@property (nonatomic, strong, readonly) CAShapeLayer *ringSpinningShapeLayer;

@end

@implementation XHLoadingView

+ (XHLoadingView *)sharedInstance {
    
    static XHLoadingView *loadingView;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        loadingView = [[XHLoadingView alloc] initWithAnimationType:XHLoadingTreeDotAnimation];
        loadingView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
//        loadingView.userInteractionEnabled = NO;
    });
    return loadingView;
}

+ (XHLoadingView *)show {
    return [XHLoadingView show:[[[UIApplication sharedApplication] delegate] window]];
}

+ (XHLoadingView *)show:(UIView *)superView {
    XHLoadingView *loadingView = [XHLoadingView sharedInstance];
    [loadingView show:superView];
    return loadingView;
}

+ (XHLoadingView *)hide {
    XHLoadingView *loadingView = [XHLoadingView sharedInstance];
    [loadingView hide];
    return loadingView;
}

+ (XHLoadingView *)dismiss {
    XHLoadingView *loadingView = [XHLoadingView sharedInstance];
    [loadingView dismiss];
    return loadingView;
}

- (instancetype)initWithAnimationType:(XHLoadingAnimationType)animationType {
    self = [super init];
    if (self) {
        _animationType = animationType;
    }
    return self;
}

- (void)show {
    [self show:[[[UIApplication sharedApplication] delegate] window]];
}

- (void)show:(UIView *)superView {
    self.displayView = superView;
    self.count ++;
}

- (void)hide {
    self.count --;
}

- (void)dismiss {
    self.count = 0;
}

- (void)setAnimationType:(XHLoadingAnimationType)animationType {
    
    if (_isAnimation == NO) {
        _animationType = animationType;
    }
}

- (void)setCount:(NSInteger)count {
    
    if (count <= 0) {
        _isAnimation = NO;
        [self removeFromSuperview];
        [self restoreState];
    } else {
        if (self.superview == nil) {
            [self.displayView addSubview:self];
            UIView *contentView = self;
            contentView.translatesAutoresizingMaskIntoConstraints = NO;
            NSMutableArray *constraints = [NSMutableArray array];
            [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[contentView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(contentView)]];
            [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[contentView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(contentView)]];
            [self.displayView addConstraints:constraints];
        }
        if (_isAnimation == NO) {
            _isAnimation = YES;
        }
    }
    _count = count;
}

- (void)restoreState {
    
    [_dot1.layer removeAllAnimations];
    [_dot2.layer removeAllAnimations];
    [_dot3.layer removeAllAnimations];
    [_dot.layer removeAllAnimations];
    
    [_ringSpinningGradientLayer removeAllAnimations];
    
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}


#pragma mark - Animation

- (void)loadingAnimation {
    [self restoreState];
    if (_animationType == XHLoadingTreeDotAnimation) {
        [self loadingTreeDotAnimation];
    } else if (_animationType == XHLoadingRingSpinningAnimation) {
        [self loadingRingSpinningAnimation];
    }
}

- (void)loadingTreeDotAnimation {
    
    if (!self.dot) {
        UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(0, 0, DOT_W, DOT_W)];
        dot.backgroundColor = [UIColor whiteColor];
        dot.layer.cornerRadius = DOT_W / 2;
        dot.clipsToBounds = YES;
        self.dot = dot;
    }
    
    if (!self.dot1) {
        UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(0, 0, DOT_W, DOT_W)];
        dot.backgroundColor = [UIColor whiteColor];
        dot.layer.cornerRadius = DOT_W / 2;
        dot.clipsToBounds = YES;
        self.dot1 = dot;
    }
    
    if (!self.dot2) {
        UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(0, 0, DOT_W, DOT_W)];
        dot.backgroundColor = [UIColor whiteColor];
        dot.layer.cornerRadius = DOT_W / 2;
        dot.clipsToBounds = YES;
        self.dot2 = dot;
    }
    
    if (!self.dot3) {
        UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(0, 0, DOT_W, DOT_W)];
        dot.backgroundColor = [UIColor whiteColor];
        dot.layer.cornerRadius = DOT_W / 2;
        dot.clipsToBounds = YES;
        self.dot3 = dot;
    }

    CGPoint centerPoint = CGPointMake(CGRectGetWidth(self.bounds)*0.5, CGRectGetHeight(self.bounds)*0.5);
    _dot.center = centerPoint;
    _dot1.center = centerPoint;
    _dot2.center = centerPoint;
    _dot3.center = centerPoint;
    
    self.dot.transform = CGAffineTransformMakeTranslation(-DOT_W * 3, 0);
//    self.dot.alpha = 0;
    self.dot1.transform = CGAffineTransformMakeTranslation(-DOT_W, 0);
    self.dot3.transform = CGAffineTransformMakeTranslation(DOT_W, 0);

    [self addSubview:self.dot];
    [self addSubview:self.dot1];
    [self addSubview:self.dot2];
    [self addSubview:self.dot3];
    
    CABasicAnimation *moveDotAnimation = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
    moveDotAnimation.duration = 0.8;
    moveDotAnimation.fromValue = @(-DOT_W * 3);
    moveDotAnimation.toValue = @(-DOT_W);
    moveDotAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    moveDotAnimation.repeatCount = CGFLOAT_MAX;
    moveDotAnimation.removedOnCompletion = NO;
    moveDotAnimation.fillMode = kCAFillModeRemoved;
    [self.dot.layer addAnimation:moveDotAnimation forKey:@"moveDotAnimation"];

    CABasicAnimation *moveDot1Animation = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
    moveDot1Animation.duration = 0.8;
    moveDot1Animation.fromValue = @(-DOT_W);
    moveDot1Animation.toValue = @(0);
    moveDot1Animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    moveDot1Animation.repeatCount = CGFLOAT_MAX;
    moveDot1Animation.removedOnCompletion = NO;
    moveDot1Animation.fillMode = kCAFillModeRemoved;
    [self.dot1.layer addAnimation:moveDot1Animation forKey:@"moveDot1Animation"];

    CABasicAnimation *moveDot2Animation = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
    moveDot2Animation.duration = 0.8;
    moveDot2Animation.fromValue = @(0);
    moveDot2Animation.toValue = @(DOT_W);
    moveDot2Animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    moveDot2Animation.repeatCount = CGFLOAT_MAX;
    moveDot2Animation.removedOnCompletion = NO;
    moveDot2Animation.fillMode = kCAFillModeRemoved;
    [self.dot2.layer addAnimation:moveDot2Animation forKey:@"moveDot2Animation"];

    CABasicAnimation *moveDot3Animation = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
    moveDot3Animation.duration = 0.8;
    moveDot3Animation.fromValue = @(DOT_W);
    moveDot3Animation.toValue = @(DOT_W * 2);
    moveDot3Animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    moveDot3Animation.repeatCount = CGFLOAT_MAX;
    moveDot3Animation.removedOnCompletion = NO;
    moveDot3Animation.fillMode = kCAFillModeForwards;
    [self.dot3.layer addAnimation:moveDot3Animation forKey:@"moveDot3Animation"];


    CABasicAnimation *opacityDotAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityDotAnimation.duration = 0.8;
    opacityDotAnimation.fromValue = @(0);
    opacityDotAnimation.toValue = @(1);
    opacityDotAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    opacityDotAnimation.repeatCount = CGFLOAT_MAX;
    opacityDotAnimation.removedOnCompletion = NO;
    opacityDotAnimation.fillMode = kCAFillModeRemoved;
    [self.dot.layer addAnimation:opacityDotAnimation forKey:@"opacityDotAnimation"];

    CABasicAnimation *opacityDot3Animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityDot3Animation.duration = 0.8;
    opacityDot3Animation.fromValue = @(1);
    opacityDot3Animation.toValue = @(0);
    opacityDot3Animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    opacityDot3Animation.repeatCount = CGFLOAT_MAX;
    opacityDot3Animation.removedOnCompletion = NO;
    opacityDot3Animation.fillMode = kCAFillModeRemoved;
    [self.dot3.layer addAnimation:opacityDot3Animation forKey:@"opacityDot3Animation"];
    
}

- (void)loadingRingSpinningAnimation {
    
    if (!_ringSpinningShapeLayer) {
        _ringSpinningShapeLayer = [CAShapeLayer layer];
        _ringSpinningShapeLayer.strokeColor = [UIColor whiteColor].CGColor;
        _ringSpinningShapeLayer.fillColor = [UIColor clearColor].CGColor;
        _ringSpinningShapeLayer.strokeStart = 0.15;
        _ringSpinningShapeLayer.strokeEnd = 0.8;
        _ringSpinningShapeLayer.lineCap = kCALineCapRound;
//        _ringSpinningShapeLayer.bounds = CGRectMake(0, 0, 58, 58);
//        _ringSpinningShapeLayer.position = centerPoint;
    }
    
    if (!_ringSpinningGradientLayer) {
        _ringSpinningGradientLayer = [CAGradientLayer layer];
        _ringSpinningGradientLayer.startPoint = CGPointMake(1, 1);
        _ringSpinningGradientLayer.endPoint = CGPointMake(0, 0);
        _ringSpinningGradientLayer.locations = @[@(0), @(0.3), @(0.5), @(1)];
        _ringSpinningGradientLayer.mask = _ringSpinningShapeLayer;
        
        UIColor *lineColor = [UIColor whiteColor];
        _ringSpinningGradientLayer.colors = @[
                                  (id)[UIColor colorWithWhite:0.001 alpha:0.001].CGColor,
                                  (id)[lineColor colorWithAlphaComponent:0.25].CGColor,
                                  (id)lineColor.CGColor];
        
        [self.layer addSublayer:_ringSpinningGradientLayer];
    }
    
    CGPoint centerPoint = CGPointMake(CGRectGetWidth(self.bounds)*0.5, CGRectGetHeight(self.bounds)*0.5);
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(25, 25) radius:23 startAngle:0 endAngle:M_PI * 2 clockwise:YES];
    _ringSpinningShapeLayer.path = bezierPath.CGPath;
    
    _ringSpinningGradientLayer.bounds = CGRectMake(0, 0, 50, 50);
    _ringSpinningGradientLayer.position = centerPoint;
    
    CABasicAnimation *rotationAnim = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnim.toValue = [NSNumber numberWithFloat:2*M_PI];
    rotationAnim.duration = 1;
    rotationAnim.repeatCount = CGFLOAT_MAX;
    rotationAnim.removedOnCompletion = NO;
    [_ringSpinningGradientLayer addAnimation:rotationAnim forKey:@"rotation"];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.isAnimation) {
        
        [self loadingAnimation];
        
//        CGPoint centerPoint = CGPointMake(CGRectGetWidth(self.bounds)*0.5, CGRectGetHeight(self.bounds)*0.5);
//
//        _dot.center = centerPoint;
//        _dot1.center = centerPoint;
//        _dot2.center = centerPoint;
//        _dot3.center = centerPoint;
//
//        if (_ringSpinningShapeLayer) {
//            UIBezierPath *bezierPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(25, 25) radius:23 startAngle:0 endAngle:M_PI * 2 clockwise:YES];
//            _ringSpinningShapeLayer.path = bezierPath.CGPath;
//
//            _ringSpinningGradientLayer.bounds = CGRectMake(0, 0, 50, 50);
//            _ringSpinningGradientLayer.position = centerPoint;
//        }
        
    }
}
@end
