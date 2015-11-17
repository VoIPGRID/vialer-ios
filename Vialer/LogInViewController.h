//
//  LogInViewController.h
//  Vialer
//
//  Created by Reinier Wieringa on 06/11/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "AnimatedImageView.h"
#import "ConfigureFormView.h"
#import "ForgotPasswordView.h"
#import "LoginFormView.h"
#import "UnlockView.h"

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, OnboardingScreens) {
    OnboardingScreenLogin      = 0,
    OnboardingScreenConfigure  = 1,
    //Not supported yet
    //OnboardingScreenUnlock     = 2,
};

@interface LogInViewController : UIViewController <UITextFieldDelegate, UIAlertViewDelegate>

/* The vialier logo that moves out of screen when view opens. */
@property (nonatomic, strong) IBOutlet AnimatedImageView *logoView;

/* Forms which require user input */
@property (nonatomic, strong) IBOutlet LoginFormView *loginFormView;
@property (strong, nonatomic) IBOutlet ForgotPasswordView *forgotPasswordView;
@property (nonatomic, strong) IBOutlet ConfigureFormView *configureFormView;
@property (strong, nonatomic) IBOutlet UnlockView *unlockView;
@property (strong, nonatomic) IBOutlet UIButton *closeButton;

// The unlock slider: should be refactored to unlockView.


/** @property screenToShow
 *  The onboarding screen to show after the Logo animation
 **/
@property (nonatomic)OnboardingScreens screenToShow;

- (IBAction)unlockIt;

- (IBAction)openForgotPassword:(id)sender;
- (IBAction)closeButtonPressed:(UIButton *)sender;

- (IBAction)openConfigurationInstructions:(id)sender;

@end
