//
//  AudioPlayerModel.h
//  mDoctor
//
//  Created by fengweiru on 2017/10/13.
//  Copyright © 2017年 zcj. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioPlayerModel : NSObject

@property (nonatomic, assign) NSUInteger strType;     //字符串类型：0本地地址 1网络地址
@property (nonatomic, strong) NSString *audioStr;
@property (nonatomic, assign) NSInteger index;        //音频位置

@property (nonatomic, assign) NSUInteger audioTime;        //音频时间

@end
