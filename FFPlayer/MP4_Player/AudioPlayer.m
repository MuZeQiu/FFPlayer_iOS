//
//  AudioPlayer.m
//
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import "AudioPlayer.h"

@interface AudioPlayer ()

@property (nonatomic) AudioUnit audioUnit;

@property (nonatomic) BOOL is_play;

@end

@implementation AudioPlayer

static AudioPlayer *ap = nil;

+ (instancetype)share_with_play_call_back: (AURenderCallback)ac
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ap = [[AudioPlayer alloc]init_with_play_call_back:ac];
    });
    return ap;
}

- (instancetype)init_with_play_call_back: (AURenderCallback)ac
{
    self = [super init];
    if (self) {
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setPreferredIOBufferDuration:0.005 error:nil];
        [[AVAudioSession sharedInstance] setPreferredOutputNumberOfChannels:1 error:nil];
        [[AVAudioSession sharedInstance] setPreferredSampleRate:44100 error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(audio_interruption:) name: AVAudioSessionInterruptionNotification object:[AVAudioSession sharedInstance]];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(audio_route_change:) name: AVAudioSessionRouteChangeNotification object:[AVAudioSession sharedInstance]];
        
        _ac = ac;
        
        _is_play = NO;
        
        [self set_audio_unit];
    }
    return self;
}

- (void)set_audio_unit
{
    AudioComponentDescription outputDescription = {0};
    outputDescription.componentType = kAudioUnitType_Output;
    outputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    outputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    outputDescription.componentFlags = 0;
    outputDescription.componentFlagsMask = 0;
    AudioComponent comp = AudioComponentFindNext(NULL, &outputDescription);
    AudioComponentInstanceNew(comp, &_audioUnit);
    
    UInt32 flag = 1;
    
    AudioUnitSetProperty(_audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 0, &flag, sizeof(flag));
    
    AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate
    = 44100;
    audioFormat.mFormatID
    = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags
    = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioFormat.mFramesPerPacket
    = 1;
    audioFormat.mChannelsPerFrame
    = 1;
    audioFormat.mBitsPerChannel
    = 16;
    audioFormat.mBytesPerPacket
    = 2;
    audioFormat.mBytesPerFrame
    = 2;
    
    AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &audioFormat, sizeof(AudioStreamBasicDescription));
    
    AURenderCallbackStruct f;
    f.inputProc = playbackCallback;
    f.inputProcRefCon = (__bridge void * _Nullable)(self);
    AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &f, sizeof(f));
    
    AudioUnitInitialize(_audioUnit);
}

- (void)play
{
    if (!_is_play) {
        _is_play = YES;
        AudioOutputUnitStart(_audioUnit);
    }
}

- (void)pause
{
    if (_is_play) {
        _is_play = NO;
        AudioOutputUnitStop(_audioUnit);
    }
}

- (void)stop
{
    if (_is_play) {
        _is_play = NO;
        AudioOutputUnitStop(_audioUnit);
        AudioUnitUninitialize(_audioUnit);
        _audioUnit = NULL;
    }
    usleep(10000);
    [self set_audio_unit];
}

OSStatus playbackCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData)
{
    @autoreleasepool {
        AudioPlayer *ap = (__bridge AudioPlayer *)inRefCon;
        if (ap.ac) {
            ap.ac(inRefCon, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData);
        }
        return noErr;
    }
}


- (void)audio_interruption: (NSNotification *)noti
{
    NSDictionary *user_info = noti.userInfo;
    id value = user_info[AVAudioSessionInterruptionTypeKey];
    if (AVAudioSessionInterruptionTypeBegan == [value integerValue]) {
 
    } else if (AVAudioSessionInterruptionTypeEnded == [value integerValue]) {
        value = user_info[AVAudioSessionInterruptionTypeKey];
        if ([value integerValue] == AVAudioSessionInterruptionOptionShouldResume) {
 
        }
    }
}

- (void)audio_route_change: (NSNotification *)noti
{
    NSDictionary *user_info = noti.userInfo;
    id value = user_info[AVAudioSessionRouteChangeReasonKey];
    switch ([value integerValue]) {
        case  AVAudioSessionRouteChangeReasonNewDeviceAvailable:{
            NSArray *outputs = [AVAudioSession sharedInstance].currentRoute.outputs;
            AVAudioSessionPortDescription *des;
            for (des in outputs) {
 
            }
        }
 
        case  AVAudioSessionRouteChangeReasonOldDeviceUnavailable: {
            NSArray *outputs = [AVAudioSession sharedInstance].currentRoute.outputs;
            AVAudioSessionPortDescription *des;
            for (des in outputs) {
 
            }
        };
        default:{
 
        };
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}


@end
