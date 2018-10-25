//
//  Navigation_View.m
//
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import "Navigation_View.h"
#import "AnimationLabel.h"

@interface Navigation_View ()

@property (nonatomic, strong) UIButton *back_but;

@property (nonatomic, strong) UIButton *info_but;

@property (nonatomic, strong) AnimationLabel *title_lbl;

@property (nonatomic, weak) MP4_Player_View_Controller_Context *context;

@end

@implementation Navigation_View

- (instancetype)initWithFrame: (CGRect)frame
                      context: (MP4_Player_View_Controller_Context *)context
{
    self = [super initWithFrame:frame];
    if (self) {
        @synchronized (self) {
            _context = context;
        }
        self.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.6];
        [self add_ui];
    }
    return self;
}

- (void)add_ui
{
    [self add_back_but];
    [self add_title_lbl];
}

- (void)add_back_but
{
    _back_but = [[UIButton alloc]initWithFrame:CGRectMake(0.0, 0.0, 35.0, 35.0)];
    _back_but.center = CGPointMake(10.0+35.0/2.0, 20.0+44.0/2.0);
    [_back_but setImage:[UIImage imageNamed:@"btn_back.png"] forState:UIControlStateNormal];
    [_back_but addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_back_but];
}

- (void)add_title_lbl
{
    _title_lbl = [[AnimationLabel alloc]initWithFrame:CGRectMake(10.0+35.0+10.0, 20.0+(44.0-35.0)/2.0, self.bounds.size.width-(10.0+35.0+10.0)*2, 35.0)];
    NSString *mp4_file_name = nil;
    @synchronized (self) {
        mp4_file_name = _context.mp4_file_name;
    }
    [_title_lbl setText:mp4_file_name];
    [self addSubview:_title_lbl];
}

- (void)back: (UIButton *)sender
{
    sender.enabled = NO;
    [self post_exit_notice];
    sender.enabled = YES;
}

- (void)post_exit_notice
{
    NSString *mp4_file_name = nil;
    @synchronized (self) {
        mp4_file_name = _context.mp4_file_name;
    }
    NSDictionary *dict = @{@"mp4_file_name":mp4_file_name};
    [[NSNotificationCenter defaultCenter]postNotificationName:KMP4_Player_View_Controller_Exit_Notice object:[dict copy]];
}

@end
