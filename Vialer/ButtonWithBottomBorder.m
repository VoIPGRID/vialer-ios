//
//  ButtonWithBottomBorder.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "ButtonWithBottomBorder.h"

#import "Configuration.h"

@implementation ButtonWithBottomBorder

- (void)layoutSubviews {
    [super layoutSubviews];
    [self setNeedsDisplay];
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    if (highlighted) {
        self.backgroundColor = [Configuration tintColorForKey:ConfigurationSideMenuButtonPressedState];
    } else {
        self.backgroundColor = nil;
    }
}

- (void)setBorderColor:(UIColor *)borderColor {
    _borderColor = borderColor;
    [self setNeedsDisplay];
}

- (void)setBorderSize:(CGFloat)borderSize {
    _borderSize = borderSize;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, self.borderColor.CGColor);
    CGContextFillRect(context, CGRectMake(0, self.frame.size.height - self.borderSize, self.frame.size.width, self.borderSize));
}

@end
