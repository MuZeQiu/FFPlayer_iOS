//
//  Bottom_Tool_View.m
//
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import "Bottom_Tool_View.h"

#include<stdio.h>
#include<stdlib.h>
#define random(x) (rand()%x)

@interface Bottom_Tool_View ()

@property (nonatomic, strong) UILabel *left_time_lbl;

@property (nonatomic, strong) UISlider *time_slider;

@property (nonatomic, strong) UILabel *right_time_lbl;

@property (nonatomic, strong) UIButton *shot_but;

@property (nonatomic, strong) UIButton *sound_but;

@property (nonatomic, strong) UIButton *full_but;

@property (nonatomic, weak) MP4_Player_View_Controller_Context *context;

@end

@implementation Bottom_Tool_View

- (instancetype)init_with_frame: (CGRect)frame
                        context: (MP4_Player_View_Controller_Context *)context
{
    self = [super initWithFrame:frame];
    if (self) {
        @synchronized (self) {
            _context = context;
        }
        
        self.backgroundColor = [UIColor colorWithRed:0.0
                                               green:0.0
                                                blue:0.0
                                               alpha:0.6];
        [self add_obser];
        [self add_ui];
    }
    return self;
}

- (void)add_ui
{
    [self add_left_time_lbl];
    [self add_time_slider];
    [self add_right_time_lbl];
    [self add_shot_but];
    [self add_sound_but];
    [self add_full_but];
}

- (void)add_left_time_lbl
{
    _left_time_lbl = [[UILabel alloc]initWithFrame:CGRectMake(20.0, 5.0, 80.0, 30.0)];
    _left_time_lbl.textAlignment = NSTextAlignmentCenter;
    _left_time_lbl.textColor = [UIColor whiteColor];
    double play_duration = 0.0;
    @synchronized (self) {
        play_duration = _context.play_duration;
    }
    _left_time_lbl.text = [self conver_hms_from_int:play_duration];
    [self addSubview:_left_time_lbl];
}

- (void)add_time_slider
{
    _time_slider = [[UISlider alloc]initWithFrame:CGRectMake(20.0+80.0+5.0, 5.0, self.frame.size.width-20.0-80.0-5.0-5.0-80.0-20.0-30.0-20.0-30.0-20.0-30.0-20.0, 30.0)];
    [self addSubview:_time_slider];
    _time_slider.minimumTrackTintColor = [UIColor whiteColor];
    _time_slider.thumbTintColor = [UIColor whiteColor];
    _time_slider.maximumTrackTintColor = [UIColor lightGrayColor];
    _time_slider.minimumValue = 0.0;
    double mp4_duration = 0.0;
    @synchronized (self) {
        mp4_duration = _context.mp4_duration;
    }
    _time_slider.maximumValue = mp4_duration;
    [_time_slider setThumbImage:[UIImage imageNamed:@"icon_jdt_dot.png"] forState:UIControlStateNormal];
    [_time_slider setThumbImage:[UIImage imageNamed:@"icon_jdt_dot.png"] forState:UIControlStateHighlighted];
    _time_slider.enabled = YES;
    double play_duration = 0.0;
    @synchronized (self) {
        play_duration = _context.play_duration;
    }
    [_time_slider setValue:play_duration];
    [_time_slider addTarget:self action:@selector(slide_time:) forControlEvents:UIControlEventTouchUpInside];
    [_time_slider addTarget:self action:@selector(slide_time:) forControlEvents:UIControlEventTouchUpOutside];
    [_time_slider addTarget:self action:@selector(slide_time_drag:) forControlEvents:UIControlEventTouchDragInside];
    [_time_slider addTarget:self action:@selector(slide_time_drag:) forControlEvents:UIControlEventTouchDragOutside];
}

- (void)add_right_time_lbl
{
    _right_time_lbl = [[UILabel alloc]initWithFrame:CGRectMake(_time_slider.frame.origin.x+_time_slider.frame.size.width+5.0, 5.0, 80.0, 30.0)];
    _right_time_lbl.textAlignment = NSTextAlignmentCenter;
    _right_time_lbl.textColor = [UIColor whiteColor];
    
    double mp4_duration = 0.0;
    double play_duration = 0.0;
    @synchronized (self) {
        mp4_duration = _context.mp4_duration;
        play_duration = _context.play_duration;
    }
    _right_time_lbl.text = [self conver_hms_from_int:(mp4_duration-play_duration)];
    [self addSubview:_right_time_lbl];
}

