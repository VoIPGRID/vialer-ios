//
//  ForgotPasswordView.m
//  Vialer
//
//  Created by Karsten Westra on 30/04/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
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
}

/*
- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect frame = (CGRect) {
        .origin = self.emailTextfield.frame.origin,
        .size = CGSizeMake(CGRectGetWidth(self.emailTextfield.frame), 44.f)
    };
    [self.emailTextfield setFrame:frame];
}*/

@end
