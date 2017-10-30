//
//  AudioDownloader.h
//  mDoctor
//
//  Created by fengweiru on 2017/10/13.
//  Copyright © 2017年 zcj. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioDownloader : NSObject<NSURLSessionDelegate>

- (void)downloadFileWith:(NSString *)url completeBlock:(void (^)(NSString *filePath))completeBlock;

@end
