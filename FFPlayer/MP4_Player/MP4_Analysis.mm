//
//  MP4_Analysis.m
//
//  Copyright © 2017年 邱沐泽. All rights reserved.
//

#import "MP4_Analysis.h"
#define LOGURU_WITH_STREAMS 1
#include "loguru.hpp"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <mach/mach_time.h>
#import "avcodec.h"
#import "avformat.h"
#import "swscale.h"
#import "MP4_Audio_Decoder2.h"
#import "MP4_Video_Decoder2.h"
#import "MP4_Subtitle_Decoder2.h"
#import "MP4_AV_Decoder.h"
#import "MP4_Pro_Def.h"
#import "MP4_Player_View_Controller.h"
#import "MP4_Player_View_V.h"
#import "MP4_Player_View_H.h"
#import "MP4_Player_View_Controller_Context.h"
#import "YUV_To_JPEG.h"
#import "MP4_Display_Loop.h"

@interface MP4_Analysis ()

@property (nonatomic, weak) MP4_Player_View_Controller_Context *context;
@property (nonatomic, strong)MP4_Player_View_Controller *mpvc;
@property (nonatomic, strong) MP4_AV_Decoder *mavd;
@property (nonatomic, strong) MP4_Display_Loop *mdl;

@end

@implementation MP4_Analysis

static UIWindow* mp4_analysis_global_window = nil;

static MP4_Analysis *mp4_player = nil;

+ (instancetype)share_mp4_player_with_file_path: (NSString *)file_path
{
    if (!file_path) {
        return nil;
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mp4_player = [[MP4_Analysis alloc]init];
    });
    if (mp4_player) {
        
        NSString *log_path = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"My_Log.log"];
        unlink([log_path UTF8String]);
        loguru::add_file([log_path UTF8String], loguru::Append, loguru::Verbosity_MAX);
        
        mp4_player.context = [MP4_Player_View_Controller_Context share_mp4_player_context];
        mp4_player.context.mp4_file_path = file_path;
        mp4_player.mpvc = nil;
        mp4_player.mdl = nil;
        mp4_player.mavd = nil;
    }
    [mp4_player add_noti];
    return mp4_player;
}

+ (id)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        if(mp4_player == nil) {
            mp4_player = [super allocWithZone:zone];
        }
    });
    return mp4_player;
}

- (id)copy
{
    return self;
}

- (id)mutableCopy
{
    return self;
}

+ (UIWindow *)share_mp4_analysis_global_window
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mp4_analysis_global_window = [[UIWindow alloc]init];
        mp4_analysis_global_window.frame = get_screen_size();
        mp4_analysis_global_window.windowLevel = 50;
        mp4_analysis_global_window.hidden = YES;
        mp4_analysis_global_window.backgroundColor = [UIColor whiteColor];
    });
    return mp4_analysis_global_window;
}

- (void)is_exist_mp4_audio
{
    NSString *mp4_file_path;
    @synchronized (self) {
        mp4_file_path = [_context.mp4_file_path copy];
    }
    NSURL *url = [[NSURL alloc]initFileURLWithPath:mp4_file_path];
    AVAsset *asset = [[AVURLAsset alloc]initWithURL:url options:nil];
    AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    @synchronized (self) {
        !track?(_context.is_exist_audio_track=NO):(_context.is_exist_audio_track=YES);
    }
}

- (void)is_exist_mp4_video
{
    NSString *mp4_file_path;
    @synchronized (self) {
        mp4_file_path = [_context.mp4_file_path copy];
    }
    NSURL *url = [NSURL fileURLWithPath:mp4_file_path];
    AVAsset *asset = [AVURLAsset assetWithURL:url];
    AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    @synchronized (self) {
        !track?(_context.is_exist_video_track=NO):(_context.is_exist_video_track=YES);
    }
}

