//
//  Background_Image_View.m
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import "Background_Image_View.h"
#import "MP4_Player_View_Controller_Context.h"
#import <ImageIO/ImageIO.h>

@interface Background_Image_View ()

@property (nonatomic, weak) MP4_Player_View_Controller_Context *mpvcc;

@property (nonatomic, strong) UIImageView *old_image_view;

@property (nonatomic, copy) UIImage *image_for_updata;

@end

@implementation Background_Image_View

- (instancetype)init_with_frame:(CGRect)frame context: (MP4_Player_View_Controller_Context *)context
{
    self = [super initWithFrame:frame];
    if (self) {
        @synchronized (self) {
            _mpvcc = context;
        }
        [self add_notice];
        [self add_old_image_view];
        [self add_blur_effect];
        @synchronized (self) {
            if (_mpvcc.video_frame) {
                self.image = [_mpvcc.video_frame copy];
            } else {
                self.image = [_mpvcc.player_cover copy];
            }
        }
        [self updata_loop];
    }
    return self;
}

- (void)add_notice
{
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(receive_next_video:) name:KMP4_Player_View_Controller_Nomal_Display_Notice object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(receive_cover_for_updata:) name:KMP4_Player_View_Controller_Cover_Updata_Notice object:nil];
}

- (void)receive_next_video: (NSNotification *)noti
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSDictionary *dict = noti.object;
        NSString *mp4_file_path = [dict[@"mp4_file_path"] copy];
        NSString *mp4_file_path_;
        @synchronized (self) {
            mp4_file_path_ = [_mpvcc.mp4_file_path copy];
        }
        if (![mp4_file_path isEqualToString:mp4_file_path_]) {
            return;
        }
        UIImage *video_frame = [dict[@"video_frame_nomal"] copy];
        @synchronized (self) {
            _image_for_updata = [video_frame copy];
        }
    });
}

- (void)receive_cover_for_updata: (NSNotification *)noti
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        UIImage *video_frame = [noti.object copy];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.old_image_view.alpha = 0.0;
            self.old_image_view.image = [video_frame copy];
            [UIView animateWithDuration:1.0 animations:^{
                self.old_image_view.alpha = 1.0;
            }];
        });
    });
}

- (void)add_old_image_view
{
    _old_image_view = [[UIImageView alloc]initWithFrame:self.bounds];
    _old_image_view.backgroundColor = [UIColor clearColor];
    [self addSubview:_old_image_view];
}

- (void)add_blur_effect
{
    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    effectView.frame = self.bounds;
    [self addSubview:effectView];
}

- (void)updata_loop
{
    __weak Background_Image_View *biv = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (biv) {
            [NSThread sleepForTimeInterval:7.0];
            UIImage *image;
            @synchronized (biv) {
                image = [biv.image_for_updata copy];
            }
            if (image) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (biv.old_image_view.image) {
                        biv.image = [biv.old_image_view.image copy];
                    }
                    biv.old_image_view.alpha = 0.0;
                    biv.old_image_view.image = [image copy];
                    [UIView animateWithDuration:2.0 animations:^{
                        biv.old_image_view.alpha = 1.0;
                    }];
                });
            }
        }
    });
}

- (void)load_image_step_by_step: (UIImage *)taget_image
{
    __weak Background_Image_View *biv = self;
    UIImage *image = [taget_image copy];
    NSData *image_data = [UIImageJPEGRepresentation(image, 1.0) copy];
    int i = 1;
    while (biv) {
        @autoreleasepool {
            [NSThread sleepForTimeInterval:0.01];
            CGImageSourceRef isr = CGImageSourceCreateIncremental(NULL);
            if (i == 101) {
                CFRelease(isr);
                break;
            }
            NSData *sub_data = [[image_data subdataWithRange:(NSRange){0, [image_data length]/100*i}] copy];
            if (i == 100) {
                CGImageSourceUpdateData(isr, (__bridge CFDataRef)sub_data, YES);
            } else {
                CGImageSourceUpdateData(isr, (__bridge CFDataRef)sub_data, NO);
            }
            CGImageRef ir;
            if (i == 100) {
                ir = CGImageSourceCreateImageAtIndex(isr, 0.01*(double)99.999999, NULL);
            } else {
                ir = CGImageSourceCreateImageAtIndex(isr, 0.01*(double)i, NULL);
            }
            CFRelease(isr);
            UIImage *im = [[UIImage imageWithCGImage:ir] copy];
            CGImageRelease(ir);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (im) {
                    biv.old_image_view.image = [im copy];
                }
            });
            i++;
        }
    }
}

@end
