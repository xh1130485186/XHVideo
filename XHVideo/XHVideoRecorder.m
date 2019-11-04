//
//  XHVideoRecorder.m
//  视频录制播放
//
//  Created by 向洪 on 2018/4/1.
//  Copyright © 2018年 向洪. All rights reserved.
//

#import "XHVideoRecorder.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>

@interface XHVideoRecorder () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, AVAssetWriteManagerDelegate>

@property (nonatomic, strong) dispatch_queue_t videoQueue;

@property (nonatomic, strong) AVCaptureSession *session;

@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioOutput;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewlayer;

@property (nonatomic, strong) AVAssetWriteManager *writeManager;
@property (nonatomic, assign) XHVideoRecordOutputSizeType type;

/// 监听拍摄方向
@property (nonatomic, strong) CMMotionManager *montionManager;
/// 是否需要更新当前拍摄方向
@property (nonatomic, assign) BOOL shouldUpdateOrientation;
/// 记录拍摄的方向
@property (nonatomic, assign) AVCaptureVideoOrientation currentOrientation;

@property (nonatomic, strong) NSURL *videoUrl;


@end


@implementation XHVideoRecorder

- (instancetype)initWithVideoRecordViewType:(XHVideoRecordOutputSizeType)type maxRecordTime:(NSInteger)maxRecordTime {
    self = [super init];
    if (self) {
        _type = type;
        _maxRecordTime = maxRecordTime;
        [self initialize];
    }
    return self;
}

- (instancetype)init {
    
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    
    // 1.初始化捕捉会话，数据的采集都在会话中处理
    [self setUpInit];
    // 2.设置视频的输入输出
    [self setUpVideo];
    // 3.设置音频的输入输出
    [self setUpAudio];
    // 4.初始化writer， 用writer 把数据写入文件
    [self setUpWriter];
    // 监听当前屏幕方向
    [self setUpMontionManager];
    // 6.开始采集画面
    [self.session startRunning];
    [self startUpdateCurrentOrientation];
}

- (void)setUpInit {
    
    // 添加通知，处理后台问题
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBack) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(becomeActive) name:UIApplicationWillEnterForegroundNotification object:nil];
//    [self clearFile];
    _recordState = XHRecordStateInit;
}

- (void)setUpVideo {
    
    // 2.1 获取视频输入设备(摄像头)
    AVCaptureDevice *videoCaptureDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];//取得后置摄像头
    
    // 2.2 创建视频输入源
    NSError *error = nil;
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:videoCaptureDevice error:&error];
    
    // 2.3 将视频输入源添加到会话
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    
    self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    self.videoOutput.alwaysDiscardsLateVideoFrames = YES; //立即丢弃旧帧，节省内存，默认YES
    [self.videoOutput setSampleBufferDelegate:self queue:self.videoQueue];
    if ([self.session canAddOutput:self.videoOutput]) {
        [self.session addOutput:self.videoOutput];
    }
    
    self.currentOrientation = AVCaptureVideoOrientationLandscapeRight;
}

- (void)setUpAudio {
    
    // 2.2 获取音频输入设备
    AVCaptureDevice *audioCaptureDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    NSError *error = nil;
    // 2.4 创建音频输入源
    self.audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioCaptureDevice error:&error];
    // 2.6 将音频输入源添加到会话
    if ([self.session canAddInput:self.audioInput]) {
        [self.session addInput:self.audioInput];
    }
    
    self.audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [self.audioOutput setSampleBufferDelegate:self queue:self.videoQueue];
    if([self.session canAddOutput:self.audioOutput]) {
        [self.session addOutput:self.audioOutput];
    }
    
}

- (void)setUpWriter {
    
    self.videoUrl = [[NSURL alloc] initFileURLWithPath:[self createVideoFilePath]];
    self.writeManager = [[AVAssetWriteManager alloc] initWithURL:self.videoUrl viewType:self.type maxRecordTime:_maxRecordTime];
    self.writeManager.delegate = self;
    
}

- (void)setUpMontionManager {
    self.montionManager = [[CMMotionManager alloc] init];
    self.shouldUpdateOrientation = YES;
}

