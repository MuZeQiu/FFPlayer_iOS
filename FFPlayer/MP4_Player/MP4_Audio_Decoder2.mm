//
//  MP4_Audio_Decoder2.m
//
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import "MP4_Audio_Decoder2.h"
#import "MP4_Decode_Frame_Queue.h"
#import "avcodec.h"
#import "avformat.h"
#import "swscale.h"
#import "swresample.h"
#include "loguru.hpp"
#include "MP4_Player_View_Controller_Context.h"

@interface MP4_Audio_Decoder2 ()

@property (nonatomic, weak) MP4_Decode_Frame_Queue *decode_queue;

@property (nonatomic) int decode_audio_id;

@property (nonatomic, copy) NSString *file_path;

@property (nonatomic) double mp4_duration;

@end

@implementation MP4_Audio_Decoder2

- (instancetype)init_with_file_path: (NSString *)file_path
                       mp4_duration: (double)mp4_duration
                       decode_queue: (MP4_Decode_Frame_Queue *)decode_queue

{
    self = [super init];
    if (self) {
        @synchronized (self) {
            _decode_queue = decode_queue;
        }
        _file_path = file_path;
        _mp4_duration = mp4_duration;
        _decode_audio_id = 0;
        
        LOG_F(INFO, "_decode_queue: %p", _decode_queue);
        LOG_F(INFO, "_file_path: %p", _file_path);
    }
    return self;
}

- (void)decode_audio_from_pos: (double)pos
{
    @synchronized (self) {
        _decode_audio_id++;
    }
    [self decode_audio_from_pos:pos decode_audio_id:_decode_audio_id decode_queue:_decode_queue];
}

- (void)set_decode_queue: (MP4_Decode_Frame_Queue *)decode_queue
{
    @synchronized (self) {
        _decode_queue = decode_queue;
        LOG_F(INFO, "_decode_queue: %p", _decode_queue);
    }
}

