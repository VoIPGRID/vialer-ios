//
//  CircleWithShadow.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "CircleWithShadow.h"

@interface CircleWithShadow()

@property (nonatomic) CGRect circleRect;

@end

static float const CircleWithShadowAlphaColor = 0.3f;
static int const CircleWithShadowRadius = 1;

@implementation CircleWithShadow

- (void)awakeFromNib {
    [self setup];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.opaque = FALSE;
    self.backgroundColor = nil;
    self.layer.shadowColor = [[[UIColor blackColor] colorWithAlphaComponent:CircleWithShadowAlphaColor] CGColor];
    self.layer.shadowOffset = CGSizeMake(0,0);
    self.layer.shadowOpacity = 1;
    self.layer.shadowRadius = CircleWithShadowRadius;
    self.layer.masksToBounds = NO;
}

- (void)setColor:(UIColor *)color {
    _color = color;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:self.bounds];
    [circle addClip];
    [self.color setFill];
    [circle fill];
}

@end
