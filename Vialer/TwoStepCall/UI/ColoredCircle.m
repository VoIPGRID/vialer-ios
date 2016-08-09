//
//  ColoredCircle.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "ColoredCircle.h"

@implementation ColoredCircle

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.backgroundColor = nil;
    self.opaque = FALSE;
}

- (void)setColor:(UIColor *)color {
    _color = color;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:self.bounds];
    [self.color setFill];
    [circle fill];
}

@end