- (void)is_mp3_file
{
    NSString *mp4_file_path;
    @synchronized (self) {
        mp4_file_path = [_context.mp4_file_path copy];
    }
    if ([mp4_file_path hasSuffix:@"mp3"]) {
        @synchronized (self) {
            _context.is_mp3_file = YES;
        }
    } else {
        @synchronized (self) {
            _context.is_mp3_file = NO;
        }
    }
}

- (void)get_mp3_file_property
{
    BOOL is_mp3_file = NO;
    @synchronized (self) {
        is_mp3_file = _context.is_mp3_file;
    }
    
    if (!is_mp3_file) {
        @synchronized (self) {
            _context.mp3_title = nil;
            _context.mp3_artist = nil;
            _context.mp3_album = nil;
            _context.mp3_bit_rate = nil;
        }
        return;
    }
    
    NSString *mp3_file_path;
    @synchronized (self) {
        mp3_file_path = [_context.mp4_file_path copy];
    }
    
    NSURL *audio_file_url = [NSURL fileURLWithPath:mp3_file_path];
    
    AudioFileID audio_file_id = NULL;
    
    if (AudioFileOpenURL((__bridge CFURLRef)audio_file_url, kAudioFileReadPermission, kAudioFileMP3Type, &audio_file_id) != noErr) {
        return;
    }
    
    UInt32 io_data_size = 0;
    void *out_property_data;
    
    AudioFileGetPropertyInfo(audio_file_id, kAudioFilePropertyInfoDictionary, &io_data_size, NULL);
    if (io_data_size > 0) {
        out_property_data = malloc(io_data_size);
        AudioFileGetProperty(audio_file_id, kAudioFilePropertyInfoDictionary, &io_data_size, out_property_data);
        CFDictionaryRef info_dictionary;
        memcpy(&info_dictionary, out_property_data, io_data_size);
        NSString *album = [((__bridge NSDictionary *)info_dictionary)[@"album"] copy];
        NSString *artist = [((__bridge NSDictionary *)info_dictionary)[@"artist"] copy];
        NSString *title = [((__bridge NSDictionary *)info_dictionary)[@"title"] copy];
        if (album) {
            @synchronized (self) {
                _context.mp3_album = [album copy];
            }
        }
        if (artist) {
            @synchronized (self) {
                _context.mp3_artist = [artist copy];
            }
        }
        if (title) {
            @synchronized (self) {
                _context.mp3_title = [title copy];
            }
        }
        free(out_property_data);
    }
    
    io_data_size = 0;
    AudioFileGetPropertyInfo(audio_file_id, kAudioFilePropertyEstimatedDuration, &io_data_size, NULL);
    if (io_data_size > 0) {
        out_property_data = malloc(io_data_size);
        AudioFileGetProperty(audio_file_id, kAudioFilePropertyEstimatedDuration, &io_data_size, out_property_data);
        Float64 estimated_duration;
        memcpy(&estimated_duration, out_property_data, io_data_size);
        free(out_property_data);
    }
    
    io_data_size = 0;
    AudioFileGetPropertyInfo(audio_file_id, kAudioFilePropertyBitRate, &io_data_size, NULL);
    if (io_data_size > 0) {
        out_property_data = malloc(io_data_size);
        AudioFileGetProperty(audio_file_id, kAudioFilePropertyBitRate, &io_data_size, out_property_data);
        UInt32 bit_rate;
        memcpy(&bit_rate, out_property_data, io_data_size);
        @synchronized (self) {
            _context.mp3_bit_rate = [[NSString stringWithFormat:@"%dkbit/s", bit_rate/1000] copy];
        }
        free(out_property_data);
    }
    
    io_data_size = 0;
    AudioFileGetPropertyInfo(audio_file_id, kAudioFilePropertyAlbumArtwork, &io_data_size, NULL);
    if (io_data_size > 4) {
        out_property_data = malloc(io_data_size);
        AudioFileGetProperty(audio_file_id, kAudioFilePropertyAlbumArtwork, &io_data_size, out_property_data);
        CFDataRef album_artwork = CFDataCreate(NULL, (const UInt8 *)out_property_data, (CFIndex)io_data_size);
        UIImage *album_artwork_image = [[UIImage imageWithData:(__bridge NSData *)album_artwork] copy];
        @synchronized (self) {
            _context.player_cover = [album_artwork_image copy];
        }
        CFRelease(album_artwork);
        free(out_property_data);
    } else {
        io_data_size = 0;
        AudioFileGetPropertyInfo(audio_file_id, kAudioFilePropertyID3Tag, &io_data_size, NULL);
        if (io_data_size > 0) {
            out_property_data = malloc(io_data_size);
            AudioFileGetProperty(audio_file_id, kAudioFilePropertyID3Tag, &io_data_size, out_property_data);
            NSString *file_path;
            @synchronized (self) {
                file_path = [_context.mp4_file_path copy];
            }
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            AVAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:file_path] options:nil];
            [asset loadValuesAsynchronouslyForKeys:@[@"commonMetadata"]
                                 completionHandler:^{
                                     dispatch_semaphore_signal(semaphore);
                                 }];
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            NSArray *artworks = [AVMetadataItem metadataItemsFromArray:asset.commonMetadata
                                                               withKey:AVMetadataCommonKeyArtwork
                                                              keySpace:AVMetadataKeySpaceCommon];
            for (AVMetadataItem *item in artworks) {
                if ([item.keySpace isEqualToString:AVMetadataKeySpaceID3]) {
                    UIImage *image = [UIImage imageWithData:(NSData *)item.value];
                    @synchronized (self) {
                        _context.player_cover = [image copy];
                    }
                }
            }
        }
    }
    AudioFileClose(audio_file_id);
}

