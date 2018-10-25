//
//  MP4_Analysis.h
//
//  Copyright © 2017年 邱沐泽. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MP4_Decode_Frame_Queue.h"

@interface MP4_Analysis : NSObject

+ (instancetype)share_mp4_player_with_file_path: (NSString *)file_path;

- (void)start;

@end






