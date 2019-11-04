//
//  XHVideoRecordController.h
//  视频录制播放
//
//  Created by 向洪 on 2018/4/2.
//  Copyright © 2018年 向洪. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XHVideoRecordController;

@protocol XHVideoRecordControllerDelegate <NSObject>

@optional
/// 点击取消
- (void)videoRecordControllerDelegateDidCancel:(XHVideoRecordController *)videoRecordController;
/// 录制结束
- (void)videoRecordController:(XHVideoRecordController *)videoRecordController recordFinishWithVideoUrl:(NSURL *)videoUrl;

@end

/// 视频录制控制器
@interface XHVideoRecordController : UIViewController

@property (nonatomic, assign, readonly) NSTimeInterval maxRecordTime;   ///< 最大时间
@property (nonatomic, weak) id<XHVideoRecordControllerDelegate> delegate;

/// 初始化
/// @param maxRecordTime 最大时间
- (instancetype)initWithMaxRecordTime:(NSTimeInterval)maxRecordTime;

@end