- (int)get_mp4_video_width_and_height_and_duration
{
    NSString *mp4_file_path;
    @synchronized (self) {
        mp4_file_path = [_context.mp4_file_path copy];
    }
    
    AVFormatContext *format_context;
    int video_stream = -1;
    int audio_stream = -1;
    AVCodecContext *codec_context;
    
    av_register_all();
    format_context = avformat_alloc_context();
    __block int err_code = avformat_open_input(&format_context, [mp4_file_path cStringUsingEncoding: NSUTF8StringEncoding], NULL, NULL);
    if (err_code != 0) {
        if (format_context) { avformat_free_context(format_context); };
        return -1;
    }
    
    err_code = avformat_find_stream_info(format_context, NULL);
    if (err_code < 0) {
        avformat_close_input((AVFormatContext **)&format_context);
        return -2;
    }
    
    double duration = 0.0;
    NSLog(@"---%lld", format_context->duration);
    if (format_context->duration == AV_NOPTS_VALUE) duration = MAXFLOAT;
    else duration = format_context->duration*1.0 / AV_TIME_BASE*1.0;
    @synchronized (self) {
        _context.mp4_duration = [NSString stringWithFormat:@"%.2f", duration].doubleValue;
    }
    
    av_dump_format(format_context, 0, [mp4_file_path.lastPathComponent cStringUsingEncoding: NSUTF8StringEncoding], 0);
    
    video_stream = av_find_best_stream(format_context, AVMEDIA_TYPE_VIDEO, -1, -1, NULL, 0);
    
    audio_stream = av_find_best_stream(format_context, AVMEDIA_TYPE_AUDIO, -1, -1, NULL, 0);
    
    BOOL is_exist_audio_track = NO, is_exist_video_track = NO;
    @synchronized (self) {
        is_exist_audio_track = _context.is_exist_audio_track;
        is_exist_video_track = _context.is_exist_video_track;
    }
    
    if (!is_exist_audio_track) {
        audio_stream = -1;
    }
    
    if (!is_exist_video_track) {
        video_stream = -1;
    }
    
    if (audio_stream==-1 && video_stream==-1) {
        avformat_close_input(&format_context);
        return -3;
    }
    
    if (video_stream >= 0) {
        @synchronized (self) {
            _context.video_frame_count = (unsigned int)format_context->streams[video_stream]->nb_frames;
            NSLog(@"_context.video_frame_count = %d", _context.video_frame_count);
        }
    }
    
    if (audio_stream >= 0) {
        @synchronized (self) {
            _context.audio_frame_count = (unsigned int)format_context->streams[audio_stream]->nb_frames;
            NSLog(@"_context.audio_frame_count = %d", _context.audio_frame_count);
        }
    }
    
    if (audio_stream >= 0) {
        double audio_duration = format_context->streams[audio_stream]->duration*av_q2d(format_context->streams[audio_stream]->time_base);
        @synchronized (self) {
            _context.mp4_audio_duration = audio_duration;
        }
    }
    
    if (video_stream >= 0) {
        double video_duration = format_context->streams[video_stream]->duration*av_q2d(format_context->streams[video_stream]->time_base);
        @synchronized (self) {
            _context.mp4_video_duration = video_duration;
        }
    }
    
    if (video_stream >= 0) {
        codec_context = format_context->streams[video_stream]->codec;
        if (!codec_context) {
            return -4;
        }
        double play_width = codec_context->width;
        double play_height = codec_context->height;
        @synchronized (self) {
            _context.play_width = play_width;
            _context.play_height = play_height;
        }
    }
    
    avformat_close_input(&format_context);
    
    return 0;
}