- (void)add_shot_but
{
    _shot_but = [[UIButton alloc]initWithFrame:CGRectMake(_right_time_lbl.frame.origin.x+_right_time_lbl.frame.size.width+20.0, 5.0, 30.0, 30.0)];
    [self addSubview:_shot_but];
    [_shot_but setImage:[UIImage imageNamed:@"btn_jietu_white2.png"] forState:UIControlStateNormal];
    [_shot_but addTarget:self action:@selector(shot:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)shot: (UIButton *)sender
{
    sender.enabled = NO;
    [self post_shot_notification];
    sender.enabled = YES;
}

- (void)post_shot_notification
{
    NSString *mp4_file_name = nil;
    @synchronized (self) {
        mp4_file_name = _context.mp4_file_name;
    }
    NSDictionary *dict = @{@"mp4_file_name":mp4_file_name};
    [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Player_View_Controller_Screen_Shot_Notice object:[dict copy]];
}

- (void)add_sound_but
{
    _sound_but = [[UIButton alloc]initWithFrame:CGRectMake(_shot_but.frame.origin.x+_shot_but.frame.size.width+20.0, 5.0, 30.0, 30.0)];
    [self addSubview:_sound_but];
    BOOL is_sound = NO;
    @synchronized (self) {
        is_sound = _context.is_sound;
    }
    if (is_sound) {
        [_sound_but setImage:[UIImage imageNamed:@"btn_voice_open_white.png"] forState:UIControlStateNormal];
    } else {
        [_sound_but setImage:[UIImage imageNamed:@"btn_voice_close_white.png"] forState:UIControlStateNormal];
    }
    [_sound_but addTarget:self action:@selector(ctl_sound:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)add_full_but
{
    _full_but = [[UIButton alloc]initWithFrame:CGRectMake(_sound_but.frame.origin.x+_sound_but.frame.size.width+20.0, 5.0, 30.0, 30.0)];
    [self addSubview:_full_but];
    [_full_but setImage:[UIImage imageNamed:@"btn_sf.png"] forState:UIControlStateNormal];
    [_full_but addTarget:self action:@selector(full:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)slide_time: (UISlider *)sender
{
    double mp4_duration = 0.0;
    double play_duration = sender.value;
    if (play_duration-_context.play_duration<1.0 && play_duration-_context.play_duration>-1.0) {
        return;
    }
    @synchronized (self) {
        mp4_duration = _context.mp4_duration;
    }
    _left_time_lbl.text = [self conver_hms_from_int:play_duration];
    _right_time_lbl.text = [self conver_hms_from_int:(mp4_duration-play_duration)];
    NSString *mp4_file_name = nil;
    @synchronized (self) {
        mp4_file_name = _context.mp4_file_name;
    }
    NSNumber *play_duration_number = [NSNumber numberWithDouble:sender.value];
    NSDictionary *dict = @{@"mp4_file_name":mp4_file_name, @"play_duration":play_duration_number};
    [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Player_View_Controller_Progress_Notice object:[dict copy]];
}
- (void)slide_time_drag: (UISlider *)sender
{
    double mp4_duration = 0.0;
    double play_duration = sender.value;
    @synchronized (self) {
        mp4_duration = _context.mp4_duration;
    }
    _left_time_lbl.text = [self conver_hms_from_int:play_duration];
    _right_time_lbl.text = [self conver_hms_from_int:(mp4_duration-play_duration)];
}

- (void)set_play_progress
{
    double play_duration = 0.0;
    double mp4_duration = 0.0;
    @synchronized (self) {
        play_duration = _context.play_duration;
        mp4_duration = _context.mp4_duration;
    }
    _time_slider.value = play_duration;
    _left_time_lbl.text = [self conver_hms_from_int:play_duration];;
    _right_time_lbl.text = [self conver_hms_from_int:(mp4_duration-play_duration)];
}

- (NSString *)conver_hms_from_int: (uint32_t)duration
{
    int h = 0, m = 0, s = 0;
    h = duration / 60 / 60;
    m = (duration - h*60*60) / 60;
    s = duration - h*60*60 - m*60;
    return [NSString stringWithFormat:@"%02d:%02d:%02d", h, m, s];
}

- (void)ctl_sound: (UIButton *)sender
{
    sender.enabled = NO;
    BOOL is_sound = NO;
    @synchronized (self) {
        is_sound = _context.is_sound;
    }
    is_sound = !is_sound;
    if (is_sound) {
        [_sound_but setImage:[UIImage imageNamed:@"btn_voice_open_white.png"] forState:UIControlStateNormal];
    }
    else {
        [_sound_but setImage:[UIImage imageNamed:@"btn_voice_close_white.png"] forState:UIControlStateNormal];
    }
    [self post_sound_notification];
    sender.enabled = YES;
}

- (void)post_sound_notification
{
    NSString *mp4_file_name = nil;
    @synchronized (self) {
        mp4_file_name = _context.mp4_file_name;
    }
    NSDictionary *dict = @{@"mp4_file_name":mp4_file_name};
    [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Player_View_Controller_Sound_Notice object:[dict copy]];
}


- (void)full: (UIButton *)sender
{
    sender.enabled = NO;
    [self post_full_notification];
    sender.enabled = YES;
}

- (void)post_full_notification
{
    NSString *mp4_file_name = nil;
    @synchronized (self) {
        mp4_file_name = _context.mp4_file_name;
    }
    NSDictionary *dict = @{@"mp4_file_name":mp4_file_name};
    [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Player_View_Controller_Nomal_Screen_Notice object:[dict copy]];
}


- (void)add_obser
{
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(slider_refresh:) name:KMP4_Player_View_Controller_Slider_Refresh_Notice object:nil];
}

- (void)slider_refresh: (NSNotification *)noti
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_time_slider.tracking) {
            return;
        }
        NSDictionary *dict = [noti.object copy];
        NSString *mp4_file_path = dict[@"mp4_file_path"];
        NSString *mp4_file_path_ = nil;
        @synchronized (self) {
            mp4_file_path_ = _context.mp4_file_path;
        }
        if (![mp4_file_path isEqualToString:mp4_file_path_]) {
            return;
        }
        NSNumber *play_duration_number = dict[@"play_duration"];
        double play_duration = play_duration_number.doubleValue;
        _time_slider.value = play_duration;
        double mp4_duration = 0.0;
        @synchronized (self) {
            mp4_duration = _context.mp4_duration;
        }
        _left_time_lbl.text = [self conver_hms_from_int:play_duration];;
        _right_time_lbl.text = [self conver_hms_from_int:(mp4_duration-play_duration)];
    });
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}









@end
