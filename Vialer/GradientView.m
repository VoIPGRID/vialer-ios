//
//  GradientView.m
//  Vialer
//
//  Created by Reinier Wieringa on 15/04/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "GradientView.h"

@interface GradientView ()
@property (nonatomic, strong) UIColor *startColor;
@property (nonatomic, strong) UIColor *endColor;
@property (nonatomic, assign) CGFloat angle;
@end

@implementation GradientView

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initFromConfig];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initFromConfig];
    }
    return self;
}

- (void)initFromConfig {
    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"]];
    NSAssert(config != nil, @"Config.plist not found!");

    NSDictionary *background = [[config objectForKey:@"Tint colors"] objectForKey:@"Background"];
    NSAssert(background != nil, @"Tint colors - Backround not found in Config.plist!");

    NSArray *gradientStartColor = [background objectForKey:@"GradientStart"];
    NSAssert(gradientStartColor != nil && gradientStartColor.count == 3, @"Tint colors - Backround - GradientStart not found in Config.plist!");

    NSArray *gradientEndColor = [background objectForKey:@"GradientEnd"];
    NSAssert(gradientEndColor != nil && gradientEndColor.count == 3, @"Tint colors - Backround - GradientEnd not found in Config.plist!");

    NSNumber *gradientAngle = [background objectForKey:@"GradientAngle"];
    NSAssert(gradientAngle != nil, @"Tint colors - Backround - GradientAngle not found in Config.plist!");

    self.startColor = [UIColor colorWithRed:[gradientStartColor[0] intValue] / 255.f green:[gradientStartColor[1] intValue] / 255.f blue:[gradientStartColor[2] intValue] / 255.f alpha:1.f];
    self.endColor = [UIColor colorWithRed:[gradientEndColor[0] intValue] / 255.f green:[gradientEndColor[1] intValue] / 255.f blue:[gradientEndColor[2] intValue] / 255.f alpha:1.f];
    self.angle = [gradientAngle floatValue];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CFArrayRef colors = (__bridge CFArrayRef) @[(id)self.startColor.CGColor, (id)self.endColor.CGColor];

    CGFloat locations[2] = { 0.0, 1.0 };
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, colors, locations);

    CGFloat degree = self.angle * M_PI / 180;
    CGPoint center = CGPointMake(self.bounds.size.width / 2.f, self.bounds.size.height / 2.f);
    CGPoint startPoint = CGPointMake(center.x - cos(degree) * center.x, center.y - sin(degree) * center.y);
    CGPoint endPoint = CGPointMake(center.x + cos(degree) * center.x, center.y + sin(degree) * center.y);

    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, kCGGradientDrawsBeforeStartLocation + kCGGradientDrawsAfterEndLocation);

    CGColorSpaceRelease(colorSpace);
    CGGradientRelease(gradient);
}

@end
