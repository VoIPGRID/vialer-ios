//
//  NumberPadButton.m
//  Vialer
//
//  Created by Bob Voorneveld on 03/11/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "NumberPadButton.h"

#import "Configuration.h"

static float const NumberPadButtonTitleYFactorOffset = .1;
static float const NumberPadButtonTitleHeigthFactor = .60;

static float const NumberPadButtonSubtitleHeigthFactor = .25;
static float const NumberPadButtonSubtitleYFactorOffset = 0.60;

static float const NumberPadButtonPressedAlpha = 0.5;

@interface NumberPadButton()
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *numberLabel;

@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *pressedColor;
@end

@implementation NumberPadButton

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setListeners];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setListeners];
    }
    return self;
}

#pragma mark - Properties

- (NSString *)number {
    return self.numberLabel.text;
}

- (void)setNumber:(NSString *)number {
    self.numberLabel.text = number;
}

- (NSString *)subtitle {
    return self.subtitleLabel.text;
}

- (void)setSubtitle:(NSString *)subtitle {
    self.subtitleLabel.text = subtitle;
}

- (UILabel *)subtitleLabel {
    if (!_subtitleLabel) {
        _subtitleLabel = [[UILabel alloc] initWithFrame:self.bounds];
        _subtitleLabel.textColor = [UIColor whiteColor];
        _subtitleLabel.textAlignment = NSTextAlignmentCenter;
        _subtitleLabel.adjustsFontSizeToFitWidth = YES;
        _subtitleLabel.minimumScaleFactor = 0.1f;
        _subtitleLabel.numberOfLines = 0;
        [self addSubview:_subtitleLabel];
        [self positionSubtitleLabel];
    }
    return _subtitleLabel;
}

- (UILabel *)numberLabel {
    if (!_numberLabel) {
        _numberLabel = [[UILabel alloc] initWithFrame:self.bounds];
        _numberLabel.font = [UIFont systemFontOfSize:50];
        _numberLabel.textColor = [UIColor whiteColor];
        _numberLabel.textAlignment = NSTextAlignmentCenter;
        _numberLabel.adjustsFontSizeToFitWidth = YES;
        _numberLabel.minimumScaleFactor = 0.1f;
        _numberLabel.numberOfLines = 0;
        [self addSubview:_numberLabel];
        [self positionNumberLabel];
    }
    return _numberLabel;
}

- (UIColor *)textColor {
    if (!_textColor) {
        _textColor = [Configuration tintColorForKey:ConfigurationNumberPadButtonTextColor];
    }
    return _textColor;
}

- (UIColor *)pressedColor {
    if (!_pressedColor) {
        _pressedColor = [[Configuration tintColorForKey:ConfigurationNumberPadButtonPressedColor] colorWithAlphaComponent:NumberPadButtonPressedAlpha];
    }
    return _pressedColor;
}

# pragma mark - event listening

- (void)setListeners {
    [self addObserver:self forKeyPath:@"highlighted" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"highlighted"] && change[@"new"] != change[@"old"]) {
        [self setNeedsDisplay];
    }
}

#pragma mark - Positioning labels

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    [self positionNumberLabel];
    [self positionSubtitleLabel];
}

- (void)positionNumberLabel {
    CGRect newFrame = CGRectMake(0,
                                 CGRectGetHeight(self.bounds) * NumberPadButtonTitleYFactorOffset,
                                 CGRectGetWidth(self.bounds),
                                 CGRectGetHeight(self.bounds) * NumberPadButtonTitleHeigthFactor);
    self.numberLabel.frame = newFrame;
}

- (void)positionSubtitleLabel {
    CGRect newFrame = CGRectMake(0,
                                 CGRectGetHeight(self.bounds) * NumberPadButtonSubtitleYFactorOffset,
                                 CGRectGetWidth(self.bounds),
                                 CGRectGetHeight(self.bounds) * NumberPadButtonSubtitleHeigthFactor);
    self.subtitleLabel.frame = newFrame;
}

# pragma mark - drawing

- (void)drawRect:(CGRect)rect {
    // Drawing code
    UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:self.bounds];
    [circle addClip];
    [circle setLineWidth:1 * [UIScreen mainScreen].scale];
    if (self.highlighted) {
        UIColor *circleColor = self.pressedColor;
        [circleColor setStroke];
        [circle stroke];
        [circleColor setFill];
        [circle fill];
    } else {
        [self.textColor setStroke];
        [circle stroke];
    }
}

@end
