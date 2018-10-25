//
//  MP4_Player_View_H.m
//
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import "MP4_Player_View_H.h"
#import "MP4_Player_View_Controller_Context.h"
#import "MP4_OP_H_View.h"
#import "Bottom_Tool_View.h"
#import "MP4_Nomal_Display_H_View.h"
#import "AudioDrawView.h"

@interface MP4_Player_View_H ()<UIAlertViewDelegate>

@property (nonatomic, weak) MP4_Player_View_Controller_Context *context;

@property (nonatomic, strong) MP4_OP_H_View *mohv;
@property (nonatomic, strong) Bottom_Tool_View *btv;
@property (nonatomic, strong) MP4_Nomal_Display_H_View *mndhv;
@property (nonatomic, strong) UIImageView *background_image_view;

@property (nonatomic, strong) AudioDrawView *adv;

@end

@implementation MP4_Player_View_H

- (instancetype)init_with_context: (MP4_Player_View_Controller_Context *)context
                            frame: (CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        @synchronized (self) {
            _context = context;
        }
        self.backgroundColor = [UIColor whiteColor];
        [self add_obser];
        [self add_ui];
    }
    return self;
}

- (void)add_ui
{
    [self add_background_image_view];
    BOOL is_mp3_file = NO, is_exist_video_track = NO;
    @synchronized (self) {
        is_mp3_file = _context.is_mp3_file;
        is_exist_video_track = _context.is_exist_video_track;
    }
    if (!is_mp3_file && is_exist_video_track) {
        [self add_display_view];
    } else {
        [self add_adv];
    }
    [self add_btv];
    [self add_mohv];
}

- (void)add_display_view
{
    __weak MP4_Player_View_H *mpvh = self;
    _mndhv = [[MP4_Nomal_Display_H_View alloc]init_with_frame:CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height) context:_context touch_block:^{
        [mpvh show_ctler];
    }];
    [self addSubview:_mndhv];
    UIImage *video_frame_nomal = nil;
    @synchronized (self) {
        video_frame_nomal = [_context.video_frame copy];
    }
    _mndhv.image = video_frame_nomal;
}

- (void)show_ctler
{
    _mohv.hidden = !_mohv.hidden;
    _btv.hidden = !_btv.hidden;
}

- (void)add_btv
{
    if (KIsiPhoneX) {
        _btv = [[Bottom_Tool_View alloc]init_with_frame:CGRectMake(35.0, self.frame.size.height-40.0, self.frame.size.width-70.0, 40.0) context:_context];
    } else {
        _btv = [[Bottom_Tool_View alloc]init_with_frame:CGRectMake(0.0, self.frame.size.height-40.0, self.frame.size.width, 40.0) context:_context];
    }
    [self addSubview:_btv];
}

- (void)add_mohv
{
    _mohv = [[MP4_OP_H_View alloc]init_with_frame:CGRectMake(0.0, 0.0, 25.0+45.0+10.0+60.0+10.0+45.0+25.0, 70.0) context:_context];
    _mohv.center = CGPointMake(self.frame.size.width/2.0, _btv.frame.origin.y-_mohv.frame.size.height/2.0-10.0);
    [self addSubview:_mohv];
}

- (void)add_obser
{
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(display_next_video:) name:KMP4_Player_View_Controller_Nomal_Display_Notice object:nil];
    
}

- (void)display_next_video: (NSNotification *)noti
{
    NSDictionary *dict = noti.object;
    NSString *mp4_file_path = dict[@"mp4_file_path"];
    NSString *mp4_file_path_;
    @synchronized (self) {
        mp4_file_path_ = _context.mp4_file_path;
    }
    if (![mp4_file_path isEqualToString:mp4_file_path_]) {
        return;
    }

    __block id video_frame;
    dispatch_async(dispatch_get_main_queue(), ^{
        video_frame = dict[@"video_frame_nomal"];
        _mndhv.image = video_frame;
    });
}

- (void)add_background_image_view
{
    _background_image_view = [[UIImageView alloc]initWithFrame:self.bounds];
    [self addSubview:_background_image_view];
    @synchronized (self) {
        _background_image_view.image = [_context.player_cover copy];
    }
    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    effectView.frame = _background_image_view.bounds;
    [_background_image_view addSubview:effectView];
}

- (void)add_adv
{
    _adv = [[AudioDrawView alloc]init_with_frame:self.bounds context:_context histogram_height:100.0];
    [self addSubview:_adv];
    __weak MP4_Player_View_H *ws = self;
    _adv.tap_block = ^{
        [ws show_ctler];
    };
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}











@end
