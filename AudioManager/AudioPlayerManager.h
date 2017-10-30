//
//  AudioPlayerManager.h
//  mDoctor
//
//  Created by fengweiru on 2017/10/13.
//  Copyright © 2017年 zcj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioPlayerModel.h"

@protocol AudioPlayerManagerDelegate <NSObject>

@optional
- (void)stopAudio:(AudioPlayerModel *)audioPlayerModel;

- (void)startAudio:(AudioPlayerModel *)audioPlayerModel;

@end

@interface AudioPlayerManager : NSObject

/**
 获取单例对象
 
 @return 返回AudioPlayerManager
 */
+ (AudioPlayerManager *)shareAudioPlayerManagerManager;

/**
 需要放在startPlay后面设置
 */
@property (nonatomic, weak) id<AudioPlayerManagerDelegate> fDelegate;

/**
 设置音频数组

 @param audioArray 音频数组
 */
- (void)setAudioArray:(NSArray *)audioArray;


/**
 当前是否有播放的音频

 @return 是否有播放的音频
 */
- (BOOL)isHavingAudio;

/**
 获取当前播放模型，无则nil

 @return 当前播放模型
 */
- (AudioPlayerModel *)currentAudioPlayerModel;


/**
 开始播放

 @return 返回播放模型，无则nil
 */
- (AudioPlayerModel *)startPlay;


/**
 暂停当前音频
 */
- (void)pause;


/**
 继续播放
 */
- (void)replay;

/**
 初始化音频管理器
 */
- (void)removeAudios;

@end
