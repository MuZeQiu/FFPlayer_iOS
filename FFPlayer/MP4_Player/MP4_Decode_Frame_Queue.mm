//
//  MP4_Decode_Frame_Queue.m
//  
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import "MP4_Decode_Frame_Queue.h"

@interface MP4_Decode_Frame_Queue ()

@end

@implementation MP4_Decode_Frame_Queue

- (instancetype)init
{
    self = [super init];
    if (self) {
        _decode_frame_queue = [[NSMutableArray alloc]init];
        _frame_time_queue = [[NSMutableArray alloc]init];
        _queue_id = 0;
    }
    return self;
}

- (void)generate_queue
{
    _decode_frame_queue = [[NSMutableArray alloc]init];
    _frame_time_queue = [[NSMutableArray alloc]init];
}

@end
