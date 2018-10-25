//
//  MP4_Time_Display_view.m
//
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import "MP4_Time_Display_view.h"
#import "MP4_Nomal_Display_View.h"
#import "Time_Progress_View.h"
#import "AudioDrawView.h"

@interface MP4_Time_Display_view ()

@property (nonatomic, weak) MP4_Player_View_Controller_Context *context;

@property (nonatomic, strong) MP4_Nomal_Display_View *mndv;

@property (nonatomic, strong) AudioDrawView *adv;

@property (nonatomic, strong) Time_Progress_View *tpv;

@end

@implementation MP4_Time_Display_view

- (instancetype)init_with_frame: (CGRect)frame
                            context: (MP4_Player_View_Controller_Context *)context
{
    self = [super initWithFrame:frame];
    if (self) {
        @synchronized (self) {
            _context = context;
        }
        self.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.6];
        [self add_tpv];
        [self add_display_view];
        [self add_adv];
        [self addSubview:_tpv];
        [self add_notice];
    }
    return self;
}

- (void)add_tpv
{
    _tpv = [[Time_Progress_View alloc]init_with_frame:CGRectMake(0.0, self.bounds.size.height-40.0, self.bounds.size.width, 40.0)context:_context];
}

- (void)add_display_view
{
    BOOL is_mp3_file = NO, is_exist_video_track = NO;
    @synchronized (self) {
        is_mp3_file = _context.is_mp3_file;
        is_exist_video_track = _context.is_exist_video_track;
    }
    if (!is_mp3_file && is_exist_video_track) {
        _mndv = [[MP4_Nomal_Display_View alloc]init_with_frame:self.bounds tpv:_tpv dbt:^{
        }];
        [self addSubview:_mndv];
        UIImage *video_frame_nomal = nil;
        @synchronized (self) {
            video_frame_nomal = [_context.video_frame copy];
        }
        _mndv.image = video_frame_nomal;
    }
}

- (void)add_adv
{
    BOOL is_mp3_file = NO, is_exist_video_track = NO;
    @synchronized (self) {
        is_mp3_file = _context.is_mp3_file;
        is_exist_video_track = _context.is_exist_video_track;
    }
    if (is_mp3_file) {
        _adv = [[AudioDrawView alloc]init_with_frame:self.bounds context:_context histogram_height:200];
        [self addSubview:_adv];
        __weak MP4_Time_Display_view *ws = self;
        _adv.tap_block = ^{
            ws.tpv.hidden = !ws.tpv.hidden;
        };
    }
}

- (void)add_notice
{
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(display_next_video:) name:KMP4_Player_View_Controller_Nomal_Display_Notice object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(receive_cover_for_updata:) name:KMP4_Player_View_Controller_Cover_Updata_Notice object:nil];
}

- (void)receive_cover_for_updata: (NSNotification *)noti
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        UIImage *video_frame = [noti.object copy];
        dispatch_async(dispatch_get_main_queue(), ^{
            _mndv.image = [video_frame copy];
        });
    });
}

- (void)display_next_video: (NSNotification *)noti
{
    NSDictionary *dict = noti.object;
    NSString *mp4_file_path = [dict[@"mp4_file_path"] copy];
    NSString *mp4_file_path_;
    @synchronized (self) {
        mp4_file_path_ = [_context.mp4_file_path copy];
    }
    if (![mp4_file_path isEqualToString:mp4_file_path_]) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImage *video_frame = [dict[@"video_frame_nomal"] copy];
        _mndv.image = [video_frame copy];
    });
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
