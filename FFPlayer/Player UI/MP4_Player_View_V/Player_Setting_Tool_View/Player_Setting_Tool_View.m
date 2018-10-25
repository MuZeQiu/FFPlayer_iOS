//
//  Player_Setting_Tool_View.m
//
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import "Player_Setting_Tool_View.h"

@interface Player_Setting_Tool_View ()

@property (nonatomic, weak) MP4_Player_View_Controller_Context *context;

@property (nonatomic, strong) UIButton *screen_shot_but;
@property (nonatomic, strong) UIButton *sound_ctl_but;
@property (nonatomic, strong) UIButton *full_screen_but;

@end

@implementation Player_Setting_Tool_View

- (instancetype)init_with_context: (MP4_Player_View_Controller_Context *)context
                            frame: (CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        @synchronized (self) {
            _context = context;
        }
        _screen_shot_but = nil;
        _sound_ctl_but = nil;
        _full_screen_but = nil;
        self.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.6];
        [self add_ui];
    }
    return self;
}

- (void)add_ui
{
    [self add_screen_shot_but];
    [self add_sound_ctl_but];
    [self add_full_screen_view];
}

- (double)tool_but_width
{
    return (self.frame.size.width-4*5)/3;
}

- (double)tool_but_height
{
    return self.frame.size.height - 10.0;
}

- (void)add_screen_shot_but
{
    _screen_shot_but = [[UIButton alloc]initWithFrame:CGRectMake(5.0, 5.0, [self tool_but_width], [self tool_but_height])];
    [_screen_shot_but setImage:[UIImage imageNamed:@"btn_jietu_gray.png"] forState:UIControlStateNormal];
    [_screen_shot_but addTarget:self action:@selector(shot:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_screen_shot_but];
}

- (void)add_sound_ctl_but
{
    _sound_ctl_but = [[UIButton alloc]initWithFrame:CGRectMake(_screen_shot_but.frame.origin.x+_screen_shot_but.frame.size.width+5.0, 5.0, [self tool_but_width], [self tool_but_height])];
    
    BOOL is_sound;
    @synchronized (self) {
        is_sound = _context.is_sound;
    }
    
    if (is_sound) {
        [_sound_ctl_but setImage:[UIImage imageNamed:@"btn_voice_open.png"] forState:UIControlStateNormal];
    } else {
        [_sound_ctl_but setImage:[UIImage imageNamed:@"btn_voice_close.png"] forState:UIControlStateNormal];
    }
    
    [_sound_ctl_but addTarget:self action:@selector(ctl_sound:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_sound_ctl_but];
}

- (void)add_full_screen_view
{
    _full_screen_but = [[UIButton alloc]initWithFrame:CGRectMake(_sound_ctl_but.frame.origin.x+_sound_ctl_but.frame.size.width+5.0, 5.0, [self tool_but_width], [self tool_but_height])];
    [_full_screen_but setImage:[UIImage imageNamed:@"btn_fd.png"] forState:UIControlStateNormal];
    [_full_screen_but addTarget:self action:@selector(full:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_full_screen_but];
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

- (void)ctl_sound: (UIButton *)sender
{
    sender.enabled = NO;
    BOOL is_sound;
    @synchronized (self) {
        is_sound = _context.is_sound;
    }
    is_sound = !is_sound;
    if (is_sound) {
         [_sound_ctl_but setImage:[UIImage imageNamed:@"btn_voice_open.png"] forState:UIControlStateNormal];
    }
    else {
         [_sound_ctl_but setImage:[UIImage imageNamed:@"btn_voice_close.png"] forState:UIControlStateNormal];
    }
    [self post_ctl_sound_notification];
    sender.enabled = YES;
}
- (void)post_ctl_sound_notification
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
    [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Player_View_Controller_Full_Screen_Notice object:[dict copy]];
}




@end
