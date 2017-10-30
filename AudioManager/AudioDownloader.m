//
//  AudioDownloader.m
//  mDoctor
//
//  Created by fengweiru on 2017/10/13.
//  Copyright © 2017年 zcj. All rights reserved.
//

#import "AudioDownloader.h"
#import "AudioRecorderManager.h"

@implementation AudioDownloader

- (void)downloadFileWith:(NSString *)url completeBlock:(void (^)(NSString *))completeBlock
{
    NSString *fileName = [url lastPathComponent];
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    // 配置会话的缓存
    NSString *cachePath = @"/MyCacheDirectory";
    
    NSArray *pathList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *path = [pathList objectAtIndex:0];
    
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    
    NSString *fullCachePath = [[path stringByAppendingPathComponent:bundleIdentifier] stringByAppendingPathComponent:cachePath];
    
    NSLog(@"Cache path: %@", fullCachePath);
    
    NSURLCache *cache = [[NSURLCache alloc] initWithMemoryCapacity:16384 diskCapacity:268435456 diskPath:cachePath];
    defaultConfigObject.URLCache = cache;
    defaultConfigObject.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
    
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    [[defaultSession dataTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"Got response %@", response);
        //        NSLog(@"Got data lenght: %d k", data.length/1024);
        

        NSString *documentsDirectory = [[AudioRecorderManager shareAudioRecorderManager] getCacheDirectory];
        NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:fileName];
        
        // Save it into file system
        BOOL success = [data writeToFile:dataPath atomically:YES];
        
        completeBlock(dataPath);
        
    }] resume];

}

@end
