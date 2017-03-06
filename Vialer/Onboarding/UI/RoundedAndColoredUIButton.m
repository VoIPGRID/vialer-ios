//
//  ColoredUIButton.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "RoundedAndColoredUIButton.h"

@implementation RoundedAndColoredUIButton

- (void)setCornerRadius:(CGFloat)cornerRadius {
    _cornerRadius = cornerRadius;
    self.layer.cornerRadius = cornerRadius;
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    _borderWidth = borderWidth;
    self.layer.borderWidth = borderWidth;
}

- (void)setBorderColor:(UIColor *)borderColor {
    _borderColor = borderColor;
    self.layer.borderColor = borderColor.CGColor;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    if (highlighted) {
        self.backgroundColor = self.backgroundColorForPressedState;
    } else {
        self.backgroundColor = nil;
    }
}

@end
