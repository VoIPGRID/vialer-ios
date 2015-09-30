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
@property (nonatomic, strong) UILabel *nameLabel;
@end

@implementation SideMenuHeaderView

- (instancetype)initWithFrame:(CGRect)frame andTintColor:(UIColor *)tintColor {
    self = [super initWithFrame:frame];

    if (self) {
        self.backgroundColor = [UIColor groupTableViewBackgroundColor];
        [self addSubview:self.logoImageView];
        [self addSubview:self.numberLabel];
        [self addSubview:self.nameLabel];
        self.nameLabel.textColor = tintColor;
        self.numberLabel.textColor = tintColor;
    }
    return self;
}

- (void)setDisplayName:(NSString *)displayName {
    self.nameLabel.text = displayName;
}

- (void)setPhoneNumber:(NSString *)phoneNumber {
    if (phoneNumber.length > 0) {
        self.numberLabel.text = phoneNumber;
    } else {
        self.numberLabel.text = NSLocalizedString(@"No outgoing number configured", nil);
    }
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

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        CGFloat yOffset = CGRectGetMaxY(self.numberLabel.frame);
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(X_OFFSET_LOGO_PHONE_NUMBER, yOffset, CGRectGetWidth(self.frame), 20.f)];
        _nameLabel.font = [UIFont systemFontOfSize:14.f];
        _nameLabel.adjustsFontSizeToFitWidth = true;
        _nameLabel.minimumScaleFactor = 0.5;
        _nameLabel.textAlignment = NSTextAlignmentLeft;
        _nameLabel.textColor = self.tintColor;
    }
    return _nameLabel;
}


@end