- (void)get_mp4_name
{
    @synchronized (self) {
        _context.mp4_file_name = [[_context.mp4_file_path lastPathComponent] copy];
    }
}

- (void)is_full_screen
{
    UIDeviceOrientation orient = [UIDevice currentDevice].orientation;
    if (orient==UIDeviceOrientationLandscapeLeft || orient == UIDeviceOrientationLandscapeRight) {
        @synchronized (self) {
            _context.is_full_screen = YES;
        }
    } else {
        @synchronized (self) {
            _context.is_full_screen = NO;
        }
    }
}

- (void)set_context
{
    @synchronized (self) {
        _context.is_sound = YES;
        _context.is_pause = YES;
        _context.audio_frame_count = 0;
        _context.video_frame_count = 0;
    }
    [self is_full_screen];
    [self is_exist_mp4_audio];
    [self is_exist_mp4_video];
    [self get_mp4_video_width_and_height_and_duration];
    [self get_mp4_name];
    @synchronized (self) {
        _context.play_duration = 0.0;
        _context.video_frame = nil;
        _context.audio_frame = nil;
        _context.is_play_end = NO;
        _context.is_decode_end = NO;
        if (!_context.is_exist_video_track) {
            _context.player_cover = [[UIImage imageNamed:@"IMG_0822.JPG"] copy];
        }
    }
    [self is_mp3_file];
    [self get_mp3_file_property];
}

