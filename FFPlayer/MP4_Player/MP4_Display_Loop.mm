//
//  MP4_Display_Loop.m
//
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import "MP4_Display_Loop.h"
#import "MP4_Decode_Frame_Queue.h"
#import "MP4_Pro_Def.h"
#import "AudioPlayer.h"
#include "MP4_Player_View_Controller_Context.h"

#define LOGURU_IMPLEMENTATION 1
#include "loguru.hpp"

@interface MP4_Display_Loop ()

@property (nonatomic, strong) dispatch_source_t display_timer;
@property (nonatomic, strong) MP4_Decode_Frame_Queue *video_decode_queue;
@property (nonatomic, strong) MP4_Decode_Frame_Queue *audio_decode_queue;
@property (nonatomic, weak) AudioPlayer *audio_player;
@property (nonatomic) BOOL is_exist_video_track, is_exist_audio_track, is_pause, is_sound, play_call_back_done;
@property (nonatomic) double mp4_duration, play_duration;
@property (nonatomic, strong) UIImage *video_frame;
@property (nonatomic, copy) NSString *mp4_file_path;
@property (nonatomic, copy) NSDictionary *current_audio_dict;
@property (nonatomic) BOOL is_start_play_loop;

@end

@implementation MP4_Display_Loop

__weak MP4_Display_Loop *ws = nil;

Byte *tem_buf = nil;

- (instancetype)init_with_mp4_file_path: (NSString *)mp4_file_path
                   is_exist_video_track: (BOOL)is_exist_video_track
                   is_exist_audio_track: (BOOL)is_exist_audio_track
                               is_pause: (BOOL)is_pause
                               is_sound: (BOOL)is_sound
                           mp4_duration: (double)mp4_duration
                          play_duration: (double)play_duration
{
    self = [super init];
    if (self) {
        tem_buf = (Byte *)malloc(44100*4*2);
        ws = self;
        _mp4_file_path = [mp4_file_path copy];
        _video_decode_queue = [[MP4_Decode_Frame_Queue alloc]init];
        _audio_decode_queue = [[MP4_Decode_Frame_Queue alloc]init];
        _is_exist_video_track = is_exist_video_track;
        _is_exist_audio_track = is_exist_audio_track;
        _is_pause = is_pause;
        _is_sound = is_sound;
        _mp4_duration = mp4_duration;
        _play_duration = play_duration;
        _audio_player = nil;
        _video_frame = nil;
        _play_call_back_done = NO;
        _current_audio_dict = nil;
        _is_start_play_loop = NO;
    }
    return self;
}

- (void)add_observer
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(did_decode_video_first:) name:KMP4_Display_Loop_First_Decode_Video_Notice object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(did_decode_audio_first:) name:KMP4_Display_Loop_First_Decode_Audio_Notice object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(decode_video_frame:) name:KMP4_Display_Loop_Video_Frame_For_Queue_Notice object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(decode_audio_frame:) name:KMP4_Display_Loop_Audio_Frame_For_Queue_Notice object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clear_av_queue:) name:KMP4_Display_Loop_Clear_Audio_Video_Queue_Notice object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(decode_end:) name:KMP4_Display_Loop_Decode_End_Notice object:nil];
}

- (void)decode_end: (NSNotification *)noti
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
    });
}

- (void)did_decode_video_first: (NSNotification *)noti
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (noti.object) {
            @synchronized (self) {
                _play_duration = [noti.object doubleValue];
            }
        }
    });
}

- (void)did_decode_audio_first: (NSNotification *)noti
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (noti.object) {
            @synchronized (self) {
                _play_duration = [noti.object doubleValue];
            }
        }
    });
}

- (void)decode_video_frame: (NSNotification *)noti
{
    NSDictionary *dict = [noti.object copy];
    if (dict) {
        @synchronized (self) {
            [_video_decode_queue.decode_frame_queue addObject:dict];
        }
    }
}

