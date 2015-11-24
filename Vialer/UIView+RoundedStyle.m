//
//  UIView+RoundedStyle.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "UIView+RoundedStyle.h"


@implementation UIView (RoundedStyle)

- (void)cleanStyle {
    [self setBackgroundColor:[UIColor whiteColor]];
    [self.layer setCornerRadius:0.f];
}

- (void)styleWithTopBorderRadius:(CGFloat)radius {
    UIBezierPath *topMaskPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                        byRoundingCorners:(UIRectCornerTopLeft|UIRectCornerTopRight)
                                              cornerRadii:CGSizeMake(radius, radius)];

    CAShapeLayer *topMaskLayer = [[CAShapeLayer alloc] init];
    topMaskLayer.frame = self.bounds;
    topMaskLayer.path = topMaskPath.CGPath;
    self.layer.mask = topMaskLayer;
}

- (void)styleWithBottomBorderRadius:(CGFloat)radius {
    UIBezierPath *bottomMaskPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                           byRoundingCorners:(UIRectCornerBottomLeft|UIRectCornerBottomRight)
                                                 cornerRadii:CGSizeMake(radius, radius)];

    CAShapeLayer *bottomMaskLayer = [[CAShapeLayer alloc] init];
    bottomMaskLayer.frame = self.bounds;
    bottomMaskLayer.path = bottomMaskPath.CGPath;
    self.layer.mask = bottomMaskLayer;
}

@end