- (void)start
{
    [self set_context];
    if (!_context.is_exist_video_track && !_context.is_exist_audio_track) {
        [[[UIAlertView alloc]initWithTitle:nil message:@"当前视频无内容！" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
    }
    else {
        [self play];
    }
}

- (void)play
{
    [self play_from_pos:0.0];
    [self show_UI];
    //[self post_cover_updata_notification];
}

//- (void)post_cover_updata_notification
//{
//    BOOL is_play_start = NO;
//    @synchronized (self) {
//        is_play_start = _context.is_play_start;
//    }
//    if (!is_play_start) {
//        BOOL is_exist_video_track = NO;
//        @synchronized (self) {
//            is_exist_video_track = _context.is_exist_video_track;
//        }
//        if (is_exist_video_track) {
//            dispatch_async(dispatch_get_global_queue(0, 0), ^{
//                __weak MP4_Decode_Frame_Queue *decode_queue = _video_decode_frame_queue;
//                while (decode_queue) {
//                    NSDictionary *dict = nil;
//                    @synchronized (self) {
//                        if (decode_queue.decode_frame_queue.count >= 20) {
//                            dict = [decode_queue.decode_frame_queue.lastObject copy];
//                        }
//                    }
//                    if (dict) {
//                        UIImage *video_frame = [dict[KVideo_Decoder_Frame_Data] copy];
//                        @synchronized (self) {
//                            _context.player_cover = [video_frame copy];
//                        }
//                        [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Player_View_Controller_Cover_Updata_Notice object:[video_frame copy]];
//                        break;
//                    }
//                    [NSThread sleepForTimeInterval:0.1];
//                }
//            });
//        }
//    }
//}

- (void)end_play
{
    [self unplay];
    [self hide_UI];
    self.mpvc = nil;
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)show_UI
{
    [MP4_Analysis share_mp4_analysis_global_window].hidden = NO;
    _mpvc = [[MP4_Player_View_Controller alloc]init_with_context:_context];
    [MP4_Analysis share_mp4_analysis_global_window].rootViewController = _mpvc;
}

- (void)hide_UI
{
    [MP4_Analysis share_mp4_analysis_global_window].rootViewController = nil;
    [MP4_Analysis share_mp4_analysis_global_window].hidden = YES;
}

CGRect get_screen_size()
{
    return [UIScreen mainScreen].bounds;
}

- (void)play_from_pos: (double)pos
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        BOOL is_exist_audio_track = NO;
        BOOL is_exist_video_track = NO;
        @synchronized (self) {
            is_exist_audio_track = _context.is_exist_audio_track;
            is_exist_video_track = _context.is_exist_video_track;
        }
        if (is_exist_audio_track || is_exist_video_track) {
            if (!_mdl) {
                NSString *mp4_file_path;
                BOOL is_exist_video_track, is_exist_audio_track, is_pause, is_sound;
                double mp4_duration, play_duration;
                @synchronized (self) {
                    mp4_file_path = [_context.mp4_file_path copy];
                    is_exist_video_track = _context.is_exist_video_track;
                    is_exist_audio_track = _context.is_exist_audio_track;
                    is_pause = _context.is_pause;
                    is_sound = _context.is_sound;
                    mp4_duration = _context.mp4_duration;
                    play_duration = _context.play_duration;
                }
                _mdl = [[MP4_Display_Loop alloc]init_with_mp4_file_path:mp4_file_path
                                                   is_exist_video_track:is_exist_video_track
                                                   is_exist_audio_track:is_exist_audio_track
                                                               is_pause:is_pause
                                                               is_sound:is_sound
                                                           mp4_duration:mp4_duration
                                                          play_duration:pos];
                [_mdl display];
            }
        }
        
        if (!_mavd) {
            NSString *mp4_file_path;
            BOOL is_exist_audio_track = NO;
            BOOL is_exist_video_track = NO;
            @synchronized (self) {
                mp4_file_path = [_context.mp4_file_path copy];
                is_exist_audio_track = _context.is_exist_audio_track;
                is_exist_video_track = _context.is_exist_video_track;
            }
            _mavd = [[MP4_AV_Decoder alloc]init_with_file_path:mp4_file_path is_exist_audio_track:is_exist_audio_track is_exist_video_track:is_exist_video_track];
            [_mavd start_decode];
            //[_mavd pause_decode];
        }
        
    });
}

- (void)unplay
{
    [_mavd end_decode];
    _mavd = nil;
    [_mdl cancel_display];
    _mdl = nil;
}

