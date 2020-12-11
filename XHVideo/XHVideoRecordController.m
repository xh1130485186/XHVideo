//
//  XHVideoRecordController.m
//  视频录制播放
//
//  Created by 向洪 on 2018/4/2.
//  Copyright © 2018年 向洪. All rights reserved.
//

#import "XHVideoRecordController.h"
#import "XHVideoRecorder.h"
#import "XHVideoRecordDefines.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

@interface XHVideoRecordController () <XHVideoRecorderDelegate>

@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *turnCameraButton;
@property (nonatomic, strong) UIButton *flashButton;
@property (nonatomic, strong) UIButton *recordButton;

@property (nonatomic, strong) UIButton *returnButton;
@property (nonatomic, strong) UIButton *saveButton;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@property (nonatomic, assign) CGFloat recordTime;
@property (nonatomic, strong) XHVideoRecorder *videoRecorder;

@property (nonatomic, strong) CAShapeLayer *shapeLayer;

@end

@implementation XHVideoRecordController

- (instancetype)initWithMaxRecordTime:(NSTimeInterval)maxRecordTime {
    self = [super init];
    if (self) {
        _maxRecordTime = maxRecordTime;
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _maxRecordTime = 10*60;
    }
    return self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self setNeedsStatusBarAppearanceUpdate];

    _videoRecorder = [[XHVideoRecorder alloc] initWithVideoRecordViewType:XHVideoRecordOutputSizeFullScreen maxRecordTime:_maxRecordTime];
    _videoRecorder.delegate = self;
    [self.view.layer addSublayer:_videoRecorder.previewlayer];
    
    [self configTopView];
    [self configRecondView];
    [self configSaveView];
    
    // 添加通知，处理后台问题
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBack) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(becomeActive) name:UIApplicationWillEnterForegroundNotification object:nil];
}


- (void)configTopView {
    
    BOOL isPhoneX = NO;
    if (@available(iOS 11.0, *)) {
        isPhoneX = [[UIApplication sharedApplication] delegate].window.safeAreaInsets.bottom > 0.0;
    }
    CGFloat height = isPhoneX?88:44;
    
    _topView = [[UIView alloc] init];
    _topView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    _topView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), height);
    
    _timeLabel = [[UILabel alloc] init];
    _timeLabel.font = [UIFont systemFontOfSize:13];
    _timeLabel.textColor = [UIColor whiteColor];
    _timeLabel.textAlignment = NSTextAlignmentCenter;
    _timeLabel.frame = CGRectMake((CGRectGetWidth(self.view.frame) - 40)/2, height-30, 40, 16);
    [_topView addSubview:_timeLabel];
    
    _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _cancelButton.frame = CGRectMake(15, height-30, 16, 16);
    [_cancelButton setImage:XHVideoImage(@"icon_video_close") forState:UIControlStateNormal];
    [_cancelButton addTarget:self action:@selector(dismissAction) forControlEvents:UIControlEventTouchUpInside];
    [self.topView addSubview:_cancelButton];
    
    _turnCameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _turnCameraButton.frame = CGRectMake(CGRectGetWidth(self.view.frame) - 60 - 28, height-33, 28, 22);
    [_turnCameraButton setImage:XHVideoImage(@"icon_camera_lens") forState:UIControlStateNormal];
    [_turnCameraButton addTarget:self action:@selector(turnCameraAction) forControlEvents:UIControlEventTouchUpInside];
    [self.topView addSubview:_turnCameraButton];
    
    _flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _flashButton.frame = CGRectMake(CGRectGetWidth(self.view.frame) - 22 - 15, height-33, 22, 22);
    [_flashButton setImage:XHVideoImage(@"icon_flash_off") forState:UIControlStateNormal];
    [_flashButton addTarget:self action:@selector(flashAction) forControlEvents:UIControlEventTouchUpInside];
    [self.topView addSubview:_flashButton];
    
    [self.view addSubview:_topView];
}

