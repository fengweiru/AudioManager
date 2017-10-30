//
//  AudioPlayerManager.m
//  mDoctor
//
//  Created by fengweiru on 2017/10/13.
//  Copyright © 2017年 zcj. All rights reserved.
//

#import "AudioPlayerManager.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "AudioRecorderManager.h"
#import "AudioDownloader.h"

@interface AudioPlayerManager ()<AVAudioPlayerDelegate>

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

@property (nonatomic, strong) NSArray *audioArray;

@property (nonatomic, assign) NSUInteger playIndex;

@property (nonatomic, strong) AudioPlayerModel *lastAudioPlayerModel;

@end

@implementation AudioPlayerManager

+ (AudioPlayerManager *)shareAudioPlayerManagerManager
{
    static AudioPlayerManager *shareAudioPlayerManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareAudioPlayerManager = [[AudioPlayerManager alloc] init];
    });
    return shareAudioPlayerManager;
}

- (instancetype)init
{
    if (self = [super init]) {
        
    }
    return self;
}

- (void)setAudioArray:(NSArray *)audioArray
{
    self.audioPlayer.delegate = nil;
    self.audioPlayer = nil;
    _audioArray = [audioArray mutableCopy];
    _playIndex = 0;
}

- (BOOL)isHavingAudio
{
    if (_audioArray) {
        return true;
    } else {
        return false;
    }
}

- (AudioPlayerModel *)currentAudioPlayerModel
{
    if (_audioArray && _playIndex < _audioArray.count) {
        AudioPlayerModel *model = _audioArray[_playIndex];
        return model;
    }
    return nil;
}

- (AudioPlayerModel *)startPlay
{
    //初始化播放器的时候如下设置
    UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
                            sizeof(sessionCategory),
                            &sessionCategory);
    
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,
                             sizeof (audioRouteOverride),
                             &audioRouteOverride);
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    //默认情况下扬声器播放
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [audioSession setActive:YES error:nil];
    
    if (self.fDelegate && [self.fDelegate respondsToSelector:@selector(stopAudio:)]  && self.lastAudioPlayerModel) {
        [self.fDelegate stopAudio:self.lastAudioPlayerModel];
    }
    
    self.audioPlayer.delegate = nil;
    self.audioPlayer = nil;
    if (_playIndex < _audioArray.count) {
        AudioPlayerModel *model = _audioArray[_playIndex];
        self.lastAudioPlayerModel = model;
        if (model.strType == 0) {      //本地音频
            self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:model.audioStr] error:nil];
            self.audioPlayer.delegate = self;
            self.audioPlayer.numberOfLoops = 0;
            self.audioPlayer.volume = 1;
            [self.audioPlayer play];
        } else {        //网络音频
            NSString *fileName = [model.audioStr lastPathComponent];
            NSString *filePathStr = [[[AudioRecorderManager shareAudioRecorderManager] getCacheDirectory] stringByAppendingPathComponent:fileName];
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePathStr]) {   //本地存在则播放本地音频
                self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:filePathStr] error:nil];
                self.audioPlayer.delegate = self;
                self.audioPlayer.numberOfLoops = 0;
                self.audioPlayer.volume = 1;
                [self.audioPlayer play];
            } else {
                __weak __typeof__(self) weakSelf = self;
                AudioDownloader *downLoader = [[AudioDownloader alloc] init];
                [downLoader downloadFileWith:model.audioStr completeBlock:^(NSString *filePath) {
                    weakSelf.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:filePath] error:nil];
                    weakSelf.audioPlayer.delegate = self;
                    weakSelf.audioPlayer.numberOfLoops = 0;
                    weakSelf.audioPlayer.volume = 1;
                    [weakSelf.audioPlayer play];
                }];
            }
        }
        return model;
    }
    return nil;
}

- (void)play
{
   AudioPlayerModel *model = [self startPlay];
    if (model) {
        if (self.fDelegate && [self.fDelegate respondsToSelector:@selector(startAudio:)]) {
            [self.fDelegate startAudio:model];
        }
    }
}

- (void)pause
{
    [self.audioPlayer stop];
    self.audioPlayer.currentTime = 0;
}

- (void)replay
{
    [self.audioPlayer play];
}

- (void)removeAudios
{
    if (self.fDelegate && [self.fDelegate respondsToSelector:@selector(stopAudio:)]) {
        [self.fDelegate stopAudio:self.lastAudioPlayerModel];
    }
    _playIndex = 0;
    _audioArray = nil;
    _lastAudioPlayerModel = nil;
    [self.audioPlayer stop];
}

#pragma mark -- AVAudioPlayerDelegate
//音频播放完成
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    AudioPlayerModel *model = _audioArray[_playIndex];
    if (self.fDelegate && [self.fDelegate respondsToSelector:@selector(stopAudio:)]) {
        [self.fDelegate stopAudio:model];
    }
    _playIndex++;
    if (_playIndex >= _audioArray.count) {
        [self removeAudios];
    } else {
        [self play];
    }
}
//音频解码发生错误
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error
{
    
}
//如果音频被中断，比如有电话呼入，该方法就会被回调，该方法可以保存当前播放信息，以便恢复继续播放的进度
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player
{
    [self.audioPlayer pause];
}

@end
