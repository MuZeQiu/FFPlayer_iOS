//
//  AudioDrawView.m
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import "AudioDrawView.h"
#import "MP4_Pro_Def.h"
#import "MP4_Player_View_Controller_Context.h"

@interface AudioDrawView ()

@property (nonatomic, copy) NSArray *audio_point_array;

@property (nonatomic, weak) MP4_Player_View_Controller_Context *mpvcc;

@property (nonatomic) BOOL is_updata;

@property (nonatomic, strong) UIImageView *image_view;

@property (nonatomic) double histogram_height;

@end

@implementation AudioDrawView

- (instancetype)init_with_frame: (CGRect)frame
                        context: (MP4_Player_View_Controller_Context *)context
               histogram_height: (double)histogram_height
{
    self = [super initWithFrame:frame];
    if (self) {
        _is_updata = YES;
        @synchronized (self) {
            _mpvcc = context;
        }
        _histogram_height = histogram_height;
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(display_next_audio:) name:KMP4_Player_View_Controller_Display_Audio_Notice object:nil];
        self.backgroundColor = [UIColor clearColor];
        self.transform = CGAffineTransformMakeRotation(M_PI);
        NSData *audio_frame;
        @synchronized (self) {
            audio_frame = [_mpvcc.audio_frame copy];
        }
        if (audio_frame) {
            NSMutableArray *array = [NSMutableArray array];
            for (int i = 0; i < 30; i++) {
                int num = *((unsigned char *)audio_frame.bytes+500/30*i)+_histogram_height;
                [array addObject:@(num)];
            }
            _audio_point_array = [array copy];
            [self setNeedsDisplay];
        }
        else {
            NSMutableArray *array = [NSMutableArray array];
            for (int i = 0; i < 30; i++) {
                int num = 50+_histogram_height;
                [array addObject:@(num)];
            }
            _audio_point_array = [array copy];
            [self setNeedsDisplay];
        }
        [self add_tap_ges];
    }
    return self;
}

- (void)display_next_audio: (NSNotification *)noti
{
    @synchronized (self) {
        if (!_is_updata) {
            return;
        }
        _is_updata = NO;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
        @synchronized (self) {
            _is_updata = YES;
        }
    });
    NSDictionary *dict = [noti.object copy];
    NSString *mp4_file_path = [dict[@"mp4_file_path"] copy];
    NSString *mp4_file_path_;
    @synchronized (self) {
        mp4_file_path_ = [_mpvcc.mp4_file_path copy];
    }
    if (![mp4_file_path isEqualToString:mp4_file_path_]) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        NSData *audio_frame = [(NSData *)dict[@"audio_frame"] copy];
        NSMutableArray *array = [NSMutableArray array];
        for (int i = 0; i < 30; i++) {
            int num = *((unsigned char *)audio_frame.bytes+500/30*i)+_histogram_height;
            [array addObject:@(num)];
        }
        [self setAudio_point_array:[array copy]];
    });
}


- (void)setAudio_point_array:(NSArray *)audio_point_array
{
    _audio_point_array = [audio_point_array copy];
    [self setNeedsDisplay];
}

- (void)add_tap_ges
{
    UITapGestureRecognizer *tap_ges = [[UITapGestureRecognizer alloc]initWithTarget:self     action:@selector(tap_action:)];
    tap_ges.numberOfTapsRequired = 1;
    tap_ges.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:tap_ges];
}

- (void)tap_action: (UITapGestureRecognizer *)tap
{
    if (_tap_block) {
        _tap_block();
    }
}

- (void)drawRect:(CGRect)rect {
    if (!_audio_point_array || _audio_point_array.count==0) {
        return;
    }
    CGContextRef context = UIGraphicsGetCurrentContext();
    for (int i = 0; i < _audio_point_array.count; i++) {
        UIColor* gradientColor = [UIColor colorWithRed: 0.383 green: 0.822 blue: 0.951 alpha: 1];
        UIColor* gradientColor2 = [UIColor colorWithRed: 0.689 green: 0.319 blue: 0.766 alpha: 1];
        CGFloat gradientLocations[] = {0, 1};
        CGGradientRef gradient = CGGradientCreateWithColors(NULL, (__bridge CFArrayRef)@[(id)gradientColor.CGColor, (id)gradientColor2.CGColor], gradientLocations);

        UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: CGRectMake((double)rect.size.width/(double)_audio_point_array.count*i, 0.0, (double)rect.size.width/(double)_audio_point_array.count/2.0, (double)[_audio_point_array[i] intValue]/[UIScreen mainScreen].bounds.size.height*rect.size.height )];
        CGContextSaveGState(context);
        [rectanglePath addClip];
        CGContextDrawLinearGradient(context, gradient, CGPointMake((double)rect.size.width/(double)_audio_point_array.count*i, 0.0), CGPointMake((double)rect.size.width/(double)_audio_point_array.count*i, 0.0+(double)[_audio_point_array[i] intValue]/[UIScreen mainScreen].bounds.size.height*rect.size.height), kNilOptions);
        CGContextRestoreGState(context);
        CGGradientRelease(gradient);
    }
    UIGraphicsEndImageContext();
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
