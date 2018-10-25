//
//  MP4_Subtitle_Decoder2.m
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import "MP4_Subtitle_Decoder2.h"
#import "MP4_Decode_Frame_Queue.h"
#import "avcodec.h"
#import "avformat.h"
#import "swscale.h"
#import "swresample.h"
#include "MP4_Player_View_Controller_Context.h"

@interface MP4_Subtitle_Decoder2 ()

@property (nonatomic, weak) MP4_Decode_Frame_Queue *decode_queue;

@property (nonatomic) int decode_subtitle_id;

@property (nonatomic, copy) NSString *file_path;

@property (nonatomic) double mp4_duration;

@end

@implementation MP4_Subtitle_Decoder2

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
        _decode_subtitle_id = 0;
    }
    return self;
}

- (void)decode_subtitle_from_pos: (double)pos
{
    @synchronized (self) {
        _decode_subtitle_id++;
    }
    [self decode_subtitle_from_pos:pos
                decode_subtitle_id:_decode_subtitle_id
                   decode_queue:_decode_queue];
}

- (void)set_decode_queue: (MP4_Decode_Frame_Queue *)decode_queue
{
    @synchronized (self) {
        _decode_queue = decode_queue;
    }
}

- (void)end_decode_subtitle
{
    @synchronized (self) {
        _decode_subtitle_id++;
    }
}

