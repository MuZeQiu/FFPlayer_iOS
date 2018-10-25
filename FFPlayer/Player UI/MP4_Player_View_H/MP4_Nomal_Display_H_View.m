//
//  MP4_Nomal_Display_H_View.m
//
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import "MP4_Nomal_Display_H_View.h"

@interface MP4_Nomal_Display_H_View ()

@property (nonatomic, weak) MP4_Player_View_Controller_Context *context;

@property (nonatomic, copy) dispatch_block_t touch_block;

@property (nonatomic, strong) UILabel *tip_label;

@end

@implementation MP4_Nomal_Display_H_View

- (instancetype)init_with_frame: (CGRect)frame
                        context: (MP4_Player_View_Controller_Context *)context
                    touch_block: (dispatch_block_t)touch_block
{
    self = [super initWithFrame:frame];
    if (self) {
        @synchronized (self) {
            _context = context;
        }
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(show_tip:) name:KMP4_Player_View_Controller_Tip_Notice object:nil];
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor clearColor];
        _touch_block = touch_block;
        [self add_tap_ges];
        [self add_tip_label];
    }
    return self;
}

- (void)add_tap_ges
{
    UITapGestureRecognizer *tap_ges = [[UITapGestureRecognizer alloc]initWithTarget:self     action:@selector(tap_action:)];
    tap_ges.numberOfTapsRequired = 1;
    tap_ges.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:tap_ges];
}

- (void)tap_action: (UITapGestureRecognizer *)tap
{
    _touch_block();
}

- (void)add_tip_label
{
    _tip_label = [[UILabel alloc]initWithFrame:CGRectMake(0.0, 0.0, 200.0, 30.0)];
    _tip_label.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
    _tip_label.textAlignment = NSTextAlignmentCenter;
    _tip_label.font = [UIFont systemFontOfSize:15.0];
    _tip_label.textColor = [UIColor whiteColor];
    _tip_label.layer.cornerRadius = 3.0;
    [self addSubview:_tip_label];
    _tip_label.hidden = YES;
}

- (void)show_tip: (NSNotification *)noti
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *tip_str = [noti.object copy];
        _tip_label.text = tip_str;
        CGSize titleSize = [tip_str sizeWithFont:_tip_label.font constrainedToSize:CGSizeMake(MAXFLOAT, _tip_label.frame.size.height)];
        _tip_label.frame = CGRectMake(0.0, 0.0, titleSize.width+10.0, titleSize.height+5.0);
        _tip_label.center = CGPointMake(self.bounds.size.width/2.0, self.bounds.size.height/2.0);
        _tip_label.hidden = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                _tip_label.hidden = YES;
            });
        });
    });
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
