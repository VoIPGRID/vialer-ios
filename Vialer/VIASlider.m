//
//  VIASlider.m
//  Vialer
//
//  Created by Karsten Westra on 24/04/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "VIASlider.h"

@implementation VIASlider

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent*)event {
    CGRect bounds = self.bounds;
    bounds = CGRectInset(bounds, -72, -72);
    return CGRectContainsPoint(bounds, point);
}

@end
