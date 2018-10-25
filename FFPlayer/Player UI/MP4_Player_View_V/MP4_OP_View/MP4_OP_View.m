//
//  MP4_OP_View.m
//
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import "MP4_OP_View.h"

@interface MP4_OP_View ()

@property (nonatomic, strong) UIButton *last_but;

@property (nonatomic, strong) UIButton *pause_but;

@property (nonatomic, strong) UIButton *next_but;

@property (nonatomic, strong) UILabel *last_lbl;

@property (nonatomic, strong) UILabel *pause_lbl;

@property (nonatomic, strong) UILabel *next_lbl;

@property (nonatomic, weak) MP4_Player_View_Controller_Context *context;

@end

@implementation MP4_OP_View

- (instancetype)init_with_frame: (CGRect)frame
                        context: (MP4_Player_View_Controller_Context *)context

{
    self = [super initWithFrame:frame];
    if (self) {
        @synchronized (self) {
            _context = context;
        }
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(will_resign_active:) name:UIApplicationWillResignActiveNotification object:nil];
        self.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.6];
        [self add_ui];
    }
    return self;
}

- (void)will_resign_active: (NSNotification *)noti
{
    [_pause_but setImage:[UIImage imageNamed:@"btn_video_play_gray.png"] forState:UIControlStateNormal];
    [self post_pause_notification:YES];
}


- (void)add_ui
{
    [self add_pause_but];
    [self add_last_but];
    [self add_next_but];
}

- (void)add_pause_but
{
    _pause_but = [[UIButton alloc]initWithFrame:CGRectMake(0.0, 0.0, 40.0, 40.0)];
    _pause_but.center = CGPointMake(self.bounds.size.width/2.0, self.bounds.size.height/2.0);
    
    BOOL is_pause;
    @synchronized (self) {
        is_pause = _context.is_pause;
    }
    if (!is_pause) {
        [_pause_but setImage:[UIImage imageNamed:@"btn_video_pause_gray.png"] forState:UIControlStateNormal];
    } else {
        [_pause_but setImage:[UIImage imageNamed:@"btn_video_play_gray.png"] forState:UIControlStateNormal];
    }
    [_pause_but addTarget:self action:@selector(pause:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_pause_but];
}

- (void)add_last_but
{
    _last_but = [[UIButton alloc]initWithFrame:CGRectMake(0.0, 0.0, 40.0, 40.0)];
    _last_but.center = CGPointMake(self.frame.size.width/3.0, _pause_but.center.y);
    [_last_but setImage:[UIImage imageNamed:@"btn_video_up_gray.png"] forState:UIControlStateNormal];
    [_last_but addTarget:self action:@selector(last:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_last_but];
}

- (void)add_next_but
{
    _next_but = [[UIButton alloc]initWithFrame:CGRectMake(0.0, 0.0, 40.0, 40.0)];
    _next_but.center = CGPointMake(self.frame.size.width/3.0*2.0, _pause_but.center.y);
    [_next_but setImage:[UIImage imageNamed:@"btn_video_next_gray.png"] forState:UIControlStateNormal];
    [_next_but addTarget:self action:@selector(next:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_next_but];
}

- (void)last: (UIButton *)sender
{
    sender.enabled = NO;
    [self post_last_nofication];
    sender.enabled = YES;
}

- (void)next: (UIButton *)sender
{
    sender.enabled = NO;
    [self post_next_nofication];
    sender.enabled = YES;
}

- (void)pause: (UIButton *)sender
{
    sender.enabled = NO;
    BOOL is_pause = NO;
    @synchronized (self) {
        is_pause = _context.is_pause;
    }
    is_pause = !is_pause;
    if (!is_pause) {
        [_pause_but setImage:[UIImage imageNamed:@"btn_video_pause_gray.png"] forState:UIControlStateNormal];
    } else {
        [_pause_but setImage:[UIImage imageNamed:@"btn_video_play_gray.png"] forState:UIControlStateNormal];
    }
    [self post_pause_notification:is_pause];
    sender.enabled = YES;
}

- (void)post_pause_notification: (BOOL)is_pause
{
    NSString *mp4_file_name = nil;
    @synchronized (self) {
        mp4_file_name = _context.mp4_file_name;
    }
    NSDictionary *dict = @{@"mp4_file_name":mp4_file_name, @"is_pause":[NSNumber numberWithBool:is_pause]};
    [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Player_View_Controller_Pause_Notice object:[dict copy]];
}

- (void)post_next_nofication
{
    NSString *mp4_file_name = nil;
    @synchronized (self) {
        mp4_file_name = _context.mp4_file_name;
    }
    NSDictionary *dict = @{@"mp4_file_name":mp4_file_name};
    [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Player_View_Controller_Next_Notice object:[dict copy]];
}

- (void)post_last_nofication
{
    NSString *mp4_file_name = nil;
    @synchronized (self) {
        mp4_file_name = _context.mp4_file_name;
    }
    NSDictionary *dict = @{@"mp4_file_name":mp4_file_name};
    [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Player_View_Controller_Last_Notice object:[dict copy]];
}


@end
