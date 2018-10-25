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

@interface MP4_AV_Decoder ()

@property (nonatomic, weak) MP4_Decode_Frame_Queue *audio_decode_queue;
@property (nonatomic, weak) MP4_Decode_Frame_Queue *video_decode_queue;

@property (nonatomic) int decode_id;

@property (nonatomic, copy) NSString *file_path;

@property (nonatomic) double mp4_duration;

@end

@implementation MP4_AV_Decoder

- (instancetype)init_with_file_path: (NSString *)file_path
                       mp4_duration: (double)mp4_duration
                 audio_decode_queue: (MP4_Decode_Frame_Queue *)audio_decode_queue
                 video_decode_queue: (MP4_Decode_Frame_Queue *)video_decode_queue

{
    self = [super init];
    if (self) {
        @synchronized (self) {
            _audio_decode_queue = audio_decode_queue;
            _video_decode_queue = video_decode_queue;
        }
        _file_path = file_path;
        _mp4_duration = mp4_duration;
        _decode_id = 0;
    }
    return self;
}

- (void)decode_from_pos: (double)pos
{
    @synchronized (self) {
        _decode_id++;
    }
    [self decode_from_pos:pos
                decode_id:_decode_id
       audio_decode_queue:_audio_decode_queue
       video_decode_queue:_video_decode_queue];
}

- (void)set_audio_decode_queue: (MP4_Decode_Frame_Queue *)audio_decode_queue
            video_decode_queue: (MP4_Decode_Frame_Queue *)video_decode_queue
{
    @synchronized (self) {
        _audio_decode_queue = audio_decode_queue;
        _video_decode_queue = video_decode_queue;
    }
}

- (void)end_decode
{
    @synchronized (self) {
        _decode_id++;
    }
}

