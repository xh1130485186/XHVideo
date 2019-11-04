//
//  XHVideoFailedView.h
//  XHKitDemo
//
//  Created by 向洪 on 2019/10/29.
//  Copyright © 2019 向洪. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface XHVideoFailedView : UIView

/// 重试事件
@property (nonatomic, copy) void(^retryHandler) (XHVideoFailedView *failedView);

@end

NS_ASSUME_NONNULL_END