- (void)decode_audio_frame: (NSNotification *)noti
{
    NSDictionary *dict = [noti.object copy];
    if (dict) {
        @synchronized (self) {
            [_audio_decode_queue.decode_frame_queue addObject:dict];
        }
    }
}

- (void)clear_av_queue: (NSNotification *)noti
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @synchronized (self) {
            [_video_decode_queue.decode_frame_queue removeAllObjects];
            [_audio_decode_queue.decode_frame_queue removeAllObjects];
        }
    });
}

OSStatus play_call_back(void *inRefCon,
                          AudioUnitRenderActionFlags *ioActionFlags,
                          const AudioTimeStamp *inTimeStamp,
                          UInt32 inBusNumber,
                          UInt32 inNumberFrames,
                          AudioBufferList *ioData)
{
    @autoreleasepool {
        for (int iBuffer=0; iBuffer < ioData->mNumberBuffers; ++iBuffer) {
            memset(ioData->mBuffers[iBuffer].mData, 0, ioData->mBuffers[iBuffer].mDataByteSize);
        }
        BOOL is_pause = NO, play_call_back_done = NO;
        @synchronized (ws) {
            is_pause = ws.is_pause;
            play_call_back_done = ws.play_call_back_done;
        }
        if (!is_pause && play_call_back_done) {
            int io_len = inNumberFrames*2;
            uint32_t position = 0;
            while (io_len && !is_pause && play_call_back_done) {
                @autoreleasepool {
                    __strong NSDictionary *audio_sample_frame = nil;
                    if (ws.current_audio_dict) {
                        audio_sample_frame = ws.current_audio_dict;
                        ws.current_audio_dict = nil;
                    } else {
                        @synchronized (ws) {
                            if (ws.audio_decode_queue.decode_frame_queue.count == 0) {
                                return NO;
                            }
                            audio_sample_frame = [ws.audio_decode_queue.decode_frame_queue[0] copy];
                            [ws.audio_decode_queue.decode_frame_queue removeObjectAtIndex:0];
                        }
                    }
                    __strong id audio_frame = nil;
                    double audio_frame_time = 0.0;
                    double audio_frame_duration = 0.0;
                    audio_frame = audio_sample_frame[KAudio_Decoder_Frame_Data];
                    audio_frame_time = ((NSNumber*)audio_sample_frame[KAudio_Decoder_Frame_Time]).doubleValue;
                    audio_frame_duration = ((NSNumber*)audio_sample_frame[KAudio_Decoder_Frame_Duration]).doubleValue;
                    if ([audio_frame length] > io_len) {
                        memcpy(tem_buf+position, [audio_frame bytes], io_len);
                        NSRange range = {static_cast<NSUInteger>(io_len), [audio_frame length]-io_len};
                        __strong id audio_frame_ = [audio_frame subdataWithRange:range];
                        __strong NSDictionary *dict = @{KAudio_Decoder_Frame_Data: audio_frame_, KAudio_Decoder_Frame_Time: @(audio_frame_time), KAudio_Decoder_Frame_Duration: @(audio_frame_duration)};
                        ws.current_audio_dict = dict;
                        io_len = 0;
                    }
                    else if ([audio_frame length] <= io_len) {
                        memcpy(tem_buf+position, [audio_frame bytes], [audio_frame length]);
                        io_len -= [audio_frame length];
                        position += [audio_frame length];
                    }
                }
            }
            
            BOOL is_sound = NO;
            @synchronized (ws) {
                is_sound = ws.is_sound;
            }
            if (is_sound && !is_pause) {
                memcpy(ioData->mBuffers[0].mData, tem_buf, inNumberFrames*2);
            }
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                BOOL is_exist_video_track = NO;
                @synchronized (ws) {
                    is_exist_video_track = ws.is_exist_video_track;
                }
                if (!is_exist_video_track) {
                    [ws post_display_audio:inNumberFrames*2];
                }
            });
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [ws post_slider_refresh_notification];
            });
        }
    }
    return noErr;
}

