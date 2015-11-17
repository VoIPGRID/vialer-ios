//
//  WifiPhone.m
//  2stepscreen
//
//  Created by Bob Voorneveld on 15/10/15.
//  Copyright © 2015 Bob Voorneveld. All rights reserved.
//

#import "VialerIconView.h"

#import "CircleWithShadow.h"

@interface VialerIconView()

@property (nonatomic, strong) CircleWithShadow *background;
@property (nonatomic, strong) UIImageView *icon;

@end

static float VialerIconViewScale = 1.f - 36/60.f;

static NSString * const VialerIconViewVialerIcon = @"wifi-phone";

@implementation VialerIconView

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
    [self addSubview:self.icon];
    self.opaque = FALSE;
    self.backgroundColor = nil;
    self.opaque = NO;
    [self setNeedsDisplay];
}

- (void)setIconColor:(UIColor *)iconColor {
    self.icon.backgroundColor = iconColor;
    [self setNeedsDisplay];
}

- (CircleWithShadow *)background {
    if (!_background) {
        _background = [[CircleWithShadow alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
        _background.color = [UIColor whiteColor];
    }
    return _background;
}

- (UIImageView *)icon {
    if (!_icon) {
        _icon = [[UIImageView alloc] initWithFrame:CGRectMake(self.bounds.size.width * VialerIconViewScale / 2,
                                                              self.bounds.size.width * VialerIconViewScale / 2,
                                                              self.bounds.size.width-self.bounds.size.width * VialerIconViewScale,
                                                              self.bounds.size.height-self.bounds.size.width * VialerIconViewScale)];
        _icon.backgroundColor = self.iconColor;
        [_icon setImage:[UIImage imageNamed:VialerIconViewVialerIcon]];
    }
    return _icon;
}

@end
