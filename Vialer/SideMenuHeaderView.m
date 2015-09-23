//
//  SideMenuHeaderView.m
//  Vialer
//
//  Created by Bob Voorneveld on 25/09/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "SideMenuHeaderView.h"

#define X_OFFSET_LOGO_PHONE_NUMBER      8
#define SPACING_LOGO_PHONE_NUMBER       15.f

@interface SideMenuHeaderView ()
@property (nonatomic, strong) UIImageView *logoImageView;
@property (nonatomic, strong) UILabel *numberLabel;
@property (nonatomic, strong) UILabel *emailLabel;
@end

@implementation SideMenuHeaderView

- (instancetype)initWithFrame:(CGRect)frame andTintColor:(UIColor *)tintColor {
    self = [super initWithFrame:frame];

    if (self) {
        self.backgroundColor = [UIColor groupTableViewBackgroundColor];
        [self addSubview:self.logoImageView];
        [self addSubview:self.numberLabel];
        [self addSubview:self.emailLabel];
        self.emailLabel.textColor = tintColor;
        self.numberLabel.textColor = tintColor;
    }

    return self;
}

- (void)setEmailAddress:(NSString *)emailAddress {
    self.emailLabel.text = emailAddress;
}

- (void)setPhoneNumber:(NSString *)phoneNumber {
    self.numberLabel.text = phoneNumber;
}

- (UIImageView *)logoImageView {
    if (!_logoImageView) {
        _logoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(X_OFFSET_LOGO_PHONE_NUMBER, 40.f, 171.f, 41.f)];
        _logoImageView.image = [UIImage imageNamed:@"sideMenuLogo"];
        _logoImageView.contentMode = UIViewContentModeLeft;
    }
    return _logoImageView;
}

- (UILabel *)numberLabel {
    if(!_numberLabel) {
        CGFloat yOffset = CGRectGetMaxY(self.logoImageView.frame) + SPACING_LOGO_PHONE_NUMBER;
        _numberLabel = [[UILabel alloc] initWithFrame:CGRectMake(X_OFFSET_LOGO_PHONE_NUMBER, yOffset, CGRectGetWidth(self.frame), 20.f)];
        _numberLabel.font = [UIFont systemFontOfSize:14.f];
        _numberLabel.textAlignment = NSTextAlignmentLeft;
        _numberLabel.textColor = self.tintColor;
    }
    return _numberLabel;
}

- (UILabel *)emailLabel {
    if (!_emailLabel) {
        CGFloat yOffset = CGRectGetMaxY(self.numberLabel.frame);
        _emailLabel = [[UILabel alloc] initWithFrame:CGRectMake(X_OFFSET_LOGO_PHONE_NUMBER, yOffset, CGRectGetWidth(self.frame), 20.f)];
        _emailLabel.font = [UIFont systemFontOfSize:14.f];
        _emailLabel.adjustsFontSizeToFitWidth = true;
        _emailLabel.minimumScaleFactor = 0.5;
        _emailLabel.textAlignment = NSTextAlignmentLeft;
        _emailLabel.textColor = self.tintColor;
    }
    return _emailLabel;
}


@end
