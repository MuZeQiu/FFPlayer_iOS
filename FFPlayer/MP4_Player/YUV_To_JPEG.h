//
//  YUV_To_JPEG.h
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YUV_To_JPEG : NSObject

+ (int)yuv: (uint8_t * __nonnull)yuv_buf
with_yuv_width: (uint32_t)yuv_width
with_yuv_height: (uint32_t)yuv_height
   to_jpeg: (uint8_t *&)jpeg_buf
 jpeg_size: (uint32_t * __nonnull)jpeg_size
jpeg_compression_quality: (double)jpeg_compression_quality
 save_path: (const char * __nullable)save_path;

@end
