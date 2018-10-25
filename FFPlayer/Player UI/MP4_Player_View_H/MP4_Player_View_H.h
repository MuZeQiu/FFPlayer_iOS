//
//  MP4_Player_View_H.h
//
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MP4_Pro_Def.h"

@class MP4_Player_View_Controller_Context;

@interface MP4_Player_View_H : UIView

- (instancetype)init_with_context: (MP4_Player_View_Controller_Context *)context
frame: (CGRect)frame;

@end
