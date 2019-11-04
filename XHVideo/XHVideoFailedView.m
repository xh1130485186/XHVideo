//
//  XHVideoFailedView.m
//  XHKitDemo
//
//  Created by 向洪 on 2019/10/29.
//  Copyright © 2019 向洪. All rights reserved.
//

#import "XHVideoFailedView.h"

@implementation XHVideoFailedView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor colorWithWhite:0/250.f alpha:1];
    
        UILabel *textLabel = [[UILabel alloc] init];
        textLabel.font = [UIFont systemFontOfSize:15];
        textLabel.textColor = [UIColor whiteColor];
        textLabel.textAlignment = NSTextAlignmentCenter;
        textLabel.text = @"视频加载失败，请点击重试";
        [self addSubview:textLabel];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.backgroundColor = [UIColor blueColor];
        button.titleLabel.font = [UIFont systemFontOfSize:14];
        button.layer.cornerRadius = 15;
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTitle:@"点击重试" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(buttonAction) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
        
        textLabel.translatesAutoresizingMaskIntoConstraints = NO;
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSMutableArray *constraints = [NSMutableArray array];
        
        [constraints addObject:[NSLayoutConstraint constraintWithItem:textLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:textLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:-25]];
        
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[button(80)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(button)]];
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[button(30)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(button)]];
        
        [constraints addObject:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:10]];
        
        
        [self addConstraints:constraints];
//        uil
    }
    return self;
}

- (void)buttonAction {
    if (self.retryHandler) {
        self.retryHandler(self);
    }
}


@end
