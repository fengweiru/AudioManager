//
//  AudioRecorderManager.h
//  mDoctor
//
//  Created by fengweiru on 2017/10/10.
//  Copyright © 2017年 zcj. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AudioRecorderManagerDelegate <NSObject>

- (void)audioRecorderLastTime:(NSUInteger)lastTime;

- (void)audioRecorderFinish:(NSString *)audioPathStr time:(NSUInteger)time;

- (void)audioRecorderCancel;

@end

@interface AudioRecorderManager : NSObject

@property (nonatomic, weak) id<AudioRecorderManagerDelegate> fDelegate;

@property (nonatomic, assign) NSUInteger     maxRecordTime;//最大录音时间

/**
 获取单例对象

 @return 返回AudioRecorderManager
 */
+ (AudioRecorderManager *)shareAudioRecorderManager;


/**
 开始录音
 */
- (void)onStatrRecord;


/**
 完成录音
 */
- (void)completeRecord;

/**
 停止录音
 */
- (void)stopRecord;

/**
 获取缓存路径
 */
- (NSString*)getCacheDirectory;

@end
