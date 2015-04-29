//
//  LoginFormView.m
//  Vialer
//
//  Created by Karsten Westra on 20/04/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "LoginFormView.h"
#import "UIView+RoundedStyle.h"

@implementation LoginFormView

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {

    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    /* Remove all the default UITextField styling */
    [self.emailField cleanStyle];
    [self.passwordField cleanStyle];
    /* Add top rounded corner mask */
    [self.emailField styleWithTopBorderRadius:8.f];
    /* Add bottom corner mask */
    [self.passwordField styleWithBottomBorderRadius:8.f];
    
    [self.emailField setupPlaceHolder:@"required" labelText:@"E-mail"];
    [self.passwordField setupPlaceHolder:@"required" labelText:@"Password"];
    
    [self.passwordField setSecureTextEntry:YES];
}

- (void)setTextFieldDelegate:(id<UITextFieldDelegate>)delegate {
    [self.passwordField setTextFieldDelegate:delegate];
    [self.emailField setTextFieldDelegate:delegate];
}

@end
