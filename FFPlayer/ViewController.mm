//
//  ViewController.m
//  FF_Pro
//
//  Created by 邱沐泽 on 2018/1/6.
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import "ViewController.h"
#import "MP4_Analysis.h"
#import <ImageIO/ImageIO.h>
#import <ImageIO/CGImageSource.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreFoundation/CoreFoundation.h>
#import "id3v2lib.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *but = [[UIButton alloc]initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)];
    [self.view addSubview:but];
    [but setTitle:@"开始" forState: UIControlStateNormal];
    [but setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [but addTarget:self action:@selector(start:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)start: (id)sender
{
    NSString *mp4_file_path = [[NSBundle mainBundle]pathForResource:@"" ofType:@"mp4"];
    [[MP4_Analysis share_mp4_player_with_file_path:mp4_file_path] start];
}

- (BOOL)shouldAutorotate
{
    return YES;
}




@end
