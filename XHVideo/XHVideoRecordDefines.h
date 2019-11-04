//
//  XHVideoRecordDefines.h
//  XHKitDemo
//
//  Created by 向洪 on 2019/11/1.
//  Copyright © 2019 向洪. All rights reserved.
//

#ifndef XHVideoRecordDefines_h
#define XHVideoRecordDefines_h

static inline NSString *XHVideoBundlePathForResource(NSString *name) {
    NSBundle *bundle = [NSBundle bundleForClass:NSClassFromString(@"XHVideoPlayer")];
    NSURL *url = [bundle URLForResource:@"xh.video" withExtension:@"bundle"];
    bundle = [NSBundle bundleWithURL:url];
    name = [UIScreen mainScreen].scale==3?[name stringByAppendingString:@"@3x"]:[name stringByAppendingString:@"@2x"];
    NSString *imagePath = [bundle pathForResource:name ofType:@"png"];
    return imagePath;
}

#define XHVideoImage(name) [UIImage imageWithContentsOfFile:XHVideoBundlePathForResource(name)]


#endif /* XHVideoRecordDefines_h */
