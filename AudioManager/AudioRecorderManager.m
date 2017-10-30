//
//  AudioRecorderManager.m
//  mDoctor
//
//  Created by fengweiru on 2017/10/10.
//  Copyright © 2017年 zcj. All rights reserved.
//

#import "AudioRecorderManager.h"
#import <AVFoundation/AVFoundation.h>
#import "AccountManager.h"
#import "AudioRedManager.h"

@interface AudioRecorderManager ()<AVAudioRecorderDelegate>
{
    NSTimer *_timer; //定时器
    NSInteger _countDown;  //倒计时
    
    BOOL _isDelete;
}

@property (nonatomic, strong) NSString *filePathStr;//文件地址
@property (nonatomic, retain) AVAudioRecorder *audioRecorder;//录音器


@end

@implementation AudioRecorderManager

+ (AudioRecorderManager *)shareAudioRecorderManager
{
    static AudioRecorderManager *shareAudioRecorderManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareAudioRecorderManager = [[self alloc] init];
        shareAudioRecorderManager.maxRecordTime = 60;
        
        if(![self fileExistsAtPath:[shareAudioRecorderManager getCacheDirectory]])
        {
            NSString *path = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"serviceCache"];
            [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
    });
    return shareAudioRecorderManager;
}

/**
 *  在初始化AVAudioRecord实例之前，需要进行基本的录音设置
 *
 *  @return 初始化字典
 */
- (NSDictionary *)audioRecordingSettings{
    
    NSDictionary *settings = [[NSDictionary alloc] initWithObjectsAndKeys:
                              
                              [NSNumber numberWithFloat:8000.0],AVSampleRateKey ,    //采样率 8000/44100/96000
                              
                              [NSNumber numberWithInt:kAudioFormatMPEG4AAC],AVFormatIDKey,  //录音格式
                              
                              [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,   //线性采样位数  8、16、24、32
                              
                              [NSNumber numberWithInt:2],AVNumberOfChannelsKey,      //声道 1，2
                              
                              [NSNumber numberWithInt:AVAudioQualityLow],AVEncoderAudioQualityKey, //录音质量
                              
                              nil];
    return (settings);
}


- (void)onStatrRecord
{
    if (![self canRecord])
    {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:[NSString stringWithFormat:@"应用需要访问您的麦克风。请启用麦克风！"]
                                   delegate:nil
                          cancelButtonTitle:@"同意"
                          otherButtonTitles:nil] show];
        return;
    }
    
    [self initRecordSession];
    
    NSError *error = nil;
    NSString *fileName = [NSString stringWithFormat:@"service-msg-%zi-%@.aac",[AccountManager currentAcccount].accountID,[AudioRecorderManager getCurrentTimeString]];
    NSString *pathOfRecordingFile = [[self getCacheDirectory] stringByAppendingPathComponent:fileName];
    self.filePathStr = [pathOfRecordingFile copy];
    NSURL *audioRecordingUrl = [NSURL fileURLWithPath:pathOfRecordingFile];
    AVAudioRecorder *newRecorder = [[AVAudioRecorder alloc]
                                    initWithURL:audioRecordingUrl
                                    settings:[self audioRecordingSettings]
                                    error:&error];
    self.audioRecorder = newRecorder;
    if (self.audioRecorder != nil) {
        self.audioRecorder.delegate = self;
        if([self.audioRecorder prepareToRecord] == NO){
            return;
        }
        
        if ([self.audioRecorder record] == YES) {
            NSLog(@"录音开始！");
            _isDelete = false;
            [self removeTimer];
            [self addTimer];
        } else {
            NSLog(@"录音失败！");
            self.audioRecorder =nil;
        }
    } else {
        NSLog(@"auioRecorder实例录音器失败！");
    }
}

