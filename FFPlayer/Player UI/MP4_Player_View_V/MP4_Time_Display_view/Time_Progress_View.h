//
//  Time_Progress_View.h
//
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MP4_Pro_Def.h"
#import "MP4_Player_View_Controller_Context.h"

@interface Time_Progress_View : UIView

@property (nonatomic, strong, readonly) UISlider *time_slider;

- (instancetype)init_with_frame: (CGRect)frame
                        context: (MP4_Player_View_Controller_Context *)context;

- (void)set_play_progress;

@end
