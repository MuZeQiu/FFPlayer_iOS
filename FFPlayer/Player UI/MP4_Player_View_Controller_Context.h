//
//  MP4_Player_View_Controller_Context.h
//
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MP4_Pro_Def.h"
#import <UIKit/UIKit.h>

@interface MP4_Player_View_Controller_Context : NSObject

@property (nonatomic) BOOL is_sound;
@property (nonatomic) BOOL is_pause;

@property (nonatomic) BOOL is_full_screen;

@property (nonatomic) BOOL is_exist_video_track;
@property (nonatomic) BOOL is_exist_audio_track;

@property (nonatomic) double mp4_duration;
@property (nonatomic) double mp4_audio_duration;
@property (nonatomic) double mp4_video_duration;

@property (nonatomic) double play_duration;

@property (nonatomic, copy) UIImage *video_frame;
@property (nonatomic, copy) NSData *audio_frame;

@property (nonatomic) double play_width;
@property (nonatomic) double play_height;

@property (nonatomic, copy) NSString *mp4_file_path;
@property (nonatomic, copy) NSString *mp4_file_name;

@property (nonatomic) BOOL is_decode_end;

@property (nonatomic) BOOL is_play_end;

@property (nonatomic) UIImage *player_cover;

@property (nonatomic) unsigned int audio_frame_count;
@property (nonatomic) unsigned int video_frame_count;

/*mp3 数据*/
@property (nonatomic) BOOL is_mp3_file;
@property (nonatomic) NSString *mp3_title;
@property (nonatomic) NSString *mp3_artist;
@property (nonatomic) NSString *mp3_album;
@property (nonatomic) NSString *mp3_bit_rate;

+ (instancetype)share_mp4_player_context;

@end
