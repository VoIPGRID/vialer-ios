//
//  TwoFactorAuthenticationView.m
//  Copyright © 2018 VoIPGRID. All rights reserved.
//

#import "TwoFactorAuthenticationView.h"
#import "UIView+RoundedStyle.h"

static CGFloat const TwoFactorAuthenticationViewButtonRadius = 5.0;


@implementation TwoFactorAuthenticationView

- (void)awakeFromNib {
    [super awakeFromNib];

    self.twoFactorAuthenticationDescriptionField.text = NSLocalizedString(@"Two-factor autentication", nil);

    self.tokenField.placeholder = NSLocalizedString(@"Token", nil);
    [self.tokenField setClearButtonMode:UITextFieldViewModeWhileEditing];
    [self.tokenField cleanStyle];

    [self.continueButton setTitle:NSLocalizedString(@"Continue", nil) forState:UIControlStateNormal];

    [self setupRoundedButtons:@[self.continueButton]];
}

- (Configuration *)configuration {
    if (!_configuration) {
        _configuration = [Configuration defaultConfiguration];
    }
    return _configuration;
}

- (void)setupRoundedButtons:(NSArray<RoundedAndColoredUIButton *> *)buttons {
    for (RoundedAndColoredUIButton *button in buttons) {
        button.borderWidth = 1;
        button.cornerRadius = TwoFactorAuthenticationViewButtonRadius;
        button.borderColor = [self.configuration.colorConfiguration colorForKey:ConfigurationLogInViewControllerButtonBorderColor];
        button.backgroundColorForPressedState = [self.configuration.colorConfiguration colorForKey:ConfigurationLogInViewControllerButtonBackgroundColorForPressedState];
    }
}

- (void)setTextFieldDelegate:(id<UITextFieldDelegate>)delegate {
    self.tokenField.delegate = delegate;
}

@end
