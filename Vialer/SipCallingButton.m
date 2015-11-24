//
//  SipCallingButton.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "SipCallingButton.h"

#import "Configuration.h"


static float const SipCallingButtonPressedAlpha = 0.5;

@interface SipCallingButton()
@property (strong, nonatomic) UIImageView *buttonImageView;
@property (strong, nonatomic) UIColor *textColor;
@property (strong, nonatomic) UIColor *pressedColor;
@end

@implementation SipCallingButton

#pragma mark - properties
- (NSString *)buttonImage {
    return self.buttonImage;
}

- (void)setButtonImage:(NSString *)buttonImage {
    UIImage *image = [[UIImage imageNamed:buttonImage] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.buttonImageView.image = image;
    self.buttonImageView.tintColor = self.textColor;
}

- (UIImageView *)buttonImageView {
    if (!_buttonImageView) {
        _buttonImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [self addSubview:_buttonImageView];
        [self positionButtonImageView];
    }
    return _buttonImageView;
}

- (UIColor *)textColor {
    if (!_textColor) {
        _textColor = [Configuration tintColorForKey:ConfigurationNumberPadButtonTextColor];
    }
    return _textColor;
}

- (UIColor *)pressedColor {
    if (!_pressedColor) {
        _pressedColor = [[Configuration tintColorForKey:ConfigurationNumberPadButtonPressedColor] colorWithAlphaComponent:SipCallingButtonPressedAlpha];
    }
    return _pressedColor;
}

/**
 When the button is highlighted update the button.
 */
- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [self setNeedsDisplay];
}

/**
 When the button is enabled update the button.
 */
- (void)setEnabled:(BOOL)enabled {
    [super setHighlighted:enabled];
    [self setNeedsDisplay];
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    [self positionButtonImageView];
}

# pragma mark - position image

- (void)positionButtonImageView {
    CGRect newFrame = CGRectMake(CGRectGetWidth(self.bounds)* 0.25,
                                 CGRectGetHeight(self.bounds) * 0.25,
                                 CGRectGetWidth(self.bounds) * 0.50,
                                 CGRectGetHeight(self.bounds) * 0.50);
    self.buttonImageView.frame = newFrame;
}

# pragma mark - drawing

- (void)drawRect:(CGRect)rect {
    UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:self.bounds];
    [circle addClip];
    [circle setLineWidth:1 * [UIScreen mainScreen].scale];

    // If the button is pressed or disabled change the color of the circle.
    // Also change the tint color of the image on the button.
    if (self.highlighted || !self.enabled) {
        UIColor *circleColor = self.pressedColor;
        [circleColor setStroke];
        [circle stroke];
        [circleColor setFill];
        self.buttonImageView.tintColor = self.pressedColor;
    } else {
        [self.textColor setStroke];
        [circle stroke];
        self.buttonImageView.tintColor = self.textColor;
    }
}

@end