- (void)decode_audio_from_pos: (double)pos
              decode_audio_id: (int)decode_audio_id
                 decode_queue: (MP4_Decode_Frame_Queue *)decode_queue
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        av_register_all();
        
        AVFormatContext *pFormatCtx = avformat_alloc_context();
        if (!pFormatCtx) {
            return;
        }
        LOG_F(INFO, "pFormatCtx: %p", pFormatCtx);
        
        NSString *file_path = [_file_path copy];
        LOG_F(INFO, "file_path: %p", file_path);
        
        if (avformat_open_input(&pFormatCtx, [file_path UTF8String], NULL, NULL) != 0) {
            if (pFormatCtx)
                avformat_free_context(pFormatCtx);
            return;
        }
        
        if (avformat_find_stream_info(pFormatCtx, NULL) < 0) {
            avformat_close_input(&pFormatCtx);
            return;
        }
        
        int audio_stream_idx = -1;
        int i = 0;
        for (; i < pFormatCtx->nb_streams; i++) {
            if (pFormatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_AUDIO) {
                audio_stream_idx = i;
                break;
            }
        }
        
        if (audio_stream_idx < 0) {
            avformat_close_input(&pFormatCtx);
            return;
        }
        
        AVCodecContext *pCodeCtx = pFormatCtx->streams[audio_stream_idx]->codec;
        if (pCodeCtx == NULL) {
            avformat_close_input(&pFormatCtx);
            return;
        }
        LOG_F(INFO, "pCodeCtx: %p", pCodeCtx);
        
        AVCodec *pCodec = avcodec_find_decoder(pCodeCtx->codec_id);
        if (pCodec == NULL) {
            avformat_close_input(&pFormatCtx);
            return;
        }
        LOG_F(INFO, "pCodec: %p", pCodec);
        
        if (avcodec_open2(pCodeCtx, pCodec, NULL) < 0) {
            avformat_close_input(&pFormatCtx);
            return;
        }
        
        AVStream *st = pFormatCtx->streams[audio_stream_idx];
        double time_base = 0.0;
        if (st->time_base.den && st->time_base.num)
            time_base = av_q2d(st->time_base);
        else if(st->codec->time_base.den && st->codec->time_base.num)
            time_base = av_q2d(st->codec->time_base);
        else
            time_base = 0.025;
        
        AVPacket packet;
        LOG_F(INFO, "packet: %p", &packet);
        
        AVFrame *frame = av_frame_alloc();
        LOG_F(INFO, "frame: %p", frame);
        if (frame == NULL) {
            avcodec_close(pCodeCtx);
            avformat_close_input(&pFormatCtx);
            return;
        }
        
        SwrContext *swrCtx = swr_alloc();
        LOG_F(INFO, "swrCtx: %p", swrCtx);
        if (swrCtx == NULL) {
            avcodec_close(pCodeCtx);
            avformat_close_input(&pFormatCtx);
            return;
        }
        
        enum AVSampleFormat in_sample_fmt = pCodeCtx->sample_fmt;
        enum AVSampleFormat out_sample_fmt = AV_SAMPLE_FMT_S16;
        int in_sample_rate = pCodeCtx->sample_rate;
        int out_sample_rate = 44100;
        uint64_t in_ch_layout = pCodeCtx->channel_layout;
        uint64_t out_ch_layout = AV_CH_LAYOUT_MONO;
        swrCtx = swr_alloc_set_opts(swrCtx, out_ch_layout, out_sample_fmt, out_sample_rate, in_ch_layout, in_sample_fmt,
                           in_sample_rate, 0, NULL);
        if (!swrCtx || swr_init(swrCtx)) {
            if (swrCtx)
                swr_free(&swrCtx);
            avcodec_close(pCodeCtx);
            avformat_close_input(&pFormatCtx);
        }
        
        int out_channel_nb = av_get_channel_layout_nb_channels(out_ch_layout);
        
        uint8_t *out_buffer = (uint8_t *)malloc(20 * 44100);
        LOG_F(INFO, "out_buffer: %p", out_buffer);
        int ret, got_frame, framecount = 0;
        double seek_pos = pos;
        
        int64_t ts = (int64_t)(seek_pos / time_base);
        if (avformat_seek_file(pFormatCtx, audio_stream_idx, ts, ts, ts, AVSEEK_FLAG_FRAME) < 0) {
            if (swrCtx)
                swr_free(&swrCtx);
            av_frame_free(&frame);
            avcodec_close(pCodeCtx);
            avformat_close_input(&pFormatCtx);
        }
        avcodec_flush_buffers(pCodeCtx);
        
        __block BOOL is_decode_end = NO;
        
        while (_decode_audio_id == decode_audio_id) {
            @autoreleasepool {
                if (decode_queue.decode_frame_queue.count >= 20) {
                    [NSThread sleepForTimeInterval:0.001];
                    continue;
                }
                int read_len = av_read_frame(pFormatCtx, &packet);
                if (read_len == 0) {
                    if (packet.stream_index == audio_stream_idx) {
                        int packet_size = packet.size;
                        while (packet_size) {
                            @autoreleasepool {
                                ret = avcodec_decode_audio4(pCodeCtx, frame, &got_frame, &packet);
                                if (ret) {
                                    if (got_frame) {
                                        double frame_position = av_frame_get_best_effort_timestamp(frame)*time_base;
                                        double frame_duration = av_frame_get_pkt_duration(frame) * time_base;
                                        int out_samples = swr_convert(swrCtx, &out_buffer, 20 * 44100, (const uint8_t **)frame->data, frame->nb_samples);
                                        if (out_samples > 0) {
                                            int out_buffer_size = av_samples_get_buffer_size(NULL, out_channel_nb, out_samples, out_sample_fmt, 1);
                                            
                                            NSData *pcm_data = [[NSData dataWithBytes:out_buffer length:out_buffer_size] copy];
                                            LOG_F(INFO, "pcm_data: %p", pcm_data);
                                            NSDictionary *sample_dict = [[NSDictionary dictionaryWithObjectsAndKeys:pcm_data,KAudio_Decoder_Frame_Data,
                                                                          @(frame_position), KAudio_Decoder_Frame_Time,
                                                                          @(frame_duration), KAudio_Decoder_Frame_Duration,
                                                                          nil] copy];
                                            LOG_F(INFO, "sample_dict: %p", sample_dict);
                                            @synchronized (self) {
                                                [decode_queue.decode_frame_queue addObject:sample_dict];
                                            }
                                        }
                                        
                                    }
                                    packet_size -= ret;
                                } else {
                                    break;
                                }
                            }
                        }
                    }
                }
                av_free_packet(&packet);
                if (read_len < 0) {
                    [NSThread sleepForTimeInterval:0.01];
                    if (!is_decode_end) {
                        //[[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Player_View_Controller_Audio_Decode_End_Notice object:@{@"mp4_file_name": [[file_path lastPathComponent] copy]}];
                        is_decode_end = YES;
                    }
                }
            }
        }
        
        av_frame_free(&frame);
        av_free(out_buffer);
        swr_free(&swrCtx);
        avcodec_close(pCodeCtx);
        avformat_close_input(&pFormatCtx);
    });
}

- (void)end_decode_audio
{
    @synchronized (self) {
        _decode_audio_id++;
    }
}









@end
