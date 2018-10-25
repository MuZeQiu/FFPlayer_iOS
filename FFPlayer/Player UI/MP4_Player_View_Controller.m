//
//  MP4_Player_View_Controller.m
//
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import "MP4_Player_View_Controller.h"
#import "MP4_Player_View_V.h"
#import "MP4_Player_View_H.h"


@interface MP4_Player_View_Controller ()

@property (nonatomic) UIDeviceOrientation orient;

@property (nonatomic, weak) MP4_Player_View_Controller_Context *context;

@end

@implementation MP4_Player_View_Controller

- (instancetype)init_with_context: (MP4_Player_View_Controller_Context *)context
{
    self = [super init];
    if (self) {
        @synchronized (self) {
            _context = context;
        }
        _mpvv_view = nil;
        _mpvh_view = nil;
    }
    return self;
}

- (void)add_mpvv_view
{
    _mpvv_view = [[MP4_Player_View_V alloc]init_with_context:_context frame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.view.bounds.size.height)];
    [self.view addSubview:_mpvv_view];
}

- (void)add_mpvh_view
{
    _mpvh_view = [[MP4_Player_View_H alloc]init_with_context:_context frame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.view.bounds.size.height)];
    [self.view addSubview:_mpvh_view];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _orient = [UIDevice currentDevice].orientation;
    if (_orient==UIDeviceOrientationLandscapeLeft || _orient==UIDeviceOrientationLandscapeRight) {
        [self add_mpvh_view];
    } else {
        [self add_mpvv_view];
    }
    
//    if (_orient == UIDeviceOrientationPortrait) {
//        [self add_mpvv_view];
//    } else if (_orient==UIDeviceOrientationLandscapeLeft || _orient==UIDeviceOrientationLandscapeRight) {
//        [self add_mpvh_view];
//    }
//    } else {
//        [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIDeviceOrientationPortrait] forKey:@"orientation"];
//    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

@end
