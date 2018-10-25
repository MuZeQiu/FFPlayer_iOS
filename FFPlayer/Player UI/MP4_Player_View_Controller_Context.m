//
//  MP4_Player_View_Controller_Context.m
//
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import "MP4_Player_View_Controller_Context.h"

@implementation MP4_Player_View_Controller_Context

static MP4_Player_View_Controller_Context *mp4_player_context = nil;

+ (instancetype)share_mp4_player_context
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mp4_player_context = [[MP4_Player_View_Controller_Context alloc]init];
    });
    return mp4_player_context;
}

+ (id)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        if(mp4_player_context == nil) {
            mp4_player_context = [super allocWithZone:zone];
        }
    });
    return mp4_player_context;
}

- (id)copy
{
    return self;
}

- (id)mutableCopy
{
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"memeory address:%p",self];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

@end
