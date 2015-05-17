//
//  LoginFormView.m
//  Vialer
//
//  Created by Karsten Westra on 20/04/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "LoginFormView.h"
#import "UIView+RoundedStyle.h"

@interface LoginFormView ()
//Display's "Business"
@property (nonatomic, weak) IBOutlet UILabel *businessLabel;
//Display's "calls in the cloud"
@property (nonatomic, weak) IBOutlet UILabel *callsInTheCloudLabel;
@property (nonatomic, weak) IBOutlet UIButton *forgotPasswordButton;
@end

@implementation LoginFormView

- (void)awakeFromNib {
    [super awakeFromNib];
    //Localize elements of view
    self.businessLabel.text = NSLocalizedString(@"Business", nil);
    self.callsInTheCloudLabel.text = NSLocalizedString(@"calls in the cloud", nil);
    
    [self.emailField setupPlaceHolder:NSLocalizedString(@"required", nil)
                                          labelText:NSLocalizedString(@"Email", nil)];
    [self.emailField setClearButtonMode:UITextFieldViewModeWhileEditing];
    
    [self.passwordField setupPlaceHolder:NSLocalizedString(@"required", nil)
                                             labelText:NSLocalizedString(@"Password", nil)];
    [self.passwordField setClearButtonMode:UITextFieldViewModeWhileEditing];
    
    [self.forgotPasswordButton setTitle:NSLocalizedString(@"Forgot password?", nil) forState:UIControlStateNormal];
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
    
    [self.passwordField setSecureTextEntry:YES];
}

- (void)setTextFieldDelegate:(id<UITextFieldDelegate>)delegate {
    [self.passwordField setTextFieldDelegate:delegate];
    [self.emailField setTextFieldDelegate:delegate];
}

@end