- (void)add_noti
{
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(pause_notice:) name:KMP4_Player_View_Controller_Pause_Notice object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(last_notice:) name:KMP4_Player_View_Controller_Last_Notice object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(next_notice:) name:KMP4_Player_View_Controller_Next_Notice object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(exit_notice:) name:KMP4_Player_View_Controller_Exit_Notice object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(progress_notice:) name:KMP4_Player_View_Controller_Progress_Notice object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(shot_notice:) name:KMP4_Player_View_Controller_Screen_Shot_Notice object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(sound_notice:) name:KMP4_Player_View_Controller_Sound_Notice object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(full_screen_notice:) name:KMP4_Player_View_Controller_Full_Screen_Notice object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(nomal_screen_notice:) name:KMP4_Player_View_Controller_Nomal_Screen_Notice object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orient_change:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    // [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(progress_refresh_notice:) name:KMP4_Player_View_Controller_Progress_Refresh_Notice object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(display_next_video:) name:KMP4_Player_View_Controller_Nomal_Display_Notice object:nil];

    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(play_end:) name:KMP4_Player_View_Controller_Play_End_Notice object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(will_resign_active:) name:UIApplicationWillResignActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(receive_next_audio:) name:KMP4_Player_View_Controller_Display_Audio_Notice object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(did_decode_video_first:) name:KMP4_Player_View_Controller_First_Decode_Video_Notice object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(did_decode_audio_first:) name:KMP4_Player_View_Controller_First_Decode_Audio_Notice object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(decode_end:) name:KMP4_Player_View_Controller_Decode_End_Notice object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(decode_error:) name:KMP4_Player_View_Controller_Decode_Error_Notice object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(clear_av_queue:) name:KMP4_Player_View_Controller_Clear_Audio_Video_Queue_Notice object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(decode_audio:) name:KMP4_Player_View_Controller_Audio_Frame_For_Queue_Notice object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(decode_video:) name:KMP4_Player_View_Controller_Video_Frame_For_Queue_Notice object:nil];
}

- (void)decode_video: (NSNotification *)noti
{
    if (noti.object) {
        [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Display_Loop_Video_Frame_For_Queue_Notice object:[noti.object copy]];
    }
}

- (void)decode_audio: (NSNotification *)noti
{
    if (noti.object) {
        [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Display_Loop_Audio_Frame_For_Queue_Notice object:[noti.object copy]];
    }
}

- (void)clear_av_queue: (NSNotification *)noti
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Display_Loop_Clear_Audio_Video_Queue_Notice object:nil];
    });
}

- (void)decode_error: (NSNotification *)noti
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self end_play];
    });
}

- (void)did_decode_video_first: (NSNotification *)noti
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(progress_refresh_notice:) name:KMP4_Player_View_Controller_Progress_Refresh_Notice object:nil];
        if (noti.object) {
            double frame_position = [noti.object intValue];
            @synchronized (self) {
                _context.play_duration = frame_position;
            }
            [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Display_Loop_First_Decode_Video_Notice object:@(frame_position)];
        }
    });
}

- (void)did_decode_audio_first: (NSNotification *)noti
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(progress_refresh_notice:) name:KMP4_Player_View_Controller_Progress_Refresh_Notice object:nil];
        if (noti.object) {
            double frame_position = [noti.object intValue];
            @synchronized (self) {
                _context.play_duration = frame_position;
            }
            [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Display_Loop_First_Decode_Audio_Notice object:@(frame_position)];
        }
    });
}

- (void)receive_next_audio: (NSNotification *)noti
{
    NSDictionary *dict = [noti.object copy];
    NSString *mp4_file_path = [dict[@"mp4_file_path"] copy];
    NSString *mp4_file_path_;
    @synchronized (self) {
        mp4_file_path_ = [_context.mp4_file_path copy];
    }
    if (![mp4_file_path isEqualToString:mp4_file_path_]) {
        return;
    }
    NSData *audio_frame = [(NSData *)dict[@"audio_frame"] copy];
    @synchronized (self) {
        if (audio_frame) {
            _context.audio_frame = [audio_frame copy];
        }
    }
}

- (void)will_resign_active: (NSNotification *)noti
{
    
}

