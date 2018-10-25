//
//  MP4_Nomal_Display_View.h
//
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Time_Progress_View;

@interface MP4_Nomal_Display_View : UIImageView

- (instancetype)init_with_frame: (CGRect)frame
                            tpv: (Time_Progress_View *)tpv
                            dbt: (dispatch_block_t)dbt;

@end
