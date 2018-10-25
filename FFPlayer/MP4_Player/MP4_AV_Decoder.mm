//
//  MP4_AV_Decoder.m
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import "MP4_AV_Decoder.h"
#import <UIKit/UIKit.h>
#import "MP4_Decode_Frame_Queue.h"
#import "avcodec.h"
#import "avformat.h"
#import "swscale.h"
#import "swresample.h"
#import "YUV_To_JPEG.h"
#include "MP4_Player_View_Controller_Context.h"

#define KMP4_AV_Decoder_Decode_Error_Notice @"KMP4_AV_Decoder_Decode_Error_Notice"
#define KMP4_AV_Decoder_First_Decode_Audio_Notice @"KMP4_AV_Decoder_First_Decode_Audio_Notice"
#define KMP4_AV_Decoder_First_Decode_Video_Notice @"KMP4_AV_Decoder_First_Decode_Video_Notice"
#define KMP4_AV_Decoder_Clear_Audio_Video_Queue_Notice @"KMP4_AV_Decoder_Clear_Audio_Video_Queue_Notice"
#define KMP4_AV_Decoder_Decode_End_Notice @"KMP4_AV_Decoder_Decode_End_Notice"
#define KMP4_AV_Decoder_Decode_Pause_Notice @"KMP4_AV_Decoder_Decode_Pause_Notice"
#define KMP4_AV_Decoder_Decode_Video_Frame_For_Queue_Notice @"KMP4_AV_Decoder_Decode_Video_Frame_For_Queue_Notice"
#define KMP4_AV_Decoder_Decode_Audio_Frame_For_Queue_Notice @"KMP4_AV_Decoder_Decode_Audio_Frame_For_Queue_Notice"

@interface MP4_AV_Decoder ()

@property (nonatomic, strong) NSMutableArray *event_decode_queue;

@property (nonatomic) int decode_id;

@property (nonatomic, copy) NSString *file_path;

@property (nonatomic) BOOL is_exist_audio_track;

@property (nonatomic) BOOL is_exist_video_track;

@property (nonatomic) BOOL is_start_decode;

@property (nonatomic) BOOL is_pause_decode;

@end

@implementation MP4_AV_Decoder

dispatch_queue_t decode_seek_event_thread_queue = nil;
dispatch_queue_t decode_video_thread_queue = nil;
dispatch_queue_t decode_audio_thread_queue = nil;

- (instancetype)init_with_file_path: (NSString *)file_path
               is_exist_audio_track: (BOOL)is_exist_audio_track
               is_exist_video_track: (BOOL)is_exist_video_track
{
    self = [super init];
    if (self) {
        decode_seek_event_thread_queue = dispatch_get_global_queue(0, 0);
        decode_video_thread_queue = dispatch_get_global_queue(0, 0);
        decode_audio_thread_queue = dispatch_get_global_queue(0, 0);
        @synchronized (self) {
            _event_decode_queue = [[NSMutableArray alloc]init];
            _is_exist_audio_track = is_exist_audio_track;
            _is_exist_video_track = is_exist_video_track;
            _file_path = [file_path copy];
            _decode_id = 0;
            _is_start_decode = NO;
            _is_pause_decode = NO;
        }
    }
    return self;
}

- (void)ready_for_property
{
    @synchronized (self) {
        _event_decode_queue = [[NSMutableArray alloc]init];
        _decode_id = 0;
        _is_start_decode = NO;
        _is_pause_decode = NO;
    }
}

- (void)add_observer
{
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(decode_seek:) name:MP4_AV_Decoder_Decode_Seek_Notice object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(decode_error:) name:KMP4_AV_Decoder_Decode_Error_Notice object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(find_first_audio:) name:KMP4_AV_Decoder_First_Decode_Audio_Notice object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(find_first_video:) name:KMP4_AV_Decoder_First_Decode_Video_Notice object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(remove_audio_video_queue_all_object:) name:KMP4_AV_Decoder_Clear_Audio_Video_Queue_Notice object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(decode_end:) name:KMP4_AV_Decoder_Decode_End_Notice object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(decode_pause:) name:KMP4_AV_Decoder_Decode_Pause_Notice object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(decode_video_frame:) name:KMP4_AV_Decoder_Decode_Video_Frame_For_Queue_Notice object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(decode_audio_frame:) name:KMP4_AV_Decoder_Decode_Audio_Frame_For_Queue_Notice object:nil];
}

