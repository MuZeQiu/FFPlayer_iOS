//
//  MP4_AV_Decoder.h
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MP4_Pro_Def.h"

#define MP4_AV_Decoder_Decode_Seek_Notice @"MP4_AV_Decoder_Decode_Seek_Notice"

@interface MP4_AV_Decoder : NSObject

- (instancetype)init_with_file_path: (NSString *)file_path
               is_exist_audio_track: (BOOL)is_exist_audio_track
               is_exist_video_track: (BOOL)is_exist_video_track;

- (BOOL)start_decode;

- (void)pause_decode;

- (void)resum_decode;

- (void)end_decode;

@end
