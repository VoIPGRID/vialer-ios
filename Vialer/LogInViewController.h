//
//  LogInViewController.h
//  Vialer
//
//  Created by Reinier Wieringa on 06/11/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TrackedViewController.h"
#import "AnimatedImageView.h"

#import "LoginFormView.h"
#import "ForgotPasswordView.h"
#import "ConfigureFormView.h"
#import "UnlockView.h"

@interface LogInViewController : TrackedViewController <UITextFieldDelegate, UIAlertViewDelegate>

/* The vialier logo that moves out of screen when view opens. */
@property (nonatomic, strong) IBOutlet AnimatedImageView *logoView;

/* Forms which require user input */
@property (nonatomic, strong) IBOutlet LoginFormView *loginFormView;
@property (strong, nonatomic) IBOutlet ForgotPasswordView *forgotPasswordView;
@property (nonatomic, strong) IBOutlet ConfigureFormView *configureFormView;
@property (strong, nonatomic) IBOutlet UnlockView *unlockView;
@property (strong, nonatomic) IBOutlet UIButton *closeButton;

// The unlock slider: should be refactored to unlockView.
@property (nonatomic, strong) IBOutlet UIView *sliderView;

- (IBAction)unlockIt;
- (IBAction)fadeLabel;

- (IBAction)openForgotPassword:(id)sender;
- (IBAction)closeButtonPressed:(UIButton *)sender;

- (IBAction)openConfigurationInstructions:(id)sender;

@end
