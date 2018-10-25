//
//  AudioPlayer.h
//
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <AudioToolbox/AudioToolbox.h>

@interface AudioPlayer : NSObject

+ (instancetype)share_with_play_call_back: (AURenderCallback)ac;

@property (nonatomic, assign) AURenderCallback ac;

- (void)play;

- (void)pause;

- (void)stop;

@end
