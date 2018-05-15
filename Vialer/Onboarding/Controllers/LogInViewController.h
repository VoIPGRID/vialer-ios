//
//  LogInViewController.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "AnimatedImageView.h"
#import "ConfigureFormView.h"
#import "ForgotPasswordView.h"
#import "LoginFormView.h"
#import "SystemUser.h"
#import "TwoFactorAuthenticationView.h"
#import "UnlockView.h"

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, OnboardingScreens) {
    OnboardingScreenLogin = 0,
    OnboardingScreenTwoFactorAuthentication = 1,
    OnboardingScreenConfigure = 2,
    //Not supported yet
    //OnboardingScreenUnlock     = 2,
};

@interface LogInViewController : UIViewController <UITextFieldDelegate>

/* The vialier logo that moves out of screen when view opens. */
@property (nonatomic, strong) IBOutlet AnimatedImageView *logoView;

/* Forms which require user input */
@property (nonatomic, strong) IBOutlet LoginFormView *loginFormView;
@property (nonatomic, strong) IBOutlet TwoFactorAuthenticationView *twoFactorAuthenticationView;
@property (nonatomic, strong) IBOutlet ForgotPasswordView *forgotPasswordView;
@property (nonatomic, strong) IBOutlet ConfigureFormView *configureFormView;
@property (nonatomic, strong) IBOutlet UnlockView *unlockView;
@property (nonatomic, strong) IBOutlet UIButton *closeButton;


/** Dependency Injection */
@property (nonatomic) SystemUser *currentUser;

/** @property screenToShow
 *  The onboarding screen to show after the Logo animation
 **/
@property (nonatomic) OnboardingScreens screenToShow;

- (IBAction)openForgotPassword:(id)sender;
- (IBAction)closeButtonPressed:(UIButton *)sender;
- (IBAction)loginButtonPushed:(UIButton *)sender;
- (IBAction)requestPasswordButtonPressed:(UIButton *)sender;

- (IBAction)openConfigurationInstructions:(id)sender;

@end