#pragma mark - 录制方向
- (void)startUpdateCurrentOrientation {
    
    if([self.montionManager isDeviceMotionAvailable]) {
        [self.montionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMAccelerometerData * _Nullable accelerometerData, NSError * _Nullable error) {
            //            NSLog(@"x : %f  y : %f  z: %f",accelerometerData.acceleration.x,accelerometerData.acceleration.y,accelerometerData.acceleration.z);
            if (self.shouldUpdateOrientation) {
                if (accelerometerData.acceleration.x < 0.75 && accelerometerData.acceleration.x > -0.75) {
                    if (accelerometerData.acceleration.y < 0) {
                        if (self.currentOrientation != AVCaptureVideoOrientationLandscapeRight) {
                            self.currentOrientation = AVCaptureVideoOrientationLandscapeRight;
                            NSLog(@"AVCaptureVideoOrientationLandscapeRight");
                        }
                    }else if (accelerometerData.acceleration.y >= 0.75){
                        if (self.currentOrientation != AVCaptureVideoOrientationLandscapeLeft) {
                            self.currentOrientation = AVCaptureVideoOrientationLandscapeLeft;
                            NSLog(@"AVCaptureVideoOrientationLandscapeLeft");
                        }
                    }
                }else if (accelerometerData.acceleration.y < 0.75 && accelerometerData.acceleration.y > -0.75) {
                    if (accelerometerData.acceleration.x > 0.75) {
                        if (self.currentOrientation != AVCaptureVideoOrientationPortrait) {
                            self.currentOrientation = AVCaptureVideoOrientationPortrait;
                            NSLog(@"AVCaptureVideoOrientationPortrait");
                        }
                    }else if(accelerometerData.acceleration.x < -0.75){
                        if (self.currentOrientation != AVCaptureVideoOrientationPortraitUpsideDown) {
                            self.currentOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
                            NSLog(@"AVCaptureVideoOrientationPortraitUpsideDown");
                        }
                    }
                }else {
                    return;
                }
            }
        }];
    }
}

- (void)endUpdateCurrentOrientation {
    // 结束监听设备方向
    [self.montionManager stopAccelerometerUpdates];
}

#pragma mark - 文件路径

/// 存放视频的文件夹
- (NSString *)videoFolder {
    return NSTemporaryDirectory();
}


/// 写入的视频路径
- (NSString *)createVideoFilePath {
    NSString *videoName = [NSString stringWithFormat:@"%@.mp4", [NSUUID UUID].UUIDString];
    NSString *path = [[self videoFolder] stringByAppendingPathComponent:videoName];
    return path;
    
}

#pragma mark - 获取摄像头

- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition)position{
    
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position] == position) {
            return camera;
        }
    }
    return nil;
}

#pragma mark - public Methods

/// 切换摄像头
- (void)turnCamera {
    [self.session stopRunning];
    AVCaptureDevicePosition position = self.videoInput.device.position;
    if (position == AVCaptureDevicePositionBack) {
        position = AVCaptureDevicePositionFront;
    
//        CABasicAnimation *animtion = [CABasicAnimation animationWithKeyPath:@"transform.rotation.y"];
//        animtion.fromValue = @0;
//        animtion.toValue = @-M_PI;
//        animtion.duration = 1;
//        animtion.fillMode = kCAFillModeForwards;
//        [_previewlayer addAnimation:animtion forKey:nil];
        
    } else {
        position = AVCaptureDevicePositionBack;
        
//        CABasicAnimation *animtion = [CABasicAnimation animationWithKeyPath:@"transform.rotation.y"];
//        animtion.fromValue = @M_PI;
//        animtion.toValue = @0;
//        animtion.duration = 1;
//        animtion.fillMode = kCAFillModeForwards;
//        animtion.removedOnCompletion = NO;
//        [_previewlayer addAnimation:animtion forKey:nil];
    }
    AVCaptureDevice *device = [self getCameraDeviceWithPosition:position];
    AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    
    [self.session beginConfiguration];
    [self.session removeInput:self.videoInput];
    [self.session addInput:newInput];
    [self.session commitConfiguration];
    
    self.videoInput = newInput;
    
    [self.session startRunning];
    
}


- (void)switchflash {
    
    if ([self.videoInput.device hasTorch]) {
    
        if (self.videoInput.device.torchMode == AVCaptureTorchModeOff) {
            [self.videoInput.device lockForConfiguration:nil];
            [self.videoInput.device setTorchMode:AVCaptureTorchModeOn];
            [self.videoInput.device unlockForConfiguration];
        } else if (self.videoInput.device.torchMode == AVCaptureTorchModeOn) {
            [self.videoInput.device lockForConfiguration:nil];
            [self.videoInput.device setTorchMode:AVCaptureTorchModeAuto];
            [self.videoInput.device unlockForConfiguration];
        }  else if (self.videoInput.device.torchMode == AVCaptureTorchModeAuto) {
            [self.videoInput.device lockForConfiguration:nil];
            [self.videoInput.device setTorchMode:AVCaptureTorchModeOff];
            [self.videoInput.device unlockForConfiguration];
        }

        if (self.delegate && [self.delegate respondsToSelector:@selector(videoRecorder:updateFlashState:)]) {
            [self.delegate videoRecorder:self updateFlashState:self.videoInput.device.torchMode];
        }
    }
    
}


- (void)startRecord {
    if (self.recordState == XHRecordStateInit) {
        [self endUpdateCurrentOrientation];
        [self.writeManager startWrite];
        self.recordState = XHRecordStateRecording;
    }
}

- (void)stopRecord {
    [self.writeManager stopWrite];
    [self startUpdateCurrentOrientation];
}