- (void)post_display_audio: (uint32_t)buf_size
{
    NSDictionary *dict = @{@"mp4_file_path":[_mp4_file_path copy], @"audio_frame":[[NSData dataWithBytes:tem_buf length:buf_size] copy]};
    [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Player_View_Controller_Display_Audio_Notice object:[dict copy]];
}

- (void)display
{
    [self add_observer];
    __weak MP4_Display_Loop *mdl = self;
    BOOL is_exist_audio_track = NO, is_exist_video_track = NO;
    @synchronized (self) {
        is_exist_audio_track = _is_exist_audio_track;
        is_exist_video_track = _is_exist_video_track;
    }
    if (is_exist_audio_track) {
        _audio_player = [AudioPlayer share_with_play_call_back:nullptr];
        _audio_player.ac = play_call_back;
        [_audio_player play];
    }
    _display_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
    dispatch_source_set_timer(_display_timer, DISPATCH_TIME_NOW, 0.005 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(_display_timer, ^{
        BOOL is_pause = NO;
        @synchronized (mdl) {
            is_pause = mdl.is_pause;
        }
        if (!is_pause) {
            if (is_exist_video_track && is_exist_audio_track) {
                if ([mdl next_audio_frame_display_time:NULL]==0 || [mdl next_video_frame_display_time:NULL]==0) {
                    mdl.play_duration += 0.005;
                    dispatch_async(dispatch_get_global_queue(0, 0), ^{
                        [mdl display_video:mdl.play_duration];
                    });
                    dispatch_async(dispatch_get_global_queue(0, 0), ^{
                        [mdl display_audio:mdl.play_duration];
                    });
                }
            } else if (is_exist_video_track) {
                if ([mdl next_video_frame_display_time:NULL] == 0) {
                    mdl.play_duration += 0.005;
                    dispatch_async(dispatch_get_global_queue(0, 0), ^{
                        [mdl display_video:mdl.play_duration];
                    });
                }
            } else if (is_exist_audio_track) {
                if ([mdl next_audio_frame_display_time:NULL] == 0) {
                    mdl.play_duration += 0.005;
                    dispatch_async(dispatch_get_global_queue(0, 0), ^{
                        [mdl display_audio:mdl.play_duration];
                    });
                }
            }
        }
    });
    dispatch_resume(_display_timer);
    @synchronized (self) {
        _is_start_play_loop = YES;
    }
}

- (void)display_audio: (double)pp
{
    BOOL is_exist_audio_track = NO, is_exist_video_track = NO;
    @synchronized (self) {
        is_exist_audio_track = _is_exist_audio_track;
        is_exist_video_track = _is_exist_video_track;
        if (!is_exist_video_track && is_exist_audio_track) {
            _play_call_back_done = YES;
            return;
        }
    }
    double ft = 0.0;
    if ([self next_audio_frame_display_time:&ft] == 0) {
        if (pp >= ft) {
            @synchronized (self) {
                _play_call_back_done = YES;
            }
            return;
        }
        @synchronized (self) {
            _play_call_back_done = NO;
        }
    }
}

- (void)display_video: (double)pp
{
    double ft = 0.0;
    if ([self next_video_frame_display_time:&ft] == 0) {
        if (pp >= ft) {
            [self show_next_video_frame];
        }
    }
}

- (int)next_video_frame_display_time: (double *)ft
{
    NSDictionary *video_sample_frame = nil;
    @synchronized (self) {
        if (_video_decode_queue.decode_frame_queue.count == 0) {
            return -1;
        }
        if (ft) {
            video_sample_frame = [_video_decode_queue.decode_frame_queue[0] copy];
        } else {
            
        }
    }
    if (ft) {
        *ft = ((NSNumber*)video_sample_frame[KVideo_Decoder_Frame_Time]).doubleValue;
    } else {
        unsigned int audio_queue_count;
        @synchronized (self) {
            audio_queue_count = (unsigned int)_video_decode_queue.decode_frame_queue.count;
        }
        [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Player_View_Controller_Video_Queue_Count_Notice object:@(audio_queue_count)];
    }
    return 0;
}

- (int)next_audio_frame_display_time: (double *)ft
{
    NSDictionary *audio_sample_frame = nil;
    @synchronized (self) {
        if (_audio_decode_queue.decode_frame_queue.count == 0) {
            return -1;
        }
        if (ft) {
            audio_sample_frame = [_audio_decode_queue.decode_frame_queue[0] copy];
        }
    }
    if (ft) {
        *ft = ((NSNumber*)audio_sample_frame[KAudio_Decoder_Frame_Time]).doubleValue;
    } else {
        unsigned int audio_queue_count;
        @synchronized (self) {
            audio_queue_count = (unsigned int)_audio_decode_queue.decode_frame_queue.count;
        }
        [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Player_View_Controller_Audio_Queue_Count_Notice object:@(audio_queue_count)];
    }
    return 0;
}

- (int)show_next_video_frame
{
    NSDictionary *video_sample_frame = nil;
    @synchronized (self) {
        if (_audio_decode_queue.decode_frame_queue.count == 0) {
            return -1;
        }
    }
    @synchronized (self) {
        video_sample_frame = [(NSDictionary*)_video_decode_queue.decode_frame_queue[0] copy];
        [_video_decode_queue.decode_frame_queue removeObjectAtIndex:0];
    }
    id video_frame = nil;
    double video_frame_time = 0.0;
    video_frame = video_sample_frame[KVideo_Decoder_Frame_Data];
    video_frame_time = ((NSNumber*)video_sample_frame[KVideo_Decoder_Frame_Time]).doubleValue;
    _video_frame = video_frame;
    [self post_nomal_display_notification];
    [self post_slider_refresh_notification];
    return 0;
}

- (void)post_slider_refresh_notification
{
    double play_duration = 0.0;
    @synchronized (self) {
        play_duration = _play_duration;
    }
    NSNumber *play_duration_number = [NSNumber numberWithDouble:play_duration];
    NSDictionary *dict = @{@"mp4_file_path":[_mp4_file_path copy], @"play_duration":play_duration_number};
    [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Player_View_Controller_Progress_Refresh_Notice object:[dict copy]];
}
- (void)post_nomal_display_notification
{
    NSDictionary *dict = @{@"mp4_file_path":[_mp4_file_path copy], @"video_frame_nomal":_video_frame};
    [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Player_View_Controller_Nomal_Display_Notice object:[dict copy]];
}

- (void)sound_enable
{
    @synchronized (self) {
        _is_sound = YES;
    }
}

- (void)sound_disable
{
    @synchronized (self) {
        _is_sound = NO;
    }
}

- (void)pause_display
{
    BOOL is_start_play_loop = NO;
    @synchronized (self) {
        is_start_play_loop = _is_start_play_loop;
    }
    if (is_start_play_loop) {
        if (_is_exist_audio_track) {
            [_audio_player pause];
        }
        @synchronized (self) {
            _is_pause = YES;
        }
    }
}

- (void)resum_display
{
    BOOL is_start_play_loop = NO;
    @synchronized (self) {
        is_start_play_loop = _is_start_play_loop;
    }
    if (is_start_play_loop) {
        if (_is_exist_audio_track) {
            [_audio_player play];
        }
        @synchronized (self) {
            _is_pause = NO;
        }
    }
}

- (void)cancel_display
{
    BOOL is_start_play_loop = NO;
    @synchronized (self) {
        is_start_play_loop = _is_start_play_loop;
    }
    if (is_start_play_loop) {
        @synchronized (self) {
            _audio_player.ac = nullptr;
        }
        if (_is_exist_audio_track) {
            [_audio_player stop];
        }
        if (!_display_timer) {
            return;
        }
        dispatch_source_cancel(_display_timer);
        _display_timer = nil;
        @synchronized (self) {
            _is_start_play_loop = NO;
        }
        [[NSNotificationCenter defaultCenter]removeObserver:self];
    }
}

- (void)dealloc
{
    free(tem_buf);
    tem_buf = nil;
}

@end
