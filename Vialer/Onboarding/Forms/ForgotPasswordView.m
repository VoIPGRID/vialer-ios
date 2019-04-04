//
//  ForgotPasswordView.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "ForgotPasswordView.h"
#import "Vialer-Swift.h"

static CGFloat const ForgotPasswordViewButtonRadius = 5.0;

@implementation ForgotPasswordView

- (void)awakeFromNib {
    [super awakeFromNib];
    //Localize elements of view
    self.emailTextfield.placeholder = NSLocalizedString(@"Email address", nil);
    self.forgotPasswordLabel.text = NSLocalizedString(@"Forgot password?", nil);
    self.pleaseEnterEmailLabel.text = NSLocalizedString(@"Please enter your e-mail address and we will send you instructions on setting a new password.", nil);

    [self.requestPasswordButton setTitle:NSLocalizedString(@"Request password", nil) forState:UIControlStateNormal];

    self.isMoved = NO;

    self.requestPasswordButton.borderWidth = 1;
    self.requestPasswordButton.cornerRadius = ForgotPasswordViewButtonRadius;
    self.requestPasswordButton.borderColor = [[ColorsConfiguration shared] colorForKey:ColorsLogInViewControllerButtonBorder];
    self.requestPasswordButton.backgroundColorForPressedState = [[ColorsConfiguration shared]  colorForKey:ColorsLogInViewControllerButtonBackgroundPressedState];
}

@end