- (void)decode_seek: (NSNotification *)noti
{
    dispatch_sync(decode_seek_event_thread_queue, ^{
        if (noti.object) {
            double seek_value = [noti.object doubleValue];
            @synchronized (self) {
                [_event_decode_queue addObject:@(seek_value)];
            }
        }
    });
}
- (void)decode_error: (NSNotification *)noti
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @synchronized (self) {
            _is_start_decode = NO;
        }
        if (noti.object) {
            double err_no = [noti.object intValue];
            [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Player_View_Controller_Decode_Error_Notice object:@(err_no)];
        }
    });
}
- (void)find_first_audio: (NSNotification *)noti
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (noti.object) {
            double frame_position = [noti.object intValue];
            [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Player_View_Controller_First_Decode_Audio_Notice object:@(frame_position)];
        }
    });
}
- (void)find_first_video: (NSNotification *)noti
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (noti.object) {
            double frame_position = [noti.object intValue];
            [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Player_View_Controller_First_Decode_Video_Notice object:@(frame_position)];
        }
    });
}
- (void)remove_audio_video_queue_all_object: (NSNotification *)noti
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Player_View_Controller_Clear_Audio_Video_Queue_Notice object:nil];
    });
}
- (void)decode_end: (NSNotification *)noti
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @synchronized (self) {
            _is_start_decode = NO;
        }
        if (noti.object) {
            NSDictionary *dict = [noti.object copy];
            BOOL is_decode_end = [dict[@"is_decode_end"] boolValue];
            [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Player_View_Controller_Decode_End_Notice object:@{@"mp4_file_name": [[_file_path lastPathComponent] copy], @"is_decode_end": [NSNumber numberWithBool:is_decode_end]}];
        }
    });
}
- (void)decode_pause: (NSNotification *)noti
{
    BOOL is_pause_decode = NO;
    @synchronized (self) {
        is_pause_decode = _is_pause_decode;
    }
    while (is_pause_decode) {
        [NSThread sleepForTimeInterval:0.001];
        @synchronized (self) {
            is_pause_decode = _is_pause_decode;
        }
    }
}
- (void)decode_video_frame: (NSNotification *)noti
{
    dispatch_sync(decode_video_thread_queue, ^{
        if (noti.object) {
            [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Player_View_Controller_Video_Frame_For_Queue_Notice object:[noti.object copy]];
        }
    });
}
- (void)decode_audio_frame: (NSNotification *)noti
{
    dispatch_sync(decode_audio_thread_queue, ^{
        if (noti.object) {
            [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Player_View_Controller_Audio_Frame_For_Queue_Notice object:[noti.object copy]];
        }
    });
}

- (BOOL)start_decode
{
    BOOL is_start_decode = NO;
    @synchronized (self) {
        is_start_decode = _is_start_decode;
    }
    if (!is_start_decode) {
        [self ready_for_property];
        [self add_observer];
        @synchronized (self) {
            _decode_id++;
            _is_start_decode = YES;
        }
        [self decode_with_id:_decode_id];
        return YES;
    }
    return NO;
}

- (void)pause_decode
{
    @synchronized (self) {
        _is_pause_decode = YES;
    }
}

- (void)resum_decode
{
    @synchronized (self) {
        _is_pause_decode = NO;
    }
}

- (void)end_decode
{
    [self resum_decode];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    @synchronized (self) {
        _decode_id++;
    }
}

