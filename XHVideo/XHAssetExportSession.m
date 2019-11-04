//
//  XHAssetExportSession.m
//  XHKitDemo
//
//  Created by 向洪 on 2017/6/21.
//  Copyright © 2017年 向洪. All rights reserved.
//

#import "XHAssetExportSession.h"
#import <CommonCrypto/CommonDigest.h>

@interface XHAssetExportSession ()

@property (nonatomic, strong) AVAssetExportSession *exportSession;

@property (nonatomic, copy) NSString *outPath;

@end

@implementation XHAssetExportSession


+ (instancetype)exportSessionWithURL:(NSURL *)url {

    return [XHAssetExportSession exportSessionWithAsset:[AVURLAsset assetWithURL:url]];
}

+ (instancetype)exportSessionWithAsset:(AVURLAsset *)asset {
    
    XHAssetExportSession *session = [[XHAssetExportSession alloc] init];
    NSArray *presets = [AVAssetExportSession exportPresetsCompatibleWithAsset:asset];
    if ([presets containsObject:AVAssetExportPreset960x540]) {
        AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPreset960x540];
        exportSession.outputFileType = AVFileTypeMPEG4;
        exportSession.shouldOptimizeForNetworkUse = YES;
        
        NSString *fileName = [XHAssetExportSession md5TransformWithString:asset.URL.lastPathComponent];
        NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", fileName]];
        NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
        exportSession.outputURL = outputURL;
        
        session.exportSession = exportSession;
    }
    return session;
}

- (void)exportWithCompletionHandler:(void (^)(BOOL success, NSURL *url))handler {
    
    AVAssetExportSession *exportSession = _exportSession;
    NSURL *outputURL = exportSession.outputURL;
    
    BOOL isDirectory = NO;
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:outputURL.resourceSpecifier isDirectory:&isDirectory];
    if (!isDirectory && isExist) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(YES, outputURL);
        });
        return;
    }
    
    if (exportSession && [exportSession.supportedFileTypes containsObject:AVFileTypeMPEG4]) {
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                    handler(YES, outputURL);
                } else {
                    handler(NO, nil);
                }
            });
        }];
    } else {
        handler(NO, nil);
    }
}

+ (NSString *)md5TransformWithString:(NSString *)str {

    const char *string = str.UTF8String;
    int length = (int)strlen(string);
    unsigned char bytes[CC_MD5_DIGEST_LENGTH];
    CC_MD5(string, length, bytes);
    
    NSMutableString *mutableString = @"".mutableCopy;
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [mutableString appendFormat:@"%02x", bytes[i]];
    return [NSString stringWithString:mutableString];
    
}

@end
