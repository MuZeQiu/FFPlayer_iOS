//
//  MP4_Video_Decoder2.h
//
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MP4_Pro_Def.h"

@class MP4_Decode_Frame_Queue;

@interface MP4_Video_Decoder2 : NSObject

- (instancetype)init_with_file_path: (NSString *)file_path
                       mp4_duration: (double)mp4_duration
                       decode_queue: (MP4_Decode_Frame_Queue *)decode_queue;


- (void)decode_video_from_pos: (double)pos;

- (void)set_decode_queue: (MP4_Decode_Frame_Queue *)decode_queue;

- (void)end_decode_video;

@end
