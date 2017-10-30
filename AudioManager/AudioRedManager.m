//
//  AudioRedManager.m
//  mHealth
//
//  Created by fengweiru on 2017/10/19.
//  Copyright © 2017年 medzone. All rights reserved.
//

#import "AudioRedManager.h"
#import "AccountManager.h"

@implementation AudioRedManager

+ (AudioRedManager *)shareAudioRedManager
{
    static AudioRedManager *shareRedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareRedManager = [[AudioRedManager alloc] init];
    });
    return shareRedManager;
}

- (instancetype)init
{
    if (self = [super init]) {
        
        NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
        NSDictionary *audioRedDic = [user objectForKey:@"audio_red"];
        if (!audioRedDic) {
            [user setObject:[[NSDictionary alloc] init] forKey:@"audio_red"];
        }
        
    }
    return self;
}

- (void)setCurrentAccountDic
{
    Account *account = [AccountManager currentAcccount];
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *audioRedDic = [NSMutableDictionary dictionaryWithDictionary:[user objectForKey:@"audio_red"]];
    NSDictionary *currentAccountDic = [audioRedDic objectForKey:[NSString stringWithFormat:@"%zi",account.accountID]];
    if (!currentAccountDic) {
        currentAccountDic = @{@"record_time":[NSDate date],@"filename":[[NSDictionary alloc] init]};
        [audioRedDic setValue:currentAccountDic forKey:[NSString stringWithFormat:@"%zi",account.accountID]];
        [user setObject:audioRedDic forKey:@"audio_red"];
    }
}

- (BOOL)showRedWithFileName:(NSString *)fileName time:(NSDate *)time
{
    Account *account = [AccountManager currentAcccount];
    
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    NSDictionary *audioRedDic = [user objectForKey:@"audio_red"];
    NSDictionary *currentAccountDic = [audioRedDic objectForKey:[NSString stringWithFormat:@"%zi",account.accountID]];
    if (currentAccountDic) {
        NSDate *recordTime = [currentAccountDic objectForKey:@"record_time"];
        NSComparisonResult result = [recordTime compare:time];
        if (result == NSOrderedDescending) {
            return false;
        } else {
            NSDictionary *fileNameDic = [currentAccountDic objectForKey:@"filename"];
            if ([fileNameDic objectForKey:fileName]) {
                return false;
            } else {
                return true;
            }
        }
    } else {
        return false;
    }
}

- (void)setIsReadWithFileName:(NSString *)fileName
{
    Account *account = [AccountManager currentAcccount];
    
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *audioRedDic = [NSMutableDictionary dictionaryWithDictionary:[user objectForKey:@"audio_red"]];
    NSMutableDictionary *currentAccountDic = [NSMutableDictionary dictionaryWithDictionary:[audioRedDic objectForKey:[NSString stringWithFormat:@"%zi",account.accountID]]];
    if (currentAccountDic) {
        NSMutableDictionary *fileNameDic =[NSMutableDictionary dictionaryWithDictionary:[currentAccountDic objectForKey:@"filename"]];
        
        if (![fileNameDic objectForKey:fileName]) {
            [fileNameDic setObject:@"isRead" forKey:fileName];
            [currentAccountDic setObject:fileNameDic forKey:@"filename"];
            [audioRedDic setObject:currentAccountDic forKey:[NSString stringWithFormat:@"%zi",account.accountID]];
            [user setObject:audioRedDic forKey:@"audio_red"];
        }

    }
}

@end
