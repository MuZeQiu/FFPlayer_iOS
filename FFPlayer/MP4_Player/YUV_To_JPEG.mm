//
//  YUV_To_JPEG.m
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import "YUV_To_JPEG.h"
#include "avcodec.h"
#include "avformat.h"
#import <UIKit/UIKit.h>

@implementation YUV_To_JPEG

              + (int)yuv: (uint8_t * __nonnull)yuv_buf
          with_yuv_width: (uint32_t)yuv_width
         with_yuv_height: (uint32_t)yuv_height
                 to_jpeg: (uint8_t *&)jpeg_buf
               jpeg_size: (uint32_t * __nonnull)jpeg_size
jpeg_compression_quality: (double)jpeg_compression_quality
               save_path: (const char * __nullable)save_path
{
    AVFormatContext* pFormatCtx;
    AVOutputFormat* fmt;
    AVStream* video_st;
    AVCodecContext* pCodecCtx;
    AVCodec* pCodec;
    
    uint8_t* picture_buf;
    AVFrame* picture;
    AVPacket pkt;
    int y_size;
    int got_picture = 0;
    int size;
    
    int ret = 0;
    
    int in_w = yuv_width, in_h = yuv_height;
    
    av_register_all();
    
    pFormatCtx = avformat_alloc_context();
    
    fmt = av_guess_format("mjpeg", NULL, NULL);
    
    pFormatCtx->oformat = fmt;
    
    video_st = avformat_new_stream(pFormatCtx, 0);
    if (video_st == NULL) {
        return -1;
    }
    pCodecCtx = video_st->codec;
    pCodecCtx->codec_id = fmt->video_codec;
    pCodecCtx->codec_type = AVMEDIA_TYPE_VIDEO;
    pCodecCtx->pix_fmt = AV_PIX_FMT_YUVJ420P;
    
    pCodecCtx->width = in_w;
    pCodecCtx->height = in_h;
    
    pCodecCtx->time_base.num = 1;
    pCodecCtx->time_base.den = 25;
    
    pCodec = avcodec_find_encoder(pCodecCtx->codec_id);
    if (!pCodec) {
        return -2;
    }
    if (avcodec_open2(pCodecCtx, pCodec,NULL) < 0) {
        return -3;
    }
    picture = av_frame_alloc();
    size = avpicture_get_size(pCodecCtx->pix_fmt, pCodecCtx->width, pCodecCtx->height);
    picture_buf = (uint8_t *)av_malloc(size);
    if (!picture_buf) {
        return -4;
    }
    avpicture_fill((AVPicture *)picture, picture_buf, pCodecCtx->pix_fmt, pCodecCtx->width, pCodecCtx->height);
    
    avformat_write_header(pFormatCtx,NULL);
    
    y_size = pCodecCtx->width * pCodecCtx->height;
    av_new_packet(&pkt,y_size*3);
    
    memcpy(picture_buf, yuv_buf, yuv_width*yuv_height*3/2);
    
    picture->data[0] = picture_buf;
    picture->data[1] = picture_buf + y_size;
    picture->data[2] = picture_buf + y_size*5/4;
    
    ret = avcodec_encode_video2(pCodecCtx, &pkt, picture, &got_picture);
    if (ret < 0) {
        return -5;
    }
    
    if (got_picture == 1) {
        @autoreleasepool {
            if (jpeg_compression_quality >= 1.0) jpeg_compression_quality = 1.00;
            if (jpeg_compression_quality <= 0.0) jpeg_compression_quality = 0.01;
            NSData *ori_data = [NSData dataWithBytes:pkt.data length:pkt.size];
            UIImage *ori_img = [UIImage imageWithData:ori_data];
            ori_data = UIImageJPEGRepresentation(ori_img, jpeg_compression_quality);
            uint8_t *jpeg_buf_ = (uint8_t *)malloc(ori_data.length);
            memcpy(jpeg_buf_, (uint8_t *)[ori_data bytes], ori_data.length);
            jpeg_buf = jpeg_buf_;
            *jpeg_size = (uint32_t)ori_data.length;
            if (save_path) {
                unlink(save_path);
                [ori_data writeToFile:[NSString stringWithUTF8String:save_path] atomically:YES];
            }
        }
    }
    
    av_free_packet(&pkt);
    
    if (video_st) {
        avcodec_close(video_st->codec);
        av_free(picture);
        av_free(picture_buf);
    }
    avformat_free_context(pFormatCtx);
    return 0;
}

@end
