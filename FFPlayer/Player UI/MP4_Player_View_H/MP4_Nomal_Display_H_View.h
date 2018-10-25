//
//  MP4_Nomal_Display_H_View.h
//
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MP4_Pro_Def.h"
#import "MP4_Player_View_Controller_Context.h"

@interface MP4_Nomal_Display_H_View : UIImageView

- (instancetype)init_with_frame: (CGRect)frame
                        context: (MP4_Player_View_Controller_Context *)context
                    touch_block: (dispatch_block_t)touch_block;

@end
