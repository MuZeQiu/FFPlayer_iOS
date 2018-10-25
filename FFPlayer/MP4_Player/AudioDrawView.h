//
//  AudioDrawView.h
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MP4_Player_View_Controller_Context;

@interface AudioDrawView : UIView

- (instancetype)init_with_frame: (CGRect)frame
                        context: (MP4_Player_View_Controller_Context *)context
               histogram_height: (double)histogram_height;

@property (nonatomic, copy) dispatch_block_t tap_block;

@end