- (void)decode_end: (NSNotification *)noti
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (![self notification_check:noti]) {
            return;
        }
        NSDictionary *dict = noti.object;
        if (dict) {
            BOOL is_decode_end = [dict[@"is_decode_end"] boolValue];
            @synchronized (self) {
                [MP4_Player_View_Controller_Context share_mp4_player_context].is_decode_end = is_decode_end;
            }
        }
        [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Display_Loop_Decode_End_Notice object:nil];
    });
}

- (void)play_end: (NSNotification *)noti
{
    if (![self notification_check:noti]) {
        return;
    }
    @synchronized (self) {
        [MP4_Player_View_Controller_Context share_mp4_player_context].is_play_end = YES;
    }
    [self end_play];
    NSString *mp4_file_path = nil;
    @synchronized (self) {
        mp4_file_path = [_context.mp4_file_path copy];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [[MP4_Analysis share_mp4_player_with_file_path:mp4_file_path] start];
    });
}

- (void)orient_change: (NSNotification *)noti
{
    UIDeviceOrientation orient = [UIDevice currentDevice].orientation;
    if (orient==UIDeviceOrientationPortrait || orient==UIDeviceOrientationLandscapeLeft || orient==UIDeviceOrientationLandscapeRight) {
        if (orient == UIDeviceOrientationPortrait) {
            @synchronized (self) {
                if (!_context.is_full_screen) {
                    return;
                }
                if (_context.is_full_screen) {
                    _context.is_full_screen = NO;
                }
            }
        } else if (orient == UIDeviceOrientationLandscapeLeft) {
            @synchronized (self) {
                _context.is_full_screen = YES;
            }
        } else if (orient == UIDeviceOrientationLandscapeRight) {
            @synchronized (self) {
                _context.is_full_screen = YES;
            }
        }
        [self show_UI];
    }
}

- (void)pause_notice: (NSNotification *)noti
{
    if (![self notification_check:noti]) {
        return;
    }
    BOOL is_pause = [noti.object[@"is_pause"] boolValue];
    @synchronized (self) {
        _context.is_pause = is_pause;
    }
    if (is_pause) {
        [_mdl pause_display];
    } else {
        [_mdl resum_display];
    }
}
- (void)last_notice: (NSNotification *)noti
{
    if (![self notification_check:noti]) {
        return;
    }
    [self end_play];
}
- (void)next_notice: (NSNotification *)noti
{
    if (![self notification_check:noti]) {
        return;
    }
    [self end_play];
}
- (void)exit_notice: (NSNotification *)noti
{
    if (![self notification_check: noti]) {
        return;
    }
    [self end_play];
}
- (void)progress_notice: (NSNotification *)noti
{
    if ([noti.name isEqualToString:KMP4_Player_View_Controller_Progress_Notice]) {
        if (![self notification_check:noti]) {
            return;
        }
        [[NSNotificationCenter defaultCenter]removeObserver:self name:KMP4_Player_View_Controller_Progress_Refresh_Notice object:nil];
        NSDictionary *dict = noti.object;
        NSNumber *play_duration_number = dict[@"play_duration"];
        double play_duration = play_duration_number.doubleValue;
        double mp4_duration = 0.0;
        @synchronized (self) {
            _context.play_duration = play_duration;
            mp4_duration = _context.mp4_duration;
        }
        [[NSNotificationCenter defaultCenter]postNotificationName:MP4_AV_Decoder_Decode_Seek_Notice object:@(play_duration)];
    }
}

- (void)progress_refresh_notice: (NSNotification *)noti
{
    NSDictionary *dict = [noti.object copy];
    NSString *mp4_file_path = dict[@"mp4_file_path"];
    NSString *mp4_file_path_ = nil;
    @synchronized (self) {
        mp4_file_path_ = _context.mp4_file_path;
    }
    if (![mp4_file_path isEqualToString:mp4_file_path_]) {
        return;
    }
    NSNumber *play_duration_number = dict[@"play_duration"];
    double play_duration = play_duration_number.doubleValue;
    double duration = 0.0;
    @synchronized (self) {
        duration = _context.mp4_duration;
        _context.play_duration = play_duration;
    }
    [self post_slider_refresh_notification];
}