- (void)decode_with_id: (int)decode_id
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        __weak MP4_AV_Decoder *ws = self;
        __weak NSMutableArray *event_decode_queue = nil;
        @synchronized (ws) {
            event_decode_queue = _event_decode_queue;
        }
        BOOL is_exist_audio_track, is_exist_video_track;
        @synchronized (ws) {
            is_exist_audio_track = _is_exist_audio_track;
            is_exist_video_track = _is_exist_video_track;
        }
        NSString *file_path = [ws.file_path copy];
        NSFileManager *fm = [NSFileManager defaultManager];
        if (![fm fileExistsAtPath:file_path]) {
            [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_Decode_Error_Notice object:@(0)];
            return;
        }
        AVFormatContext *format_context = NULL;
        int video_stream, audio_stream;
        AVCodecContext *video_codec_context = NULL;
        AVCodec *video_codec = NULL;
        AVCodecContext *audio_codec_context = NULL;
        AVCodec *audio_codec = NULL;
        AVFrame *frame = NULL;
        AVFrame *frame_yuv = NULL;
        AVPacket packet;
        __block int frame_finished;
        int num_bytes;
        uint8_t *buffer = NULL;
        AVDictionary *dict = NULL;
        struct SwsContext *sws_context = NULL;
        double video_time_base = 0.0;
        double audio_time_base = 0.0;
        double fps = 0.0;
        SwrContext *swr_ctx = NULL;
        BOOL need_seek = NO;
        
        av_register_all();
        
        format_context = avformat_alloc_context();
        
        __block int err_code = avformat_open_input(&format_context, [file_path cStringUsingEncoding: NSUTF8StringEncoding], NULL, NULL);
        if (err_code != 0) {
            if (format_context) avformat_free_context(format_context);
            [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_Decode_Error_Notice object:@(-1)];
            return;
        }

        err_code = avformat_find_stream_info(format_context, NULL);
        if (err_code < 0) {
            avformat_close_input((AVFormatContext **)&format_context);
            [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_Decode_Error_Notice object:@(-2)];
            return;
        }

        av_dump_format(format_context, 0, [file_path.lastPathComponent cStringUsingEncoding: NSUTF8StringEncoding], 0);
        
        double duration = 0.0;
        if (format_context->duration == AV_NOPTS_VALUE) duration = MAXFLOAT;
        else duration = format_context->duration*1.0 / AV_TIME_BASE*1.0;

        video_stream = av_find_best_stream(format_context, AVMEDIA_TYPE_VIDEO, -1, -1, NULL, 0);

        audio_stream = av_find_best_stream(format_context, AVMEDIA_TYPE_AUDIO, -1, -1, NULL, 0);
        
        if (!is_exist_video_track) {
            video_stream = -1;
        }
        
        if (!is_exist_audio_track) {
            audio_stream = -1;
        }
        
        if (audio_stream<0 && video_stream<0) {
            avformat_close_input((AVFormatContext **)&format_context);
            [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_Decode_Error_Notice object:@(-3)];
            return;
        }
        
        if (video_stream >= 0) {
            video_codec_context = format_context->streams[video_stream]->codec;
            if (!video_codec_context) {
                avformat_close_input((AVFormatContext **)&format_context);
                [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_Decode_Error_Notice object:@(-4)];
                return;
            }
            video_codec = avcodec_find_decoder(video_codec_context->codec_id);
            if (!video_codec) {
                avformat_close_input((AVFormatContext **)&format_context);
                [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_Decode_Error_Notice object:@(-5)];
                return;
            }
            err_code = avcodec_open2(video_codec_context, video_codec, (AVDictionary **)&dict);
            if (err_code < 0) {
                avformat_close_input((AVFormatContext **)&format_context);
                [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_Decode_Error_Notice object:@(-6)];
                return;
            }
        }
        
        if (audio_stream >= 0) {
            audio_codec_context = format_context->streams[audio_stream]->codec;
            if (!audio_codec_context) {
                if (video_stream >= 0) avcodec_close(video_codec_context);
                avformat_close_input((AVFormatContext **)&format_context);
                [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_Decode_Error_Notice object:@(-7)];
                return;
            }
            audio_codec = avcodec_find_decoder(audio_codec_context->codec_id);
            if (!audio_codec) {
                if (video_stream >= 0) avcodec_close(video_codec_context);
                avformat_close_input((AVFormatContext **)&format_context);
                [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_Decode_Error_Notice object:@(-8)];
                return;
            }
            err_code = avcodec_open2(audio_codec_context, audio_codec, (AVDictionary **)&dict);
            if (err_code < 0) {
                if (video_stream >= 0) avcodec_close(video_codec_context);
                avformat_close_input((AVFormatContext **)&format_context);
                [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_Decode_Error_Notice object:@(-9)];
                return;
            }
        }
        
        if (video_stream >= 0) {
            AVStream *st = format_context->streams[video_stream];
            if (st->time_base.den && st->time_base.num)
                video_time_base = av_q2d(st->time_base);
            else if(st->codec->time_base.den && st->codec->time_base.num)
                video_time_base = av_q2d(st->codec->time_base);
            else
                video_time_base = 1.0/25.0;
            
            if (st->avg_frame_rate.den && st->avg_frame_rate.num)
                fps = av_q2d(st->avg_frame_rate);
            else if (st->r_frame_rate.den && st->r_frame_rate.num)
                fps = av_q2d(st->r_frame_rate);
            else
                fps = 1.0 / video_time_base;
        }
        
        if (audio_stream >= 0) {
            AVStream *st = format_context->streams[audio_stream];
            if (st->time_base.den && st->time_base.num)
                audio_time_base = av_q2d(st->time_base);
            else if(st->codec->time_base.den && st->codec->time_base.num)
                audio_time_base = av_q2d(st->codec->time_base);
            else
                audio_time_base = 0.025;
        }
        
        if (audio_stream>=0 || video_stream>=0) {
            frame = av_frame_alloc();
            if (!frame) {
                if (video_stream >= 0) avcodec_close(video_codec_context);
                if (audio_stream >= 0) avcodec_close(audio_codec_context);
                avformat_close_input((AVFormatContext **)&format_context);
                [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_Decode_Error_Notice object:@(-10)];
                return;
            }
        }
        
        if (video_stream >= 0) {
            frame_yuv = av_frame_alloc();
            if (!frame_yuv) {
                av_frame_free(&frame);
                if (video_stream >= 0) avcodec_close(video_codec_context);
                if (audio_stream >= 0) avcodec_close(audio_codec_context);
                avformat_close_input((AVFormatContext **)&format_context);
                [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_Decode_Error_Notice object:@(-11)];
                return;
            }
            num_bytes = avpicture_get_size(AV_PIX_FMT_YUV420P, video_codec_context->width, video_codec_context->height);
            buffer = (uint8_t*)av_malloc(num_bytes);
            if (!buffer) {
                av_frame_free(&frame);
                if (video_stream >= 0) av_frame_free(&frame_yuv);
                if (video_stream >= 0) avcodec_close(video_codec_context);
                if (audio_stream >= 0) avcodec_close(audio_codec_context);
                avformat_close_input((AVFormatContext **)&format_context);
                [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_Decode_Error_Notice object:@(-12)];
                return;
            }
            sws_context = sws_getContext(video_codec_context->width,
                                         video_codec_context->height,
                                         video_codec_context->pix_fmt,
                                         video_codec_context->width,
                                         video_codec_context->height,
                                         AV_PIX_FMT_YUV420P,
                                         SWS_BICUBIC/*SWS_BILINEAR*/,
                                         NULL,
                                         NULL,
                                         NULL);
            if (!sws_context) {
                if (video_stream >= 0) av_free(buffer);
                av_frame_free(&frame);
                if (video_stream >= 0) av_frame_free(&frame_yuv);
                if (video_stream >= 0) sws_freeContext(sws_context);
                if (video_stream >= 0) avcodec_close(video_codec_context);
                if (audio_stream >= 0) avcodec_close(audio_codec_context);
                avformat_close_input((AVFormatContext **)&format_context);
                [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_Decode_Error_Notice object:@(-13)];
                return;
            }
            err_code = avpicture_fill((AVPicture*)frame_yuv,
                                      buffer,
                                      AV_PIX_FMT_YUV420P,
                                      video_codec_context->width,
                                      video_codec_context->height);
            if (err_code < 0) {
                if (video_stream >= 0) av_free(buffer);
                av_frame_free(&frame);
                if (video_stream >= 0) av_frame_free(&frame_yuv);
                if (video_stream >= 0) sws_freeContext(sws_context);
                if (video_stream >= 0) avcodec_close(video_codec_context);
                if (audio_stream >= 0) avcodec_close(audio_codec_context);
                avformat_close_input((AVFormatContext **)&format_context);
                [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_Decode_Error_Notice object:@(-14)];
                return;
            }
        }
        
        enum AVSampleFormat in_sample_fmt;
        enum AVSampleFormat out_sample_fmt;
        int in_sample_rate;
        int out_sample_rate;
        uint64_t in_ch_layout;
        uint64_t out_ch_layout;
        int out_channel_nb;
        if (audio_stream >= 0) {
            swr_ctx = swr_alloc();
            if (swr_ctx == NULL) {
                if (video_stream >= 0) av_free(buffer);
                av_frame_free(&frame);
                if (video_stream >= 0) av_frame_free(&frame_yuv);
                if (video_stream >= 0) sws_freeContext(sws_context);
                if (video_stream >= 0) avcodec_close(video_codec_context);
                if (audio_stream >= 0) avcodec_close(audio_codec_context);
                avformat_close_input((AVFormatContext **)&format_context);
                [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_Decode_Error_Notice object:@(-15)];
                return;
            }
            
            in_sample_fmt = audio_codec_context->sample_fmt;
            out_sample_fmt = AV_SAMPLE_FMT_S16;
            in_sample_rate = audio_codec_context->sample_rate;
            out_sample_rate = 44100;
            in_ch_layout = audio_codec_context->channel_layout;
            out_ch_layout = AV_CH_LAYOUT_MONO;
            swr_ctx = swr_alloc_set_opts(swr_ctx, out_ch_layout, out_sample_fmt, out_sample_rate, in_ch_layout, in_sample_fmt,
                                         in_sample_rate, 0, NULL);
            if (!swr_ctx || swr_init(swr_ctx)) {
                if (swr_ctx)
                    if (audio_stream >= 0) swr_free(&swr_ctx);
                if (video_stream >= 0) av_free(buffer);
                av_frame_free(&frame);
                if (video_stream >= 0) av_frame_free(&frame_yuv);
                if (video_stream >= 0) sws_freeContext(sws_context);
                if (video_stream >= 0) avcodec_close(video_codec_context);
                if (audio_stream >= 0) avcodec_close(audio_codec_context);
                avformat_close_input((AVFormatContext **)&format_context);
                [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_Decode_Error_Notice object:@(-16)];
                return;
            }
            out_channel_nb = av_get_channel_layout_nb_channels(out_ch_layout);
        }
        
        uint8_t *out_buffer = (uint8_t *)malloc(20 * 44100);
        int ret, got_frame;
        
    Start:
        BOOL is_decode_end = NO;
        [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_Decode_End_Notice object:@{@"mp4_file_name": [[_file_path lastPathComponent] copy], @"is_decode_end": [NSNumber numberWithBool:NO]}];
        BOOL is_first_get_frame = YES;
        unsigned int undecode_video_frame_count = 0;
        unsigned int undecode_audio_frame_count = 0;
        if (need_seek) {
            need_seek = NO;
            @autoreleasepool {
                __block double seek_pos = 0.0;
                @synchronized (ws) {
                    seek_pos = [event_decode_queue.lastObject doubleValue];
                    [event_decode_queue removeAllObjects];
                    [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_Clear_Audio_Video_Queue_Notice object:nil];
                }
                int64_t ts;
                if (audio_stream >= 0) {
                    ts = (int64_t)(seek_pos / audio_time_base);
                    if (avformat_seek_file(format_context, audio_stream, ts, ts, ts, AVSEEK_FLAG_BACKWARD) < 0) {
                        if (audio_stream >= 0) swr_free(&swr_ctx);
                        if (video_stream >= 0) av_free(buffer);
                        av_frame_free(&frame);
                        if (video_stream >= 0) av_frame_free(&frame_yuv);
                        if (video_stream >= 0) sws_freeContext(sws_context);
                        if (video_stream >= 0) avcodec_close(video_codec_context);
                        if (audio_stream >= 0) avcodec_close(audio_codec_context);
                        avformat_close_input((AVFormatContext **)&format_context);
                        [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_Decode_Error_Notice object:@(-17)];
                        return;
                    }
                    avcodec_flush_buffers(audio_codec_context);
                }
                if (video_stream >= 0) {
                    ts = (int64_t)(seek_pos / video_time_base);
                    if (avformat_seek_file(format_context, video_stream, ts, ts, ts, AVSEEK_FLAG_BACKWARD) < 0) {
                        if (audio_stream >= 0) swr_free(&swr_ctx);
                        if (video_stream >= 0) av_free(buffer);
                        av_frame_free(&frame);
                        if (video_stream >= 0) av_frame_free(&frame_yuv);
                        if (video_stream >= 0) sws_freeContext(sws_context);
                        if (video_stream >= 0) avcodec_close(video_codec_context);
                        if (audio_stream >= 0) avcodec_close(audio_codec_context);
                        avformat_close_input((AVFormatContext **)&format_context);
                        [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_Decode_Error_Notice object:@(-18)];
                        return;
                    }
                    avcodec_flush_buffers(video_codec_context);
                }
            }
        }
        
        while (YES) {
            @synchronized (ws) {
                if (_decode_id != decode_id) {
                    break;
                }
            }
            @synchronized (ws) {
                if (event_decode_queue.count > 0) {
                    need_seek = YES;
                    goto Start;
                }
            }
            @autoreleasepool {
                NSDictionary *sample_dict = nil;
                int read_len = 0;
                read_len = av_read_frame(format_context, &packet);
                if (read_len == 0) {
                    if (packet.stream_index == video_stream)
                    {
                        int packet_size = packet.size;
                        while (packet_size) {
                            
                            @synchronized (ws) {
                                if (_decode_id != decode_id) {
                                    break;
                                }
                            }
                            
                            BOOL need_seek = NO;
                            @synchronized (ws) {
                                if (event_decode_queue.count > 0) {
                                    need_seek = YES;
                                }
                            }
                            if (need_seek) {
                                goto Start;
                            }
                            
                            @autoreleasepool {
                                int decode_len = avcodec_decode_video2((AVCodecContext *)video_codec_context,
                                                                       (AVFrame *)frame,
                                                                       (int *)&frame_finished,
                                                                       &packet);
                                if (decode_len > 0) {
                                    if (frame_finished) {
                                        double frame_position = av_frame_get_best_effort_timestamp(frame)*video_time_base;
                                        NSLog(@"%f", frame_position);
                                        if (is_first_get_frame) {
                                            is_first_get_frame = NO;
                                            [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_First_Decode_Video_Notice object:@(frame_position)];
                                        }
                                        double frame_duration = 0.0;
                                        int64_t pkt_duration = av_frame_get_pkt_duration(frame);
                                        if (pkt_duration) {
                                            frame_duration = pkt_duration*video_time_base;
                                            frame_duration += frame->repeat_pict*video_time_base*0.5;
                                        } else {
                                            frame_duration = 1.0/fps;
                                        }
                                        
                                        BOOL is_final_frame = NO;
                                        (((frame_position+frame_duration)-duration)<0.001&&((frame_position+frame_duration)-duration)>-0.001)?is_final_frame=YES:is_final_frame;
                                        NSNumber *is_final_frame_number = [NSNumber numberWithBool:is_final_frame];
                        
                                        sws_scale(sws_context,
                                                  (const uint8_t* const*)frame->data,
                                                  frame->linesize,
                                                  0,
                                                  video_codec_context->height,
                                                  frame_yuv->data,
                                                  frame_yuv->linesize);
                                        int size_y = video_codec_context->width * video_codec_context->height;
                                        NSData *data_y = [NSData dataWithBytes:frame_yuv->data[0] length:size_y];
                                        NSData *data_u = [NSData dataWithBytes:frame_yuv->data[1] length:size_y/4];
                                        NSData *data_v = [NSData dataWithBytes:frame_yuv->data[2] length:size_y/4];
                                        NSMutableData *yuv_data = [NSMutableData data];
                                        [yuv_data appendData:data_y];
                                        [yuv_data appendData:data_u];
                                        [yuv_data appendData:data_v];
                                        
                                        UIImage *decode_frame_image;
                                        uint8_t *jpeg = nil;
                                        uint32_t jpeg_size = 0;
                                        if ([YUV_To_JPEG yuv:(uint8_t *)[yuv_data bytes]
                                          with_yuv_width:(uint32_t)video_codec_context->width
                                         with_yuv_height:(uint32_t)video_codec_context->height
                                                 to_jpeg:jpeg
                                               jpeg_size:&jpeg_size
                                jpeg_compression_quality:0.1
                                                   save_path:nullptr] == 0) {
                                            decode_frame_image = [[UIImage alloc]initWithData:[NSData dataWithBytes:jpeg length:jpeg_size]];
                                            free(jpeg);
                                            jpeg = nullptr;
                                            if (decode_frame_image) {
                                                sample_dict = [[NSDictionary dictionaryWithObjectsAndKeys:
                                                                decode_frame_image,KVideo_Decoder_Frame_Data,
                                                                @(frame_position),KVideo_Decoder_Frame_Time,
                                                                @(frame_duration),KVideo_Decoder_Frame_Duration,is_final_frame_number,KVideo_Decoder_Is_Final_Frame,
                                                                nil] copy];
                                                [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_Decode_Pause_Notice object:nil];
                                                [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_Decode_Video_Frame_For_Queue_Notice object:[sample_dict copy]];
                                            }
                                        }
                                    } else {
                                        undecode_video_frame_count++;
                                    }
                                }
                                else if (decode_len == 0) {
                                    break;
                                }
                                else {
                                    [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_Decode_Error_Notice object:@(-19)];
                                    goto End;
                                }
                                packet_size -= decode_len;
                            }
                        }
                    }
                    else if (packet.stream_index == audio_stream)
                    {
                        int packet_size = packet.size;
                        while (packet_size) {
                            
                            @synchronized (ws) {
                                if (_decode_id != decode_id) {
                                    break;
                                }
                            }
                            
                            BOOL need_seek = NO;
                            @synchronized (ws) {
                                if (event_decode_queue.count > 0) {
                                    need_seek = YES;
                                }
                            }
                            if (need_seek) {
                                goto Start;
                            }
                            
                            @autoreleasepool {
                                ret = avcodec_decode_audio4(audio_codec_context, frame, &got_frame, &packet);
                                if (ret > 0) {
                                    if (got_frame) {
                                        double frame_position = av_frame_get_best_effort_timestamp(frame)*audio_time_base;
                                        
                                        if (is_first_get_frame) {
                                            is_first_get_frame = NO;
                                            [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_First_Decode_Audio_Notice object:@(frame_position)];
                                        }
                                        double frame_duration = av_frame_get_pkt_duration(frame) * audio_time_base;
                                        BOOL is_final_frame = NO;
                                        (((frame_position+frame_duration)-duration)<0.001&&((frame_position+frame_duration)-duration)>-0.001)?is_final_frame=YES:is_final_frame;
                                        NSNumber *is_final_frame_number = [NSNumber numberWithBool:is_final_frame];
                                        
                                        int out_samples = swr_convert(swr_ctx, &out_buffer, 20 * 44100, (const uint8_t **)frame->data, frame->nb_samples);
                                        if (out_samples > 0) {
                                            int out_buffer_size = av_samples_get_buffer_size(NULL, out_channel_nb, out_samples, out_sample_fmt, 1);
                                            NSData *pcm_data = [[NSData dataWithBytes:out_buffer length:out_buffer_size] copy];
                                            NSDictionary *sample_dict = [[NSDictionary dictionaryWithObjectsAndKeys:pcm_data,KAudio_Decoder_Frame_Data,
                                                                          @(frame_position), KAudio_Decoder_Frame_Time,
                                                                          @(frame_duration), KAudio_Decoder_Frame_Duration,is_final_frame_number,KVideo_Decoder_Is_Final_Frame,
                                                                          nil] copy];
                                            [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_Decode_Pause_Notice object:nil];
                                            [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_Decode_Audio_Frame_For_Queue_Notice object:[sample_dict copy]];
                                        }
                                    } else {
                                        undecode_audio_frame_count++;
                                    }
                                }
                                else if (ret == 0) {
                                    break;
                                }
                                else {
                                    [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_Decode_Error_Notice object:@(-19)];
                                    goto End;
                                }
                                packet_size -= ret;
                            }
                        }
                    }
                }
                av_free_packet(&packet);
                if (read_len < 0) {
                    /*
                    while (1) {
                        @autoreleasepool {
                            if (undecode_video_frame_count == 0) {
                                break;
                            }
                            packet.data = NULL;
                            packet.size = 0;
                            int decode_len = avcodec_decode_video2((AVCodecContext *)video_codec_context,
                                                                   (AVFrame *)frame,
                                                                   (int *)&frame_finished,
                                                                   &packet);
                            if (decode_len >= 0) {
                                if (frame_finished) {
                                    double frame_position = av_frame_get_best_effort_timestamp(frame)*video_time_base;
                                    
                                    double frame_duration = 0.0;
                                    int64_t pkt_duration = av_frame_get_pkt_duration(frame);
                                    if (pkt_duration) {
                                        frame_duration = pkt_duration*video_time_base;
                                        frame_duration += frame->repeat_pict*video_time_base*0.5;
                                    } else {
                                        frame_duration = 1.0/fps;
                                    }
                                    BOOL is_final_frame = NO;
                                    (frame_position+frame_duration)>=duration?is_final_frame=YES:is_final_frame;
                                    NSNumber *is_final_frame_number = [NSNumber numberWithBool:is_final_frame];
                                    
                                    NSLog(@"-----%f %f", frame_position+frame_duration, duration);
                                    
                                    sws_scale(sws_context,
                                              (const uint8_t* const*)frame->data,
                                              frame->linesize,
                                              0,
                                              video_codec_context->height,
                                              frame_yuv->data,
                                              frame_yuv->linesize);
                                    int size_y = video_codec_context->width * video_codec_context->height;
                                    NSData *data_y = [NSData dataWithBytes:frame_yuv->data[0] length:size_y];
                                    NSData *data_u = [NSData dataWithBytes:frame_yuv->data[1] length:size_y/4];
                                    NSData *data_v = [NSData dataWithBytes:frame_yuv->data[2] length:size_y/4];
                                    NSMutableData *yuv_data = [NSMutableData data];
                                    [yuv_data appendData:data_y];
                                    [yuv_data appendData:data_u];
                                    [yuv_data appendData:data_v];
                                    
                                    UIImage *decode_frame_image;
                                    uint8_t *jpeg = nil;
                                    uint32_t jpeg_size = 0;
                                    if ([YUV_To_JPEG yuv:(uint8_t *)[yuv_data bytes]
                                          with_yuv_width:(uint32_t)video_codec_context->width
                                         with_yuv_height:(uint32_t)video_codec_context->height
                                                 to_jpeg:jpeg
                                               jpeg_size:&jpeg_size
                                jpeg_compression_quality:0.1
                                               save_path:nullptr] == 0) {
                                        decode_frame_image = [[UIImage alloc]initWithData:[NSData dataWithBytes:jpeg length:jpeg_size]];
                                        free(jpeg);
                                        jpeg = nullptr;
                                        if (decode_frame_image) {
                                            sample_dict = [[NSDictionary dictionaryWithObjectsAndKeys:
                                                            decode_frame_image,KVideo_Decoder_Frame_Data,
                                                            @(frame_position),KVideo_Decoder_Frame_Time,
                                                            @(frame_duration),KVideo_Decoder_Frame_Duration,is_final_frame_number,KVideo_Decoder_Is_Final_Frame,
                                                            nil] copy];
                                            [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_Decode_Pause_Notice object:nil];
                                            [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_AV_Decoder_Decode_Video_Frame_For_Queue_Notice object:[sample_dict copy]];
                                        }
                                    }
                                }
                            }
                            av_free_packet(&packet);
                            undecode_video_frame_count--;
                        }
                    }
                     */
                    if (!is_decode_end) {
                        is_decode_end = YES;
                        [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Player_View_Controller_Decode_End_Notice object:@{@"mp4_file_name": [[_file_path lastPathComponent] copy], @"is_decode_end": [NSNumber numberWithBool:YES]}];
                    }
                }
            }
        }
        
    End:
        av_free_packet(&packet);
        if (audio_stream >= 0) swr_free(&swr_ctx);
        if (video_stream >= 0) av_free(buffer);
        av_frame_free(&frame);
        if (video_stream >= 0) av_frame_free(&frame_yuv);
        if (video_stream >= 0) sws_freeContext(sws_context);
        if (video_stream >= 0) avcodec_close(video_codec_context);
        if (audio_stream >= 0) avcodec_close(audio_codec_context);
        avformat_close_input((AVFormatContext **)&format_context);
        return;
    });
}

- (void)dealloc
{
    
}


@end
