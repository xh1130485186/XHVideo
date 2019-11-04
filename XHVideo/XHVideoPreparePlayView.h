//
//  XHVideoPreparePlayView.h
//  BSGrowthViewing
//
//  Created by 向洪 on 2019/10/28.
//  Copyright © 2019 向洪. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface XHVideoPreparePlayView : UIView

@property (nonatomic, strong, readonly) UIImageView *backgroundImageView;
@property (nonatomic, strong, readonly) UIImageView *playImageView;
@property (nonatomic, strong, readonly) UILabel *timeLabel;

@property (nonatomic, copy) void (^didTapGestureRecognizerForPlayHandler) (void);

@end

NS_ASSUME_NONNULL_END
