//
//  CircleWithWhiteIcon.m
//  2stepscreen
//
//  Created by Bob Voorneveld on 16/10/15.
//  Copyright © 2015 Bob Voorneveld. All rights reserved.
//

#import "CircleWithWhiteIcon.h"

#import "CircleWithShadow.h"
#import "ColoredCircle.h"

@interface CircleWithWhiteIcon()

@property (nonatomic, strong) CircleWithShadow *background;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) ColoredCircle *coloredCircle;

@end

static float const CircleWithWhiteIconScale = 1 - 18/60.f;
static int const CircleWithWhiteIconBackgroundInset = 6;


@implementation CircleWithWhiteIcon

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
    [self addSubview:self.background];
    [self addSubview:self.coloredCircle];
    [self addSubview:self.iconView];
    self.opaque = FALSE;
    self.backgroundColor = nil;
    self.opaque = NO;
    [self setNeedsDisplay];
}

- (void)setInnerCircleColor:(UIColor *)innerCircleColor {
    self.coloredCircle.color = innerCircleColor;
}

- (CircleWithShadow *)background {
    if (!_background) {
        _background = [[CircleWithShadow alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
        _background.color = [UIColor whiteColor];
    }
    return _background;
}

- (UIImageView *)iconView {
    if (!_iconView) {
        CGRect iconViewRect = CGRectMake(self.bounds.size.width * CircleWithWhiteIconScale / 2,
                                         self.bounds.size.width * CircleWithWhiteIconScale / 2,
                                         self.bounds.size.width-self.bounds.size.width * CircleWithWhiteIconScale,
                                         self.bounds.size.height-self.bounds.size.width * CircleWithWhiteIconScale);

        _iconView = [[UIImageView alloc] initWithFrame:iconViewRect];
    }
    return _iconView;
}

- (void)setIcon:(UIImage *)icon {
    self.iconView.image = icon;
}

- (ColoredCircle *)coloredCircle {
    if (!_coloredCircle) {
        CGSize backgroundSize = CGSizeMake(self.bounds.size.width - CircleWithWhiteIconBackgroundInset, self.bounds.size.height - CircleWithWhiteIconBackgroundInset);
        CGRect coloredCircleRect = CGRectMake((self.bounds.size.width - backgroundSize.width) /2,
                                           (self.bounds.size.height - backgroundSize.height) / 2,
                                           backgroundSize.width,
                                           backgroundSize.height);
        _coloredCircle = [[ColoredCircle alloc] initWithFrame:coloredCircleRect];
    }
    return _coloredCircle;
}

@end
