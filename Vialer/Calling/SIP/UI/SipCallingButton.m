//
//  SipCallingButton.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "SipCallingButton.h"

#import "Vialer-Swift.h"


static float const SipCallingButtonPressedAlpha = 0.5;
static float const SipCallingButtonDisabledAlpha = 0.2;

@interface SipCallingButton()
@property (strong, nonatomic) UIImageView *buttonImageView;
@property (strong, nonatomic) UIColor *textColor;
@property (strong, nonatomic) UIColor *pressedColor;

@property (weak, nonatomic) ColorsConfiguration *colorsConfiguration;
@end

@implementation SipCallingButton

#pragma mark - Properties

- (ColorsConfiguration *)colorsConfiguration {
    if (!_colorsConfiguration) {
        _colorsConfiguration = [ColorsConfiguration shared];
    }
    return _colorsConfiguration;
}

- (void)setButtonImage:(NSString *)buttonImage {
    UIImage *image = [[UIImage imageNamed:buttonImage] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.buttonImageView.image = image;
    self.buttonImageView.tintColor = self.textColor;
}

- (UIImageView *)buttonImageView {
    if (!_buttonImageView) {
        _buttonImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _buttonImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_buttonImageView];
        [self positionButtonImageView];
    }
    return _buttonImageView;
}

- (UIColor *)textColor {
    if (!_textColor) {
        _textColor = [self.colorsConfiguration colorForKey:ColorsNumberPadButtonText];
    }
    return _textColor;
}

- (UIColor *)pressedColor {
    if (!_pressedColor) {
        _pressedColor = [[self.colorsConfiguration colorForKey:ColorsNumberPadButtonPressed] colorWithAlphaComponent:SipCallingButtonPressedAlpha];
    }
    return _pressedColor;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [self setNeedsDisplay];
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    [self setNeedsDisplay];
    self.alpha = enabled ? 1.0 : SipCallingButtonDisabledAlpha;
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    [self positionButtonImageView];
}

- (void)setActive:(BOOL)active {
    _active = active;
    [self setNeedsDisplay];
}

# pragma mark - Position image

- (void)positionButtonImageView {
    CGRect newFrame = CGRectMake(CGRectGetWidth(self.bounds)* 0.25,
                                 CGRectGetHeight(self.bounds) * 0.25,
                                 CGRectGetWidth(self.bounds) * 0.50,
                                 CGRectGetHeight(self.bounds) * 0.50);
    self.buttonImageView.frame = newFrame;
}

# pragma mark - Drawing

- (void)drawRect:(CGRect)rect {
    UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:self.bounds];
    [circle addClip];
    [circle setLineWidth:1 * [UIScreen mainScreen].scale];

    self.buttonImageView.tintColor = self.textColor;

    // When highlighted or disabled, greyout the button.
    if (self.highlighted || !self.isEnabled) {
        [self.pressedColor setStroke];
        [self.pressedColor setFill];

    // When active, make the button filled and image greyed out.
    } else if (self.active) {
        [self.textColor setStroke];
        [self.pressedColor setFill];

    // When the button is enabled but not active, no fill and filled image.
    } else {
        [self.textColor setStroke];
        [[UIColor clearColor] setFill];
    }

    // And actually do the stroke and fill
    [circle stroke];
    [circle fill];
}

@end
