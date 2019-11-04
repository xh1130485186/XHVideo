//
//  AVAssetWriteManager.h
//  视频录制播放
//
//  Created by 向洪 on 2018/4/2.
//  Copyright © 2018年 向洪. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AVAssetWriteManager;

/// 录制状态，（这里把视频录制与写入合并成一个状态）
typedef NS_ENUM(NSInteger, XHRecordState) {
    XHRecordStateInit = 0,
    XHRecordStatePrepareRecording,
    XHRecordStateRecording,
    XHRecordStateFinish,
    XHRecordStateFail,
};

/// 录制视频的长宽比
typedef NS_ENUM(NSInteger, XHVideoRecordOutputSizeType) {
    XHVideoRecordOutputSize1X1 = 0,
    XHVideoRecordOutputSize4X3,
    XHVideoRecordOutputSizeFullScreen,
};

@protocol AVAssetWriteManagerDelegate <NSObject>

- (void)finishWritingInAssetWriteManager:(AVAssetWriteManager *)assetWriteManager;
- (void)assetWriteManager:(AVAssetWriteManager *)assetWriteManager updateWritingProgress:(CGFloat)progress;

@end

/// 视频写入
@interface AVAssetWriteManager : NSObject

@property (nonatomic, assign) AVCaptureVideoOrientation orientation; ///< 方向
@property (nonatomic, assign) XHRecordState writeState;  ///< 写入状态
@property (nonatomic, assign) XHVideoRecordOutputSizeType viewType; ///< 视频输出尺寸
@property (nonatomic, assign, readonly) CGRect videoRecordViewBounds; ///< 视频尺寸
@property (nonatomic, assign, readonly) NSTimeInterval maxRecordTime; ///< 最大时间

@property (nonatomic, weak) id <AVAssetWriteManagerDelegate> delegate;

@property (nonatomic, retain, nullable) __attribute__((NSObject)) CMFormatDescriptionRef outputVideoFormatDescription;
@property (nonatomic, retain, nullable) __attribute__((NSObject)) CMFormatDescriptionRef outputAudioFormatDescription;
/// 追加数据
- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer ofMediaType:(NSString *)mediaType;

- (instancetype)initWithURL:(NSURL *)URL viewType:(XHVideoRecordOutputSizeType)type maxRecordTime:(NSInteger)maxRecordTime;

/// 开始写人
- (void)startWrite;
/// 停止写入
- (void)stopWrite;

/// 销毁
- (void)destroyWrite;

@end

NS_ASSUME_NONNULL_END
