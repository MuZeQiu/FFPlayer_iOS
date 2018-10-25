//
//  AppDelegate.m
//  FF_Pro
//
//  Created by 邱沐泽 on 2018/1/6.
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    //[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(secondary_audio_hint:) name:AVAudioSessionSilenceSecondaryAudioHintNotification object:[AVAudioSession sharedInstance]];
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)secondary_audio_hint: (NSNotification *)noti
{
    NSDictionary *user_info = noti.userInfo;
    id value = user_info[AVAudioSessionSilenceSecondaryAudioHintTypeKey];
    if (AVAudioSessionSilenceSecondaryAudioHintTypeBegin == [value integerValue]) {
        
    } else if (AVAudioSessionSilenceSecondaryAudioHintTypeEnd == [value integerValue]) {
        
    }
}


@end
