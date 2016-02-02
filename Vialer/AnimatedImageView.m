//
//  AnimatedImageView.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "AnimatedImageView.h"

@implementation AnimatedImageView {
    NSMutableArray *animationPath; // Array of CGPoint instances over which this imageView animates.
    
    __weak NSMutableArray *_onStage;
}

- (instancetype)initWithImage:(UIImage *)image {
    self = [super initWithImage:image];
    if (self) {
        animationPath = [NSMutableArray array];
    }
    return self;
}

- (void)addPoint:(CGPoint)point {
    [animationPath addObject:[NSValue valueWithCGPoint:point]];
}

- (void)animateToNextWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay {
    NSValue *v = [animationPath firstObject];
    [animationPath removeObject:v];

    CGPoint p = [v CGPointValue];
    [self moveToPoint:p withDuration:duration delay:delay andRemoveWhenOffScreen:YES];
}

- (void)moveToPoint:(CGPoint)point withDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay andRemoveWhenOffScreen:(BOOL)remove {
    [UIView animateWithDuration:duration
                          delay:delay
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.center = point;
                     }
                     completion:^(BOOL finished) {
                         if ((self.center.y < 0 || self.center.x < -60) && remove) {
                             [self removeFromSuperview];
                         }
                     }];
}

@end
