//
//  AudioRedManager.h
//  mHealth
//
//  Created by fengweiru on 2017/10/19.
//  Copyright © 2017年 medzone. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioRedManager : NSObject

+ (AudioRedManager *)shareAudioRedManager;


/**
 在userDefault里设置当前帐号字典
 */
- (void)setCurrentAccountDic;


/**
 判断是否显示红点

 @param fileName 语音文件名
 @param time 语音发出时间
 @return 是否显示红点
 */
- (BOOL)showRedWithFileName:(NSString *)fileName time:(NSDate *)time;


/**
 设置语音已读

 @param fileName 语音文件名
 */
- (void)setIsReadWithFileName:(NSString *)fileName;

@end