- (void)decode_subtitle_from_pos: (double)pos
              decode_subtitle_id: (int)decode_subtitle_id
                 decode_queue: (MP4_Decode_Frame_Queue *)decode_queue
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        AVFormatContext *format_context = NULL;
        int subtitle_stream;
        AVCodecContext *codec_context = NULL;
        AVCodec *codec = NULL;
        AVSubtitle subtitle;
        AVPacket packet;
        __block int got_subtitle;
        AVDictionary *dict = NULL;
        double time_base = 0.0;
        
        av_register_all();
        
        format_context = avformat_alloc_context();
        if (!format_context) {
            return;
        }
        
        __block int err_code = avformat_open_input(&format_context, [_file_path cStringUsingEncoding: NSUTF8StringEncoding], NULL, NULL);
        if (err_code != 0) {
            avformat_free_context(format_context);
            return;
        }
        
        err_code = avformat_find_stream_info(format_context, NULL);
        if (err_code < 0) {
            avformat_close_input((AVFormatContext **)&format_context);
            return;
        }
        
        av_dump_format(format_context, 0, [_file_path.lastPathComponent cStringUsingEncoding: NSUTF8StringEncoding], 0);
        
        subtitle_stream = av_find_best_stream(format_context, AVMEDIA_TYPE_SUBTITLE, -1, -1, NULL, 0);
        if (subtitle_stream < 0) {
            avformat_close_input((AVFormatContext **)&format_context);
            return;
        }
        
        codec_context = format_context->streams[subtitle_stream]->codec;
        if (!codec_context) {
            avformat_close_input((AVFormatContext **)&format_context);
            return;
        }
        
        codec = avcodec_find_decoder(codec_context->codec_id);
        if (!codec) {
            avformat_close_input((AVFormatContext **)&format_context);
            return;
        }
        
        err_code = avcodec_open2(codec_context, codec, (AVDictionary **)&dict);
        if (err_code < 0) {
            avformat_close_input((AVFormatContext **)&format_context);
            return;
        }
        
        const AVCodecDescriptor *codec_desc = avcodec_descriptor_get(codec_context->codec_id);
        if (codec_desc && (codec_desc->props & AV_CODEC_PROP_BITMAP_SUB)) {
            avcodec_close(codec_context);
            avformat_close_input((AVFormatContext **)&format_context);
            return;
        }
        
        int subtitle_ass_events = -1;
        if (codec_context->subtitle_header_size) {
            NSString *s = [[NSString alloc] initWithBytes:codec_context->subtitle_header
                                                   length:codec_context->subtitle_header_size
                                                 encoding:NSASCIIStringEncoding];
            if (s.length) {
                NSArray *fields = [MP4_Subtitle_Decoder2 parseEvents:s];
                if (fields.count && [fields.lastObject isEqualToString:@"Text"]) {
                    subtitle_ass_events = fields.count;
                }
            }
        }
        
        AVStream *st = format_context->streams[subtitle_stream];
        
        if (st->time_base.den && st->time_base.num)
            time_base = av_q2d(st->time_base);
        else if(st->codec->time_base.den && st->codec->time_base.num)
            time_base = av_q2d(st->codec->time_base);
        else
            time_base = 1.0/25.0;
        
        double seek_pos = pos;
        int64_t ts = (int64_t)(seek_pos / time_base);
        if (avformat_seek_file(format_context, subtitle_stream, ts, ts, ts, AVSEEK_FLAG_FRAME) < 0) {
            avcodec_close(codec_context);
            avformat_close_input((AVFormatContext **)&format_context);
            return;
        }
        avcodec_flush_buffers(codec_context);
        
        __block BOOL is_decode_end = NO;
        
        while (_decode_subtitle_id == decode_subtitle_id) {
            @autoreleasepool {
                @synchronized (self) {
                    if (decode_queue.decode_frame_queue.count >= 20) {
                        [NSThread sleepForTimeInterval:0.001];
                        continue;
                    }
                }
                NSDictionary *sample_dict = nil;
                int read_len = 0;
                read_len = av_read_frame(format_context, &packet);
                if (read_len == 0) {
                    if (packet.stream_index == subtitle_stream) {
                        int packet_size = packet.size;
                        while (packet_size) {
                            @autoreleasepool {
                                int decode_len = avcodec_decode_subtitle2((AVCodecContext *)codec_context,
                                                         &subtitle,
                                                         &got_subtitle,
                                                         &packet);
                                if (decode_len > 0) {
                                    if (got_subtitle) {
                                        NSMutableString *ms = [NSMutableString string];
                                        for (NSUInteger i = 0; i < subtitle.num_rects; ++i) {
                                            AVSubtitleRect *rect = subtitle.rects[i];
                                            if (rect) {
                                                if (rect->text) { // rect->type == SUBTITLE_TEXT
                                                    NSString *s = [NSString stringWithUTF8String:rect->text];
                                                    if (s.length) [ms appendString:s];
                                                } else if (rect->ass && subtitle_ass_events != -1) {
                                                    NSString *s = [NSString stringWithUTF8String:rect->ass];
                                                    if (s.length) {
                                                        NSArray *fields = [MP4_Subtitle_Decoder2 parseDialogue:s numFields:subtitle_ass_events];
                                                        if (fields.count && [fields.lastObject length]) {
                                                            s = [MP4_Subtitle_Decoder2 removeCommandsFromEventText: fields.lastObject];
                                                            if (s.length) [ms appendString:s];
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        
                                        NSString *text = [ms copy];
                                        NSLog(@"---text = %@", text);
                                        double position = subtitle.pts / AV_TIME_BASE + subtitle.start_display_time;
                                        double duration = (CGFloat)(subtitle.end_display_time - subtitle.start_display_time) / 1000.f;
                                        
                                        sample_dict = [[NSDictionary dictionaryWithObjectsAndKeys:
                                                        text,KMP4_Subtitle_Decoder_Frame_Text,
                                                        @(position),KMP4_Subtitle_Decoder_Frame_Position,
                                                        @(duration),KMP4_Subtitle_Decoder_Frame_Duration,
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
                    if (!is_decode_end) {
                        //[[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Player_View_Controller_Video_Decode_End_Notice object:@{@"mp4_file_name": [[_file_path lastPathComponent] copy]}];
                        is_decode_end = YES;
                    }
                }
            }
        }
        avsubtitle_free(&subtitle);
        avcodec_close(codec_context);
        avformat_close_input((AVFormatContext **)&format_context);
    });
}



+ (NSArray *) parseEvents: (NSString *) events
{
    NSRange r = [events rangeOfString:@"[Events]"];
    if (r.location != NSNotFound) {
        
        NSUInteger pos = r.location + r.length;
        
        r = [events rangeOfString:@"Format:"
                          options:0
                            range:NSMakeRange(pos, events.length - pos)];
        
        if (r.location != NSNotFound) {
            
            pos = r.location + r.length;
            r = [events rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]
                                        options:0
                                          range:NSMakeRange(pos, events.length - pos)];
            
            if (r.location != NSNotFound) {
                
                NSString *format = [events substringWithRange:NSMakeRange(pos, r.location - pos)];
                NSArray *fields = [format componentsSeparatedByString:@","];
                if (fields.count > 0) {
                    
                    NSCharacterSet *ws = [NSCharacterSet whitespaceCharacterSet];
                    NSMutableArray *ma = [NSMutableArray array];
                    for (NSString *s in fields) {
                        [ma addObject:[s stringByTrimmingCharactersInSet:ws]];
                    }
                    return ma;
                }
            }
        }
    }
    
    return nil;
}

+ (NSArray *) parseDialogue: (NSString *) dialogue
                  numFields: (NSUInteger) numFields
{
    if ([dialogue hasPrefix:@"Dialogue:"]) {
        
        NSMutableArray *ma = [NSMutableArray array];
        
        NSRange r = {@"Dialogue:".length, 0};
        NSUInteger n = 0;
        
        while (r.location != NSNotFound && n++ < numFields) {
            
            const NSUInteger pos = r.location + r.length;
            
            r = [dialogue rangeOfString:@","
                                options:0
                                  range:NSMakeRange(pos, dialogue.length - pos)];
            
            const NSUInteger len = r.location == NSNotFound ? dialogue.length - pos : r.location - pos;
            NSString *p = [dialogue substringWithRange:NSMakeRange(pos, len)];
            p = [p stringByReplacingOccurrencesOfString:@"\\N" withString:@"\n"];
            [ma addObject: p];
        }
        
        return ma;
    }
    
    return nil;
}

+ (NSString *) removeCommandsFromEventText: (NSString *) text
{
    NSMutableString *ms = [NSMutableString string];
    
    NSScanner *scanner = [NSScanner scannerWithString:text];
    while (!scanner.isAtEnd) {
        
        NSString *s;
        if ([scanner scanUpToString:@"{\\" intoString:&s]) {
            
            [ms appendString:s];
        }
        
        if (!([scanner scanString:@"{\\" intoString:nil] &&
              [scanner scanUpToString:@"}" intoString:nil] &&
              [scanner scanString:@"}" intoString:nil])) {
            
            break;
        }
    }
    
    return ms;
}


@end
