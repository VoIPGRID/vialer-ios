//
//  TwoFactorAuthenticationView.m
//  Copyright © 2018 VoIPGRID. All rights reserved.
//

#import "TwoFactorAuthenticationView.h"
#import "UIView+RoundedStyle.h"
#import "Vialer-Swift.h"

static CGFloat const TwoFactorAuthenticationViewButtonRadius = 5.0;


@implementation TwoFactorAuthenticationView

- (void)awakeFromNib {
    [super awakeFromNib];

    self.twoFactorAuthenticationDescriptionField.text = NSLocalizedString(@"Two-factor authentication", nil);

    self.tokenField.placeholder = NSLocalizedString(@"Token", nil);
    [self.tokenField setClearButtonMode:UITextFieldViewModeWhileEditing];
    [self.tokenField cleanStyle];
    self.tokenField.keyboardType = UIKeyboardTypeNumberPad;

    [self.continueButton setTitle:NSLocalizedString(@"Continue", nil) forState:UIControlStateNormal];

    [self setupRoundedButtons:@[self.continueButton]];
}

- (void)setupRoundedButtons:(NSArray<RoundedAndColoredUIButton *> *)buttons {
    for (RoundedAndColoredUIButton *button in buttons) {
        button.borderWidth = 1;
        button.cornerRadius = TwoFactorAuthenticationViewButtonRadius;
        button.borderColor = [[ColorsConfiguration shared] colorForKey:ColorsLogInViewControllerButtonBorder];
        button.backgroundColorForPressedState = [[ColorsConfiguration shared] colorForKey:ColorsLogInViewControllerButtonBackgroundPressedState];
    }
}

- (void)setTextFieldDelegate:(id<UITextFieldDelegate>)delegate {
    self.tokenField.delegate = delegate;
}

@end