- (void)configRecondView {
    
    _recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _recordButton.frame = CGRectMake(0, 0, 60, 60);
    _recordButton.center = CGPointMake(CGRectGetWidth(self.view.frame)*0.5, CGRectGetHeight(self.view.frame)-80);
    [_recordButton setImage:XHVideoImage(@"icon_btn_video") forState:UIControlStateNormal];
    [_recordButton setImage:XHVideoImage(@"icon_btn_stop") forState:UIControlStateSelected];
    [_recordButton addTarget:self action:@selector(recordAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_recordButton];
    
}

- (void)configSaveView {
    
    _player = [[AVPlayer alloc] initWithURL:[NSURL fileURLWithPath:@""]];
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    _playerLayer.frame = self.view.bounds;
    _playerLayer.hidden = YES;
    _playerLayer.backgroundColor = [UIColor blackColor].CGColor;
    _playerLayer.repeatCount = CGFLOAT_MAX;
    _playerLayer.repeatDuration = 0;
    _playerLayer.contentsGravity = kCAGravityResize;
    [self.view.layer addSublayer:_playerLayer];
    
    _saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _saveButton.frame = CGRectMake(0, 0, 60, 60);
    _saveButton.layer.cornerRadius = 30;
    _saveButton.hidden = YES;
    _saveButton.clipsToBounds = YES;
    _saveButton.backgroundColor = [UIColor clearColor];
    _saveButton.center = CGPointMake(CGRectGetWidth(self.view.frame)*0.5, CGRectGetHeight(self.view.frame)-80);
    [_saveButton setImage:XHVideoImage(@"icon_btn_sure") forState:UIControlStateNormal];
    [_saveButton addTarget:self action:@selector(saveAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_saveButton];
    
    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    effectView.frame = _saveButton.bounds;
    effectView.layer.cornerRadius = 30;
    effectView.clipsToBounds = YES;
    effectView.userInteractionEnabled = NO;
    [_saveButton insertSubview:effectView belowSubview:_saveButton.imageView];
    
    
    _returnButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _returnButton.frame = CGRectMake(0, 0, 60, 60);
    _returnButton.layer.cornerRadius = 30;
    _returnButton.clipsToBounds = YES;
    _returnButton.hidden = YES;;
    _returnButton.center = CGPointMake(CGRectGetWidth(self.view.frame)*0.5, CGRectGetHeight(self.view.frame)-80);
    [_returnButton setImage:XHVideoImage(@"icon_btn_back") forState:UIControlStateNormal];
    [_returnButton addTarget:self action:@selector(returnAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_returnButton];
    
    UIBlurEffect *returneEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *returneEffectView = [[UIVisualEffectView alloc] initWithEffect:returneEffect];
    returneEffectView.frame = _returnButton.bounds;
    returneEffectView.layer.cornerRadius = 30;
    returneEffectView.clipsToBounds = YES;
    returneEffectView.userInteractionEnabled = NO;
    [_returnButton insertSubview:returneEffectView belowSubview:_returnButton.imageView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
    
}

#pragma mark - upateView Methods

- (void)updateViewWithPrepareRecord {
    
    self.timeLabel.hidden = YES;
    self.topView.hidden = NO;
    self.saveButton.hidden = YES;
    self.returnButton.hidden = YES;
    self.playerLayer.hidden = YES;
    self.recordButton.hidden = NO;
    self.videoRecorder.previewlayer.hidden = NO;
    self.recordButton.selected = NO;
    self.shapeLayer.hidden = YES;

    [self.player pause];
}

- (void)updateViewWithRecording {
    
    self.timeLabel.hidden = NO;
    self.turnCameraButton.hidden = YES;
    self.recordButton.selected = YES;
    self.shapeLayer.hidden = NO;
}

- (void)updateViewWithStop {
    
    self.timeLabel.hidden = YES;
    self.turnCameraButton.hidden = NO;
    self.topView.hidden = YES;
    self.recordButton.hidden = YES;
    self.videoRecorder.previewlayer.hidden = YES;
    self.shapeLayer.hidden = YES;
    self.shapeLayer.strokeEnd = 0;
    
    self.saveButton.center = CGPointMake(CGRectGetWidth(self.view.frame)*0.5, CGRectGetHeight(self.view.frame)-80);
    self.returnButton.center = CGPointMake(CGRectGetWidth(self.view.frame)*0.5, CGRectGetHeight(self.view.frame)-80);
    [UIView animateWithDuration:0.3 animations:^{
        self.saveButton.center = CGPointMake(CGRectGetWidth(self.view.frame)-100, CGRectGetHeight(self.view.frame)-80);
        self.returnButton.center = CGPointMake(100, CGRectGetHeight(self.view.frame)-80);
        self.saveButton.hidden = NO;
        self.returnButton.hidden = NO;
    }];
    
    self.playerLayer.hidden = NO;
    
    AVURLAsset *movieAsset = [AVURLAsset URLAssetWithURL:self.videoRecorder.videoUrl options:nil];
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:movieAsset];
    [self.player replaceCurrentItemWithPlayerItem:playerItem];
    [self.player play];
}


#pragma mark - Action Methods

- (void)dismissAction {
    
    if (_delegate && [_delegate conformsToProtocol:@protocol(XHVideoRecordControllerDelegate)] && [_delegate respondsToSelector:@selector(videoRecordControllerDelegateDidCancel:)]) {
        [_delegate videoRecordControllerDelegateDidCancel:self];
    } else {
         [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)turnCameraAction {
    [self.videoRecorder turnCamera];
}

- (void)flashAction {
    
    [self.videoRecorder switchflash];
}

- (void)recordAction {
    
    if (self.videoRecorder.recordState == XHRecordStateInit) {
        [self.videoRecorder startRecord];
    } else if (self.videoRecorder.recordState == XHRecordStateRecording) {
        [self.videoRecorder stopRecord];
    } else {
        [self.videoRecorder reset];
    }
}

- (void)saveAction {
    
    if (_delegate && [_delegate conformsToProtocol:@protocol(XHVideoRecordControllerDelegate)] && [_delegate respondsToSelector:@selector(videoRecordController:recordFinishWithVideoUrl:)]) {
        [_delegate videoRecordController:self recordFinishWithVideoUrl:self.videoRecorder.videoUrl];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)returnAction {
    
//    [self updateViewWithPrepareRecord];
    [self.videoRecorder reset];
}

#pragma mark - NSNotification Methods

- (void)enterBack {
    if (self.videoRecorder.recordState == XHRecordStateFinish) {
        [self.player pause];
    }
}

- (void)becomeActive {
    
    if (self.videoRecorder.recordState == XHRecordStateFinish) {
        [self.player seekToTime:CMTimeMake(0, 1)];
        [self.player play];
    }
}

- (void)playbackFinished:(NSNotification *)noti {
    
    if ([noti.object isEqual:self.player.currentItem]) {
        [self.player seekToTime:CMTimeMake(0, 1)];
        [self.player play];
    }
}

#pragma mark - delegate <XHVideoRecorderDelegate>

- (void)videoRecorder:(XHVideoRecorder *)videoRecorder updateFlashState:(AVCaptureTorchMode)state {
    
    if (state == AVCaptureTorchModeOff) {
        [_flashButton setImage:XHVideoImage(@"icon_flash_off") forState:UIControlStateNormal];
    } else if (state == AVCaptureTorchModeOn) {
        [_flashButton setImage:XHVideoImage(@"icon_flash_on") forState:UIControlStateNormal];
    } else if (state == AVCaptureTorchModeAuto) {
        [_flashButton setImage:XHVideoImage(@"icon_flash_auto") forState:UIControlStateNormal];
    }
}

- (void)videoRecorder:(XHVideoRecorder *)videoRecorder updateRecordingProgress:(CGFloat)progress {
    
    CGFloat videocurrent = progress * _maxRecordTime;
    NSString *time = [NSString stringWithFormat:@"%02li:%02li",lround(floor(videocurrent/60.f)), lround(floor(videocurrent/1.f))%60];
    self.timeLabel.text = time;
    self.shapeLayer.strokeEnd = progress;
    
}

- (void)videoRecorder:(XHVideoRecorder *)videoRecorder updateRecordState:(XHRecordState)recordState {
    
    if (recordState == XHRecordStateInit) {
        [self updateViewWithPrepareRecord];
    } else if (recordState == XHRecordStateRecording) {
        [self updateViewWithRecording];
    } else  if (recordState == XHRecordStateFinish) {
        [self updateViewWithStop];
    }
}

#pragma mark - 进度

- (CAShapeLayer *)shapeLayer {
    if (!_shapeLayer) {
        
        CGFloat width = self.recordButton.frame.size.width-4;
        CGFloat positionX = width/2;
        CGFloat positionY = positionX;
        
        CGFloat radius = MIN(positionX, positionY)-3*0.5;
        
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path addArcWithCenter:CGPointMake(positionX, positionY) radius:radius startAngle:-M_PI_2 endAngle:M_PI_2*3 clockwise:YES];
        
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.bounds = CGRectMake(0, 0, width, width);
        shapeLayer.position = self.recordButton.center;
        shapeLayer.path = path.CGPath;
        shapeLayer.lineJoin = kCALineJoinMiter;
        shapeLayer.lineCap = kCALineCapRound;
        shapeLayer.lineWidth = 3;
        shapeLayer.strokeEnd = 0;
        shapeLayer.fillColor = [UIColor clearColor].CGColor;
        shapeLayer.strokeColor = [UIColor colorWithRed:240/255.f green:0/255.f blue:17/255.f alpha:1].CGColor;
        
        _shapeLayer = shapeLayer;
        
        [self.view.layer addSublayer:shapeLayer];
    }
    return _shapeLayer;
}

#pragma mark - barHidden

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (BOOL)shouldAutorotate {

    return NO;
}

- (void)dealloc {
    
//    // 关闭手机Orientation通知
//    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

@end