- (void)completeRecord
{
    _isDelete = false;
    
    if ((self.maxRecordTime - _countDown) == 0) {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:[NSString stringWithFormat:@"说话时间太短"]
                                   delegate:nil
                          cancelButtonTitle:@"确定"
                          otherButtonTitles:nil] show];
        _isDelete = true;
    }
    
    [self stopRecordingOnAudioRecorder:self.audioRecorder];
    if (self.audioRecorder != nil) {
        if ([self.audioRecorder isRecording] == YES) {
            [self.audioRecorder stop];
        }
        self.audioRecorder = nil;
    }
    [self removeTimer];
}

- (void)stopRecord{
    _isDelete = true;
    [self stopRecordingOnAudioRecorder:self.audioRecorder];
    if (self.audioRecorder != nil) {
        if ([self.audioRecorder isRecording] == YES) {
            [self.audioRecorder stop];
        }
        self.audioRecorder = nil;
    }
    [self removeTimer];
}

//当AVAudioRecorder对象录音终止的时候会调用audioRecorderDidFinishRecording:successfully:方法
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    
    //如果flag为真，代表录音正常结束，使用AVAudioPlayer将其播放出来，否则失败
    if (flag == YES) {
        NSLog(@"录音完成！");
//        NSData *data = [NSData dataWithContentsOfFile:self.filePathStr];
//        NSLog(@"%zi",data.length/1024);
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.filePathStr]) {
            if (_isDelete) {
                [[NSFileManager defaultManager] removeItemAtPath:self.filePathStr error:nil];
                if (self.fDelegate && [self.fDelegate respondsToSelector:@selector(audioRecorderCancel)]) {
                    [self.fDelegate performSelector:@selector(audioRecorderCancel) withObject:nil];
                }
            } else {
                if (self.fDelegate && [self.fDelegate respondsToSelector:@selector(audioRecorderFinish:time:)]) {
                    [self.fDelegate audioRecorderFinish:self.filePathStr time:(self.maxRecordTime-_countDown)*1000];
                    [[AudioRedManager shareAudioRedManager] setIsReadWithFileName:[self.filePathStr lastPathComponent]];
                }
            }
        }
    } else {
        NSLog(@"录音过程意外终止！");
    }
    self.audioRecorder = nil;
}

- (void)stopRecordingOnAudioRecorder:(AVAudioRecorder *)recorder{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];  //此处需要恢复设置回放标志，否则会导致其它播放声音也会变小
    [session setActive:YES error:nil];
    [recorder stop];
}

//添加定时器
- (void)addTimer
{
    _countDown = self.maxRecordTime;
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(countDown) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}
//移除定时器
- (void)removeTimer
{
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}
- (void)countDown
{
    _countDown--;
    if (_countDown <= 0) {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:[NSString stringWithFormat:@"说话时间超长"]
                                   delegate:nil
                          cancelButtonTitle:@"确定"
                          otherButtonTitles:nil] show];
        [self completeRecord];
        return;
    }
    if (self.fDelegate && [self.fDelegate respondsToSelector:@selector(audioRecorderLastTime:)]) {
        [self.fDelegate audioRecorderLastTime:_countDown];
    }
}

//获取缓存路径
- (NSString *)getCacheDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [[paths objectAtIndex:0] stringByAppendingPathComponent:@"serviceCache"];
}

//判断文件是否存在
+ (BOOL)fileExistsAtPath:(NSString*)path
{
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}


//生成当前时间字符串+6位随机数
+ (NSString*)getCurrentTimeString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    return [NSString stringWithFormat:@"%@%06d",[dateFormatter stringFromDate:[NSDate date]],arc4random() % 100000];
}

//初始化音频检查
- (void)initRecordSession
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [session setActive:YES error:nil];
    
}

//将要录音,是否系统7.0以上
- (BOOL)canRecord
{
    __block BOOL bCanRecord = YES;
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {//麦克风权限
        if (granted) {
            bCanRecord = true;
        }else{
            bCanRecord = false;
        }
    }];
    return bCanRecord;
}

@end