- (void)decode_from_pos: (double)pos
              decode_id: (int)decode_video_id
     audio_decode_queue: (MP4_Decode_Frame_Queue *)audio_decode_queue
     video_decode_queue: (MP4_Decode_Frame_Queue *)video_decode_queue
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
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
        
        av_register_all();
        format_context = avformat_alloc_context();
        __block int err_code = avformat_open_input(&format_context, [_file_path cStringUsingEncoding: NSUTF8StringEncoding], NULL, NULL);
        if (err_code != 0) {
            return;
        }
        
        err_code = avformat_find_stream_info(format_context, NULL);
        if (err_code < 0) {
            return;
        }
        
        av_dump_format(format_context, 0, [_file_path.lastPathComponent cStringUsingEncoding: NSUTF8StringEncoding], 0);
        
        video_stream = av_find_best_stream(format_context, AVMEDIA_TYPE_VIDEO, -1, -1, NULL, 0);
        if (video_stream < 0) {
            return;
        }
        
        audio_stream = av_find_best_stream(format_context, AVMEDIA_TYPE_AUDIO, -1, -1, NULL, 0);
        if (audio_stream < 0) {
            return;
        }
        
        video_codec_context = format_context->streams[video_stream]->codec;
        if (!video_codec_context) {
            return;
        }
        video_codec = avcodec_find_decoder(video_codec_context->codec_id);
        if (!video_codec) {
            return;
        }
        err_code = avcodec_open2(video_codec_context, video_codec, (AVDictionary **)&dict);
        if (err_code < 0) {
            return;
        }
        
        audio_codec_context = format_context->streams[audio_stream]->codec;
        if (!audio_codec_context) {
            return;
        }
        audio_codec = avcodec_find_decoder(audio_codec_context->codec_id);
        if (!video_codec) {
            return;
        }
        err_code = avcodec_open2(audio_codec_context, audio_codec, (AVDictionary **)&dict);
        if (err_code < 0) {
            return;
        }
        
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
    
        st = format_context->streams[audio_stream];
        if (st->time_base.den && st->time_base.num)
            audio_time_base = av_q2d(st->time_base);
        else if(st->codec->time_base.den && st->codec->time_base.num)
            audio_time_base = av_q2d(st->codec->time_base);
        else
            audio_time_base = 0.025;
    
        frame = av_frame_alloc();
        if (!frame) {
            return;
        }
        frame_yuv = av_frame_alloc();
        if (!frame_yuv) {
            return;
        }
        num_bytes = avpicture_get_size(AV_PIX_FMT_YUV420P, video_codec_context->width, video_codec_context->height);
        buffer = (uint8_t*)av_malloc(num_bytes);
        if (!buffer) {
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
            return;
        }
        err_code = avpicture_fill((AVPicture*)frame_yuv,
                                  buffer,
                                  AV_PIX_FMT_YUV420P,
                                  video_codec_context->width,
                                  video_codec_context->height);
        if (err_code < 0) {
            return;
        }
        
        double seek_pos = pos;
        int64_t ts = (int64_t)(seek_pos / video_time_base);
        avformat_seek_file(format_context, video_stream, ts, ts, ts, AVSEEK_FLAG_FRAME);
        avcodec_flush_buffers(video_codec_context);
        
        BOOL is_first_enter_loop = YES;
        
        while (_decode_id == decode_video_id) {
            @autoreleasepool {
                @synchronized (self) {
                    if (video_decode_queue.decode_frame_queue.count >= 20) {
                        [NSThread sleepForTimeInterval:0.001];
                        continue;
                    }
                }
                NSDictionary *sample_dict = nil;
                int read_len = 0;
                read_len = av_read_frame(format_context, &packet);
                if (read_len == 0) {
                    if (packet.stream_index == video_stream) {
                        int packet_size = packet.size;
                        while (packet_size) {
                            @autoreleasepool {
                                int decode_len = avcodec_decode_video2((AVCodecContext *)video_codec_context,
                                                                       (AVFrame *)frame,
                                                                       (int *)&frame_finished,
                                                                       &packet);
                                if (decode_len > 0) {
                                    if (frame_finished) {
                                        double frame_position = av_frame_get_best_effort_timestamp(frame)*video_time_base;
                                        if (is_first_enter_loop) {
                                            is_first_enter_loop = !is_first_enter_loop;
                                            [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Player_View_Controller_Video_Decode_Seek_With_First_Position_Notice object:@(frame_position)];
                                        }
                                        double frame_duration = 0.0;
                                        int64_t pkt_duration = av_frame_get_pkt_duration(frame);
                                        if (pkt_duration) {
                                            frame_duration = pkt_duration*video_time_base;
                                            frame_duration += frame->repeat_pict*video_time_base*0.5;
                                        } else {
                                            frame_duration = 1.0/fps;
                                        }
                                        
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
                                        [YUV_To_JPEG yuv:(uint8_t *)[yuv_data bytes]
                                          with_yuv_width:(uint32_t)video_codec_context->width
                                         with_yuv_height:(uint32_t)video_codec_context->height
                                                 to_jpeg:jpeg
                                               jpeg_size:&jpeg_size
                                jpeg_compression_quality:0.1
                                               save_path:nullptr];
                                        decode_frame_image = [[UIImage alloc]initWithData:[NSData dataWithBytes:jpeg length:jpeg_size]];
                                        free(jpeg);
                                        jpeg = nullptr;
                                        
                                        sample_dict = [[NSDictionary dictionaryWithObjectsAndKeys:
                                                        decode_frame_image,KVideo_Decoder_Frame_Data,
                                                        @(frame_position),KVideo_Decoder_Frame_Time,
                                                        @(frame_duration),KVideo_Decoder_Frame_Duration,
                                                        nil] copy];
                                        @synchronized (self) {
                                            [decode_queue.decode_frame_queue addObject:sample_dict];
                                        }
                                    }
                                    packet_size -= decode_len;
                                }
                                else {
                                    break;
                                }
                            }
                        }
                    }
                }
                av_free_packet(&packet);
                if (read_len < 0) {
                    [NSThread sleepForTimeInterval:0.01];
                    @synchronized (self) {
                        [MP4_Player_View_Controller_Context share_mp4_player_context].is_decode_video_end = YES;
                    }
                }
            }
        }
        av_free(buffer);
        av_free(frame_yuv);
        av_free(frame);
        sws_freeContext(sws_context);
        avcodec_close(codec_context);
        avformat_close_input((AVFormatContext **)&format_context);
        avformat_free_context(format_context);
    });
}




@end
