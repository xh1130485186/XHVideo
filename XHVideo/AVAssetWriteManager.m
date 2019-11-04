//
//  AVAssetWriteManager.m
//  视频录制播放
//
//  Created by 向洪 on 2018/4/2.
//  Copyright © 2018年 向洪. All rights reserved.
//

#import "AVAssetWriteManager.h"
#import <CoreMedia/CoreMedia.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <UIKit/UIKit.h>

#define TIMER_INTERVAL 0.05         // 计时器刷新频率

@interface AVAssetWriteManager ()


@property (nonatomic, strong) dispatch_queue_t writeQueue;
@property (nonatomic, strong) NSURL *videoUrl;

@property (nonatomic, strong) AVAssetWriter *assetWriter;

@property (nonatomic, strong) AVAssetWriterInput *assetWriterVideoInput;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterAudioInput;


@property (nonatomic, strong) NSDictionary *videoCompressionSettings;
@property (nonatomic, strong) NSDictionary *audioCompressionSettings;


@property (nonatomic, assign) BOOL canWrite;
@property (nonatomic, assign) CGSize outputSize;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) CGFloat recordTime;

@end

@implementation AVAssetWriteManager


- (instancetype)initWithURL:(NSURL *)URL viewType:(XHVideoRecordOutputSizeType)type maxRecordTime:(NSInteger)maxRecordTime {
    self = [super init];
    if (self) {
        _videoUrl = URL;
        _viewType = type;
        _recordTime = 0;
        _maxRecordTime = maxRecordTime;
        _orientation = AVCaptureVideoOrientationLandscapeRight;
        [self setUpInitWithType:type];
    }
    return self;
}

- (void)setViewType:(XHVideoRecordOutputSizeType)viewType {
    _viewType = viewType;
    [self setUpInitWithType:viewType];
}

#pragma mark - Public methed

//开始写入数据
- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer ofMediaType:(NSString *)mediaType {
    if (sampleBuffer == NULL){
        NSLog(@"empty sampleBuffer");
        return;
    }
    
    @synchronized(self){
        if (self.writeState < XHRecordStateRecording){
            NSLog(@"not ready yet");
            return;
        }
    }
    
    CFRetain(sampleBuffer);
    dispatch_async(self.writeQueue, ^{
        @autoreleasepool {
            @synchronized(self) {
                if (self.writeState > XHRecordStateRecording){
                    CFRelease(sampleBuffer);
                    return;
                }
            }
            
            if (!self.canWrite && mediaType == AVMediaTypeVideo) {
                [self.assetWriter startWriting];
                [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
                self.canWrite = YES;
            }
            
            if (!self.timer) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
                });
                
            }
            //写入视频数据
            if (mediaType == AVMediaTypeVideo) {
                if (self.assetWriterVideoInput.readyForMoreMediaData) {
                    BOOL success = [self.assetWriterVideoInput appendSampleBuffer:sampleBuffer];
                    if (!success) {
                        @synchronized (self) {
                            [self stopWrite];
                            [self destroyWrite];
                        }
                    }
                }
            }
            
            //写入音频数据
            if (mediaType == AVMediaTypeAudio) {
                if (self.assetWriterAudioInput.readyForMoreMediaData) {
                    BOOL success = [self.assetWriterAudioInput appendSampleBuffer:sampleBuffer];
                    if (!success) {
                        @synchronized (self) {
                            [self stopWrite];
                            [self destroyWrite];
                        }
                    }
                }
            }
            
            CFRelease(sampleBuffer);
        }
    } );
}

- (void)startWrite {
    
    if (self.writeState == XHRecordStatePrepareRecording) {
        return;
    }
    self.writeState = XHRecordStatePrepareRecording;
    if (!self.assetWriter) {
        [self setUpWriter];
    }
    
    
}
- (void)stopWrite {
    
    if (self.writeState == XHRecordStateFinish) {
        return;
    }
    
    self.writeState = XHRecordStateFinish;
    [self.timer invalidate];
    self.timer = nil;
    __weak __typeof(self)weakSelf = self;
    if(_assetWriter && _assetWriter.status == AVAssetWriterStatusWriting){
        dispatch_async(self.writeQueue, ^{
            [self.assetWriter finishWritingWithCompletionHandler:^{
                
                dispatch_async(dispatch_get_main_queue(), ^{
                   
                    if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(finishWritingInAssetWriteManager:)]) {
                        [weakSelf.delegate finishWritingInAssetWriteManager:weakSelf];
                    }
                });
                
            }];
        });
    }
}

- (void)updateProgress {
    
    if (_recordTime >= self.maxRecordTime) {
        [self stopWrite];
        return;
    }
    _recordTime += TIMER_INTERVAL;
    if (self.delegate && [self.delegate respondsToSelector:@selector(assetWriteManager:updateWritingProgress:)]) {
        [self.delegate assetWriteManager:self updateWritingProgress:_recordTime/self.maxRecordTime * 1.0];
    }
}

#pragma mark - Private method