- (void)post_slider_refresh_notification
{
    double play_duration = 0.0;
    NSString *mp4_file_path = nil;
    @synchronized (self) {
        play_duration = _context.play_duration;
        mp4_file_path = _context.mp4_file_path;
    }
    NSNumber *play_duration_number = [NSNumber numberWithDouble:play_duration];
    NSDictionary *dict = @{@"mp4_file_path":[mp4_file_path copy], @"play_duration":play_duration_number};
    [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Player_View_Controller_Slider_Refresh_Notice object:[dict copy]];
}

- (void)shot_notice: (NSNotification *)noti
{
    BOOL is_exist_video_track = NO;
    @synchronized (self) {
        is_exist_video_track = _context.is_exist_video_track;
    }
    if (is_exist_video_track) {
        if (![self notification_check:noti]) {
            return;
        }
        id shot_image;
        @synchronized (self) {
            shot_image = [_context.video_frame copy];
        }
        if (shot_image) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                UIImageWriteToSavedPhotosAlbum(shot_image, nil, nil, nil);
            });
            [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Player_View_Controller_Tip_Notice object:@"截图成功"];
        }
    }
}
- (NSString *)get_screen_shot_image_name
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss-SSS"];
    NSDate *current_date = [NSDate date];
    NSString *current_date_string = [formatter stringFromDate:current_date];
    NSMutableString *screen_shot_image_name = [NSMutableString string];
    [screen_shot_image_name appendString:@"img_"];
    [screen_shot_image_name appendString:current_date_string];
    [screen_shot_image_name appendString:@".jpg"];
    return [screen_shot_image_name copy];
}

- (void)sound_notice: (NSNotification *)noti
{
    if (![self notification_check:noti]) {
        return;
    }
    BOOL is_sound = NO;
    @synchronized (self) {
        _context.is_sound = !_context.is_sound;
        is_sound = _context.is_sound;
    }
    if (is_sound) {
        [_mdl sound_enable];
    } else {
        [_mdl sound_disable];
    }
}

- (void)pano_mode_notice: (NSNotification *)noti
{
    if (![self notification_check:noti]) {
        return;
    }
}
- (void)pano_view_mode_notice: (NSNotification *)noti
{
    if (![self notification_check:noti]) {
        return;
    }
}
- (void)full_screen_notice: (NSNotification *)noti
{
    if (![self notification_check:noti]) {
        return;
    }
    @synchronized (self) {
        _context.is_full_screen = YES;
    }
    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIInterfaceOrientationLandscapeRight] forKey:@"orientation"];
    [self show_UI];
}

- (void)nomal_screen_notice: (NSNotification *)noti
{
    if (![self notification_check:noti]) {
        return;
    }
    @synchronized (self) {
        _context.is_full_screen = NO;
    }
    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIInterfaceOrientationPortrait] forKey:@"orientation"];
    [self show_UI];
}

- (void)display_next_video: (NSNotification *)noti
{
    NSDictionary *dict = noti.object;
    NSString *mp4_file_path = dict[@"mp4_file_path"];
    NSString *mp4_file_path_;
    @synchronized (self) {
        mp4_file_path_ = _context.mp4_file_path;
    }
    if (![mp4_file_path isEqualToString:mp4_file_path_]) {
        return;
    }
    __block id video_frame;
    @synchronized (self) {
        video_frame = dict[@"video_frame_nomal"];
        _context.video_frame = video_frame;
    }
}

- (BOOL)notification_check: (NSNotification *)notification
{
    NSDictionary *dict = notification.object;
    NSString *mp4_file_name = [dict[@"mp4_file_name"] copy];
    NSString *mp4_file_name_;
    @synchronized (self) {
        mp4_file_name_ = _context.mp4_file_name;
    }
    if (![mp4_file_name isEqualToString:mp4_file_name_]) {
        return NO;
    }
    return YES;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end




