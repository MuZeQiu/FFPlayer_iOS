//
//  AnimationLabel.m
//  Copyright © 2018年 邱沐泽. All rights reserved.
//

#import "AnimationLabel.h"

@interface AnimationLabel ()

@property (nonatomic, strong) UIScrollView *scroll_view;

@property (nonatomic, strong) UILabel *label;

@end

@implementation AnimationLabel

__weak AnimationLabel *al = nil;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        al = self;
    }
    return self;
}

- (void)add_scroll_view
{
    CGSize title_size = [_text sizeWithFont:[UIFont systemFontOfSize: 17.0] constrainedToSize:CGSizeMake(MAXFLOAT, self.frame.size.height)];
    
    if (title_size.width <= self.bounds.size.width) {
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height)];
        [self addSubview:label];
        label.font = [UIFont systemFontOfSize:17.0];
        label.textColor = [UIColor blackColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = _text;
        return;
    }
    
    _scroll_view = [[UIScrollView alloc]initWithFrame:self.bounds];
    _scroll_view.contentSize = CGSizeMake(title_size.width+10.0, title_size.height);
    [self addSubview: _scroll_view];
    _scroll_view.scrollEnabled = NO;
    _scroll_view.showsVerticalScrollIndicator = NO;
    _scroll_view.showsHorizontalScrollIndicator = NO;
    
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(5.0, 0.0, title_size.width, self.frame.size.height)];
    [_scroll_view addSubview:label];
    label.font = [UIFont systemFontOfSize:17.0];
    label.textColor = [UIColor blackColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = _text;
    
    double animation_duration = 0.0;
    animation_duration = title_size.width/_scroll_view.frame.size.width*2.0;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        __block BOOL is_to_right = YES;
        while (al) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (is_to_right) {
                    [UIView animateWithDuration:animation_duration animations:^{
                        [al.scroll_view scrollRectToVisible:CGRectMake(al.scroll_view.contentSize.width-al.scroll_view.bounds.size.width, 0, al.scroll_view.bounds.size.width, title_size.height) animated:NO];
                    }];
                } else {
                    [UIView animateWithDuration:animation_duration animations:^{
                        [al.scroll_view scrollRectToVisible:CGRectMake(0, 0, al.scroll_view.bounds.size.width, title_size.height) animated:NO];
                    }];
                }
                
            });
            [NSThread sleepForTimeInterval:animation_duration+0.5];
            is_to_right = !is_to_right;
        }
    });
}

- (void)setText:(NSString *)text
{
    _text = [text copy];
    [self add_scroll_view];
}

@end
