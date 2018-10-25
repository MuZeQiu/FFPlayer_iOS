//
//  MP4_Display_Time_Set_View.m
//
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import "MP4_Display_Time_Set_View.h"
#import "MP4_Time_Display_view.h"
#import "Player_Setting_Tool_View.h"

@interface MP4_Display_Time_Set_View ()

@property (nonatomic, strong) MP4_Time_Display_view *mtdv;

@property (nonatomic, strong) Player_Setting_Tool_View *pstv;

@property (nonatomic, weak) MP4_Player_View_Controller_Context *context;

@end

@implementation MP4_Display_Time_Set_View

- (instancetype)init_with_frame: (CGRect)frame
                        context: (MP4_Player_View_Controller_Context *)context
{
    self = [super initWithFrame:frame];
    if (self) {
        @synchronized (self) {
            _context = context;
        }
        [self add_mtdv];
        [self add_pstv];
    }
    return self;
}

- (void)add_mtdv
{
    _mtdv = [[MP4_Time_Display_view alloc]init_with_frame:CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.width/16.0*9.0) context:_context];
    [self addSubview:_mtdv];
}

- (void)add_pstv
{
    _pstv = [[Player_Setting_Tool_View alloc]init_with_context:_context
                                                         frame:CGRectMake(0.0, _mtdv.frame.size.height, self.frame.size.width, 50.0)];
    [self addSubview:_pstv];
}

@end
