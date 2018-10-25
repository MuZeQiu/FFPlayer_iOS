//
//  MP4_Decode_Frame_Queue.h
//
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MP4_Decode_Frame_Queue : NSObject

@property (atomic, strong)NSMutableArray *decode_frame_queue;

@property (atomic, strong)NSMutableArray *frame_time_queue;

@property (nonatomic)int queue_id;

- (void)generate_queue;

@end
