//
//  UIView+RoundedStyle.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIView (RoundedStyle)

/* Remove all the border radii and set a white background color. */
- (void)cleanStyle;

/* add a beziermask to set a set of rounded corners */
/* Apply radius to top of textField */
- (void)styleWithTopBorderRadius:(CGFloat)radius;
/* Apply radius to bottom of textField */
- (void)styleWithBottomBorderRadius:(CGFloat)radius;

@end
