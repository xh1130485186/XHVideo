//
//  XHAssetExportSession.h
//  XHKitDemo
//
//  Created by 向洪 on 2017/6/21.
//  Copyright © 2017年 向洪. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


/// 文件转换，常用于视频文件压缩
/// 对AVAssetExportSession进行简单的封装，
@interface XHAssetExportSession : NSObject

/// 出口类，除非有特殊需要不建议再去设置
@property (nonatomic, strong, readonly) AVAssetExportSession *exportSession;

/// 初始化
+ (instancetype)exportSessionWithURL:(NSURL *)url;
/// 初始化
+ (instancetype)exportSessionWithAsset:(AVURLAsset *)asset;
/// 进行文件压缩，会对压缩结果进行缓存，如果有缓存，直接返回路径地址
- (void)exportWithCompletionHandler:(void(^)(BOOL success, NSURL *url))handler;

@end