- (void)reset {
    
    self.recordState = XHRecordStateInit;
    [self.session startRunning];
    [self setUpWriter];
    
}

#pragma mark - 权限

+ (AVAuthorizationStatus)audioAuthorizationStatus {

    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    return authStatus;
}


+ (AVAuthorizationStatus)videoAuthorizationStatus {
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    return authStatus;
}

+ (void)requestAccessForAudioAuthorizationAndCompletionHandler:(void (^)(BOOL granted))handler {
    
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:handler];
}

+ (void)requestAccessForVideoAuthorizationAndCompletionHandler:(void (^)(BOOL granted))handler {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:handler];
}

#pragma mark - action Methods (NSNotification)

- (void)enterBack {
    
    if (self.recordState == XHRecordStateRecording) {
        self.videoUrl = nil;
        self.writeManager = nil;
    }
    
    [self.session stopRunning];
    
}

- (void)becomeActive {
    
    if (self.recordState == XHRecordStateRecording) {
        [self reset];
    }
}


#pragma mark - delegate <AVCaptureVideoDataOutputSampleBufferDelegate AVCaptureAudioDataOutputSampleBufferDelegate>

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    @autoreleasepool {
        
        // 视频
        if (connection == [self.videoOutput connectionWithMediaType:AVMediaTypeVideo]) {
            
            if (!self.writeManager.outputVideoFormatDescription) {
                @synchronized(self) {
                    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
                    self.writeManager.outputVideoFormatDescription = formatDescription;
                }
            } else {
                @synchronized(self) {
                    if (self.writeManager.writeState == XHRecordStateRecording) {
                        [self.writeManager appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeVideo];
                    }
                    
                }
            }
        }
        
        // 音频
        if (connection == [self.audioOutput connectionWithMediaType:AVMediaTypeAudio]) {
            if (!self.writeManager.outputAudioFormatDescription) {
                @synchronized(self) {
                    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
                    self.writeManager.outputAudioFormatDescription = formatDescription;
                }
            }
            @synchronized(self) {
                
                if (self.writeManager.writeState == XHRecordStateRecording) {
                    [self.writeManager appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeAudio];
                }
                
            }
            
        }
    }
    
}

#pragma mark - delegate <AVAssetWriteManagerDelegate>

- (void)assetWriteManager:(AVAssetWriteManager *)assetWriteManager updateWritingProgress:(CGFloat)progress {
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoRecorder:updateRecordingProgress:)]) {
        [self.delegate videoRecorder:self updateRecordingProgress:progress];
    }
}

- (void)finishWritingInAssetWriteManager:(AVAssetWriteManager *)assetWriteManager {
    
    [self.session stopRunning];
    self.recordState = XHRecordStateFinish;
}

#pragma mark - Setter Methods

- (void)setRecordState:(XHRecordState)recordState
{
    if (_recordState != recordState) {
        _recordState = recordState;
        if (self.delegate && [self.delegate respondsToSelector:@selector(videoRecorder:updateRecordState:)]) {
            [self.delegate videoRecorder:self updateRecordState:_recordState];
        }
    }
}

- (void)setCurrentOrientation:(AVCaptureVideoOrientation)currentOrientation {
    _currentOrientation = currentOrientation;
    self.writeManager.orientation = currentOrientation;
}

- (void)setMaxRecordTime:(NSTimeInterval)maxRecordTime {
    _maxRecordTime = maxRecordTime;
}

#pragma mark - Getter Methods

- (AVCaptureSession *)session {
    // 录制5秒钟视频 高画质10M,压缩成中画质 0.5M
    // 录制5秒钟视频 中画质0.5M,压缩成中画质 0.5M
    // 录制5秒钟视频 低画质0.1M,压缩成中画质 0.1M
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
        if ([_session canSetSessionPreset:AVCaptureSessionPresetHigh]) {//设置分辨率
            _session.sessionPreset=AVCaptureSessionPresetHigh;
        }
    }
    return _session;
}

- (dispatch_queue_t)videoQueue {
    if (!_videoQueue) {
        _videoQueue = dispatch_queue_create("com.xh.video.recorder", DISPATCH_QUEUE_SERIAL);
    }
    return _videoQueue;
}

- (AVCaptureVideoPreviewLayer *)previewlayer {
    
    if (!_previewlayer) {
        _previewlayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        _previewlayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _previewlayer.contentsScale = [UIScreen mainScreen].scale;
        _previewlayer.frame = self.writeManager.videoRecordViewBounds;
    }
    return _previewlayer;
}

#pragma mark - dealloc Methods

- (void)destroy {
    [self.session stopRunning];
    self.session = nil;
    self.videoQueue = nil;
    self.videoOutput = nil;
    self.videoInput = nil;
    self.audioOutput = nil;
    self.audioInput = nil;
    [self.writeManager destroyWrite];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc {
    [self destroy];
}

@end
