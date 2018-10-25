//
//  Time_Progress_View.m
//
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import "Time_Progress_View.h"

@interface Time_Progress_View ()

@property (nonatomic, strong) UILabel *left_time_lbl;

@property (nonatomic, strong) UISlider *time_slider;

@property (nonatomic, strong) UILabel *right_time_lbl;

@property (nonatomic, weak) MP4_Player_View_Controller_Context *context;

@end

@implementation Time_Progress_View

- (instancetype)init_with_frame: (CGRect)frame
                        context: (MP4_Player_View_Controller_Context *)context

{
    self = [super initWithFrame:frame];
    if(self) {
        @synchronized (self) {
            _context = context;
        }
        self.backgroundColor = [UIColor colorWithRed:0.0
                                               green:0.0
                                                blue:0.0
                                               alpha:0.6];
        [self add_ui];
        [self add_obser];
    }
    return self;
}

- (void)add_ui
{
    [self add_left_time_lbl];
    [self add_time_slider];
    [self add_right_lbl];
}

- (void)add_left_time_lbl
{
    _left_time_lbl = [[UILabel alloc]initWithFrame:CGRectMake(0.0, 0.0, 80.0, self.frame.size.height)];
    _left_time_lbl.textAlignment = NSTextAlignmentCenter;
    _left_time_lbl.textColor = [UIColor whiteColor];
    double play_duration = 0.0;
    @synchronized (self) {
        play_duration = _context.play_duration;
    }
    _left_time_lbl.text = [self conver_hms_from_int:(uint32_t)play_duration];
    [self addSubview:_left_time_lbl];
}

- (void)add_time_slider
{
    _time_slider = [[UISlider alloc]initWithFrame:CGRectMake(80.0+5.0, 0.0, self.frame.size.width - 170.0, self.frame.size.height)];
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

- (void)add_right_lbl
{
    _right_time_lbl = [[UILabel alloc]initWithFrame:CGRectMake(self.frame.size.width - 80.0, 0.0, 80.0, self.frame.size.height)];
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

- (void)slide_time: (UISlider *)sender
{
    double play_duration = sender.value;
    if (play_duration-_context.play_duration<1.0 && play_duration-_context.play_duration>-1.0) {
        return;
    }
    double mp4_duration = 0.0;
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
    @synchronized (self) {
        _time_slider.value = _context.play_duration;
    }
    double mp4_duration = 0.0;
    double play_duration = 0.0;
    @synchronized (self) {
        mp4_duration = _context.mp4_duration;
        play_duration = _context.play_duration;
    }
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
