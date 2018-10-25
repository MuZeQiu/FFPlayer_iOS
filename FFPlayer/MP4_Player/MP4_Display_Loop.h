//
//  MP4_Display_Loop.h
//
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MP4_Pro_Def.h"

#define KMP4_Display_Loop_First_Decode_Video_Notice @"KMP4_Display_Loop_First_Decode_Video_Notice"
#define KMP4_Display_Loop_First_Decode_Audio_Notice @"KMP4_Display_Loop_First_Decode_Audio_Notice"
#define KMP4_Display_Loop_Audio_Frame_For_Queue_Notice @"KMP4_Display_Loop_Audio_Frame_For_Queue_Notice"
#define KMP4_Display_Loop_Video_Frame_For_Queue_Notice @"KMP4_Display_Loop_Video_Frame_For_Queue_Notice"
#define KMP4_Display_Loop_Clear_Audio_Video_Queue_Notice @"KMP4_Display_Loop_Clear_Audio_Video_Queue_Notice"
#define KMP4_Display_Loop_Decode_End_Notice @"KMP4_Display_Loop_Decode_End_Notice"

@interface MP4_Display_Loop : NSObject

- (instancetype)init_with_mp4_file_path: (NSString *)mp4_file_path
                   is_exist_video_track: (BOOL)is_exist_video_track
                   is_exist_audio_track: (BOOL)is_exist_audio_track
                               is_pause: (BOOL)is_pause
                               is_sound: (BOOL)is_sound
                           mp4_duration: (double)mp4_duration
                          play_duration: (double)play_duration;

- (void)display;

- (void)sound_enable;

- (void)sound_disable;

- (void)pause_display;

- (void)resum_display;

- (void)cancel_display;

@end