// 设置写入视频属性
- (void)setUpWriter {
    
//    BOOL is_landscape = UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]);
    CGRect frame = [UIScreen mainScreen].bounds;
//    CGFloat width = is_landscape?CGRectGetHeight(frame):CGRectGetWidth(frame);
//    CGFloat height = is_landscape?CGRectGetWidth(frame):CGRectGetHeight(frame);
    CGFloat width = CGRectGetWidth(frame);
    CGFloat height = CGRectGetHeight(frame);
    switch (self.viewType) {
        case XHVideoRecordOutputSize1X1:
            _outputSize = CGSizeMake(width, width);
            break;
        case XHVideoRecordOutputSize4X3:
            _outputSize = CGSizeMake(width, width*4/3);
            break;
        case XHVideoRecordOutputSizeFullScreen:
            _outputSize = CGSizeMake(width, height);
            break;
        default:
            _outputSize = CGSizeMake(width, width);
            break;
    }

    self.assetWriter = [AVAssetWriter assetWriterWithURL:self.videoUrl fileType:AVFileTypeMPEG4 error:nil];
    // 写入视频大小
    NSInteger numPixels = self.outputSize.width * self.outputSize.height;
    // 每像素比特
    CGFloat bitsPerPixel = 6.0;
    NSInteger bitsPerSecond = numPixels * bitsPerPixel;
    
    // 码率和帧率设置
    NSDictionary *compressionProperties = @{ AVVideoAverageBitRateKey : @(bitsPerSecond),
                                             AVVideoExpectedSourceFrameRateKey : @(30),
                                             AVVideoMaxKeyFrameIntervalKey : @(30),
                                             AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel };
    
    // 视频属性
    self.videoCompressionSettings = @{ AVVideoCodecKey : AVVideoCodecH264,
                                       AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                                       AVVideoWidthKey : @(self.outputSize.height),
                                       AVVideoHeightKey : @(self.outputSize.width),
                                       AVVideoCompressionPropertiesKey : compressionProperties };
    
    _assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:self.videoCompressionSettings];
    //expectsMediaDataInRealTime 必须设为yes，需要从capture session 实时获取数据
    _assetWriterVideoInput.expectsMediaDataInRealTime = YES;
    
    
    switch (self.orientation) {
        case AVCaptureVideoOrientationLandscapeRight:
            _assetWriterVideoInput.transform = CGAffineTransformMakeRotation(M_PI_2);
            break;
        case AVCaptureVideoOrientationLandscapeLeft:
            _assetWriterVideoInput.transform = CGAffineTransformMakeRotation(M_PI_2*3);
            break;
        case AVCaptureVideoOrientationPortraitUpsideDown:
            _assetWriterVideoInput.transform = CGAffineTransformMakeRotation(0);
            break;
        case AVCaptureVideoOrientationPortrait:
            _assetWriterVideoInput.transform = CGAffineTransformMakeRotation(M_PI);
            break;
            
        default:
            _assetWriterVideoInput.transform = CGAffineTransformMakeRotation(M_PI_2);
            break;
    }
    
    
    // 音频设置
    self.audioCompressionSettings = @{ AVEncoderBitRatePerChannelKey : @(28000),
                                       AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                       AVNumberOfChannelsKey : @(1),
                                       AVSampleRateKey : @(22050) };
    
    
    _assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:self.audioCompressionSettings];
    _assetWriterAudioInput.expectsMediaDataInRealTime = YES;
    
    
    if ([_assetWriter canAddInput:_assetWriterVideoInput]) {
        [_assetWriter addInput:_assetWriterVideoInput];
    }else {
        NSLog(@"AssetWriter videoInput append Failed");
    }
    if ([_assetWriter canAddInput:_assetWriterAudioInput]) {
        [_assetWriter addInput:_assetWriterAudioInput];
    }else {
        NSLog(@"AssetWriter audioInput Append Failed");
    }
    
    self.writeState = XHRecordStateRecording;
}

- (void)setUpInitWithType:(XHVideoRecordOutputSizeType)type {
    CGRect frame = [UIScreen mainScreen].bounds;
//    CGSize size = CGSizeZero;
    switch (type) {
        case XHVideoRecordOutputSize1X1:
            _outputSize = CGSizeMake(CGRectGetWidth(frame), CGRectGetWidth(frame));
            break;
        case XHVideoRecordOutputSize4X3:
            _outputSize = CGSizeMake(CGRectGetWidth(frame), CGRectGetWidth(frame)*4/3);
            break;
        case XHVideoRecordOutputSizeFullScreen:
            _outputSize = CGSizeMake(CGRectGetWidth(frame), CGRectGetHeight(frame));
            break;
        default:
            _outputSize = CGSizeMake(CGRectGetWidth(frame), CGRectGetWidth(frame));
            break;
    }
    _videoRecordViewBounds = CGRectMake(0, 0, _outputSize.width, _outputSize.height);
    
    if (!_writeQueue) {
        _writeQueue = dispatch_queue_create("com.xh.video.recorder", DISPATCH_QUEUE_SERIAL);
    }
}

- (void)destroyWrite {
    
    self.assetWriter = nil;
    self.assetWriterAudioInput = nil;
    self.assetWriterVideoInput = nil;
    self.videoUrl = nil;
    self.recordTime = 0;
    [self.timer invalidate];
    self.timer = nil;
    
}

- (void)dealloc {
    [self destroyWrite];
}

@end
