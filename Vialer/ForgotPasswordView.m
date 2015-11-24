//
//  ForgotPasswordView.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "ForgotPasswordView.h"

@implementation ForgotPasswordView

- (void)awakeFromNib {
    [super awakeFromNib];
    //Localize elements of view
    self.emailTextfield.placeholder = NSLocalizedString(@"Email", nil);
    self.forgotPasswordLabel.text = NSLocalizedString(@"Forgot password?", nil);
    self.pleaseEnterEmailLabel.text = NSLocalizedString(@"Please enter your e-mail address and we will send you instructions on setting a new password.", nil);
    
    [self.requestPasswordButton setTitle:NSLocalizedString(@"Request password", nil) forState:UIControlStateNormal];

    self.isMoved = NO;
}

@end
