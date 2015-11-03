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
@property (nonatomic, weak) IBOutlet UIButton *loginButton;
@property (nonatomic, weak) IBOutlet UIButton *forgotPasswordButton;
@property (nonatomic, weak) IBOutlet UIButton *configurationInstructionsButton;
@end

@implementation LoginFormView

- (void)awakeFromNib {
    [super awakeFromNib];
    //Localize elements of view
    self.businessLabel.text = NSLocalizedString(@"Business", nil);
    self.callsInTheCloudLabel.text = NSLocalizedString(@"calls in the cloud", nil);
    
    self.usernameField.placeholder = NSLocalizedString(@"Email", nil);
    self.passwordField.placeholder = NSLocalizedString(@"Password", nil);
    
    [self.usernameField cleanStyle];
    [self.passwordField cleanStyle];
    
    [self.loginButton setTitle:NSLocalizedString(@"Login", nil) forState:UIControlStateNormal];
    [self.forgotPasswordButton setTitle:NSLocalizedString(@"Forgot password?", nil) forState:UIControlStateNormal];
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    [self.configurationInstructionsButton setTitle:[NSString stringWithFormat:NSLocalizedString(@"HOW_DOES_APP_WORK_BUTTON_TEXT", nil), appName] forState:UIControlStateNormal];

    self.isMoved = NO;
}

- (void)setTextFieldDelegate:(id<UITextFieldDelegate>)delegate {
    self.passwordField.delegate = delegate;
    self.usernameField.delegate = delegate;
}

@end
