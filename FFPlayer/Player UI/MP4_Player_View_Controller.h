//
//  MP4_Player_View_Controller.h
//
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MP4_Pro_Def.h"
#import "MP4_Player_View_Controller_Context.h"

@class MP4_Player_View_V, MP4_Player_View_H;

@interface MP4_Player_View_Controller : UIViewController

@property (nonatomic, strong) MP4_Player_View_V *mpvv_view;
@property (nonatomic, strong) MP4_Player_View_H *mpvh_view;

- (instancetype)init_with_context: (MP4_Player_View_Controller_Context *)context;

@end
