//
//  MP4_Player_View_V.m
//
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import "MP4_Player_View_V.h"
#import "Time_Progress_View.h"
#import "MP4_Pro_Def.h"
#import "Navigation_View.h"
#import "Player_Setting_Tool_View.h"
#import "MP4_OP_View.h"
#import "MP4_Time_Display_view.h"
#import "MP4_Display_Time_Set_View.h"
#import "Background_Image_View.h"

@interface MP4_Player_View_V ()

@property (nonatomic, strong) Navigation_View *nav_view;

@property (nonatomic, strong) MP4_Display_Time_Set_View *mdtsv;

@property (nonatomic, strong) MP4_OP_View *mov_view;

@property (nonatomic, weak) MP4_Player_View_Controller_Context *context;

@property (nonatomic, strong) Background_Image_View *background_image_view;

@end

@implementation MP4_Player_View_V

- (instancetype)init_with_context: (MP4_Player_View_Controller_Context *)context frame: (CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        @synchronized (self) {
            _context = context;
        }
        [self add_ui];
    }
    return self;
}

- (void)add_ui
{
    [self add_background_image_view];
    [self add_nav_view];
    [self add_mdtsv];
    [self add_mov_view];
}


- (void)add_nav_view
{
    if (KIsiPhoneX) {
        _nav_view = [[Navigation_View alloc]initWithFrame:CGRectMake(0.0, 0.0, self.bounds.size.width, 44.0+35.0) context:_context];
    } else {
        _nav_view = [[Navigation_View alloc]initWithFrame:CGRectMake(0.0, 0.0, self.bounds.size.width, 64.0) context:_context];
    }
    [self addSubview:_nav_view];
}

- (void)add_mdtsv
{
    _mdtsv = [[MP4_Display_Time_Set_View alloc]init_with_frame:CGRectMake(0.0, 0.0, self.bounds.size.width, self.bounds.size.width/16.0*9.0+50.0) context:_context];
    _mdtsv.center = CGPointMake(self.bounds.size.width/2.0, self.bounds.size.height/2.0);
    [self addSubview:_mdtsv];
}

- (void)add_mov_view
{
    if (KIsiPhoneX) {
        _mov_view = [[MP4_OP_View alloc]init_with_frame:CGRectMake(0.0, self.bounds.size.height-64.0-15.0, self.bounds.size.width, 64.0) context:_context];
    } else {
        _mov_view = [[MP4_OP_View alloc]init_with_frame:CGRectMake(0.0, self.bounds.size.height-64.0, self.bounds.size.width, 64.0) context:_context];
    }
    [self addSubview:_mov_view];
}

- (void)add_background_image_view
{
    _background_image_view = [[Background_Image_View alloc]init_with_frame:self.bounds context:_context];
    [self addSubview:_background_image_view];
}

@end
