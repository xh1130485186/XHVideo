//
//  XHVideoRecorder.h
//  视频录制播放
//
//  Created by 向洪 on 2018/4/1.
//  Copyright © 2018年 向洪. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AVAssetWriteManager.h"

NS_ASSUME_NONNULL_BEGIN

@class XHVideoRecorder;

@protocol XHVideoRecorderDelegate <NSObject>

/// 闪光灯状态更新
- (void)videoRecorder:(XHVideoRecorder *)videoRecorder updateFlashState:(AVCaptureTorchMode)state;
/// 录制进度更新
- (void)videoRecorder:(XHVideoRecorder *)videoRecorder updateRecordingProgress:(CGFloat)progress;
/// 录制状态更新
- (void)videoRecorder:(XHVideoRecorder *)videoRecorder updateRecordState:(XHRecordState)recordState;

@end


/// 视频录制
@interface XHVideoRecorder : NSObject


@property (nonatomic, weak) id<XHVideoRecorderDelegate>delegate;

@property (nonatomic, assign) XHRecordState recordState; ///< 录制状态
@property (nonatomic, strong, readonly) NSURL *videoUrl; ///< 输出地址
@property (nonatomic, assign, readonly) NSTimeInterval maxRecordTime;   ///< 最大时间
@property (nonatomic, strong, readonly) AVCaptureVideoPreviewLayer *previewlayer; ///< 输出layer

/// 初始化
/// @param type 输出尺寸类型
/// @param maxRecordTime 最大时间
- (instancetype)initWithVideoRecordViewType:(XHVideoRecordOutputSizeType)type maxRecordTime:(NSInteger)maxRecordTime;

/// 翻转相机
- (void)turnCamera;
/// 打开关闭闪光灯
- (void)switchflash;

/// 开始录制
- (void)startRecord;
/// 结束录制
- (void)stopRecord;
/// 重置
- (void)reset;


// 权限
+ (AVAuthorizationStatus)audioAuthorizationStatus;
+ (AVAuthorizationStatus)videoAuthorizationStatus;
+ (void)requestAccessForAudioAuthorizationAndCompletionHandler:(void (^)(BOOL granted))handler;
+ (void)requestAccessForVideoAuthorizationAndCompletionHandler:(void (^)(BOOL granted))handler;


@end


NS_ASSUME_NONNULL_END
