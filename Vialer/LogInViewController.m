//
//  LogInViewController.m
//  Vialer
//
//  Created by Reinier Wieringa on 06/11/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "LogInViewController.h"

#import "AppDelegate.h"
#import "AnimatedImageView.h"
#import "ConnectionHandler.h"
#import "GAITracker.h"
#import "SystemUser.h"
#import "UIAlertView+Blocks.h"
#import "UIView+RoundedStyle.h"
#import "VIAScene.h"
#import "VoIPGRIDRequestOperationManager.h"

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>

#import "PBWebViewController.h"
#import "SVProgressHUD.h"

#define SHOW_LOGIN_ALERT      100
#define PASSWORD_FORGOT_ALERT 101
#define kMobileNumberKey    @"mobile_nr"

@interface LogInViewController ()
@property (nonatomic, assign) BOOL alertShown;
@property (nonatomic, strong) NSString *user;
@property (nonatomic, strong) VIAScene *scene;
@property (nonatomic) NSUInteger fetchAccountRetryCount;
@end

@implementation LogInViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UITapGestureRecognizer *tg = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(deselectAllTextFields:)];
    [self.view addGestureRecognizer:tg];

    self.fetchAccountRetryCount = 0;

    self.logoView.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));

    // animate logo to top
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self moveLogoOutOfScreen];
    });
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

/**
 * Deselect all textfields when a user taps somewhere in the view.
 */
- (void)deselectAllTextFields:(UITapGestureRecognizer*)recognizer {
    [self.loginFormView.usernameField resignFirstResponder];
    [self.loginFormView.passwordField resignFirstResponder];
    [self.configureFormView.phoneNumberField resignFirstResponder];
    [self.forgotPasswordView.emailTextfield resignFirstResponder];
}

/**
 * clears all text field contents from all views
 */
- (void)clearAllTextFields {
    self.loginFormView.usernameField.text = nil;
    self.loginFormView.passwordField.text = nil;
    self.configureFormView.phoneNumberField.text = nil;
    self.configureFormView.outgoingNumberLabel.text = nil;
    self.forgotPasswordView.emailTextfield.text = nil;
}

#pragma mark - UIView lifecycle methods.

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [GAITracker trackScreenForControllerName:NSStringFromClass([self class])];
    [self clearAllTextFields];
    [self addObservers];
}

/*
 - Set all keyboard types and return keys for the textFields when the view did appear.
 - Furthermore create login flow through the Return key.
 */
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.forgotPasswordView.requestPasswordButton.enabled = NO;

    //to be able/disable the enable the request password button
    [self.forgotPasswordView.emailTextfield addTarget:self action:@selector(forgotPasswordViewTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

    // Make text field react to Enter to login!
    [self.loginFormView setTextFieldDelegate:self];
    [self.configureFormView setTextFieldDelegate:self];
    [self.forgotPasswordView.emailTextfield setDelegate:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self removeObservers];
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    self.alertShown = NO;
}

#pragma mark - UITextField delegate methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([self.loginFormView.usernameField isEqual:textField]) {
        // TODO: focus on password field
        [textField resignFirstResponder];
        [self.loginFormView.passwordField becomeFirstResponder];
    } else if ([self.loginFormView.passwordField isEqual:textField]) {
        NSString *username = [self.loginFormView.usernameField text];
        NSString *password = [self.loginFormView.passwordField text];
        if ([username length] > 0 && [password length] > 0) {
            [self continueFromLoginFormViewToConfigureFormView];
            return YES;
        } else {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No login data", nil)
                                        message:NSLocalizedString(@"Enter Your email address and password to login.", nil)
                                       delegate:self
                              cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                              otherButtonTitles:nil]
             show];
            self.alertShown = YES;
            return NO;
        }
    } else if ([self.configureFormView.phoneNumberField isEqual:textField]) {
        [textField resignFirstResponder];
        [self continueFromConfigureFormViewToUnlockView];
        return YES;
    } else if ([self.forgotPasswordView.emailTextfield isEqual:textField]) {
        NSString *emailRegEx = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
        if ([[NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx]
             evaluateWithObject:textField.text]) {
            [self resetPasswordWithEmail:textField.text];
            [self animateForgotPasswordViewToVisible:0.f delay:0.8];
            [self animateLoginViewToVisible:1.f delay:0.f];
            return YES;
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry!", nil)
                                                            message:NSLocalizedString(@"Please enter a valid email address.", nil)
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                                  otherButtonTitles:nil];
            [alert show];
            self.alertShown = YES;
        }
    }
    return NO;
}

//Checks have been done to ensure the text fields have data, otherwise the button would not be clickable.
- (IBAction)loginButtonPushed:(UIButton *)sender {
    [self continueFromLoginFormViewToConfigureFormView];
}

- (void)forgotPasswordViewTextFieldDidChange:(UITextField *)textField {
    NSString *emailRegEx = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
    if ([[NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx]
         evaluateWithObject:textField.text])
        self.forgotPasswordView.requestPasswordButton.enabled = YES;
    else
        self.forgotPasswordView.requestPasswordButton.enabled = NO;
}

//Check for valid email is done, otherwise the button would not be enabled.
- (IBAction)requestPasswordButtonPressed:(UIButton *)sender {
    [self resetPasswordWithEmail:self.forgotPasswordView.emailTextfield.text];
}

- (IBAction)configureViewContinueButtonPressed:(UIButton *)sender {
    [self continueFromConfigureFormViewToUnlockView];
}

- (void)continueFromLoginFormViewToConfigureFormView {
    NSString *username = self.loginFormView.usernameField.text;
    NSString *password = self.loginFormView.passwordField.text;
    [self doLoginCheckWithUname:username password:password successBlock:^{
        [self retrievePhoneNumbersWithSuccessBlock:nil];
    }];
    [self deselectAllTextFields:nil];
}

- (void)continueFromConfigureFormViewToUnlockView {
    NSString *newNumber = self.configureFormView.phoneNumberField.text;
    [SVProgressHUD showWithStatus:NSLocalizedString(@"SAVING_NUMBER...", nil) maskType:SVProgressHUDMaskTypeGradient];

    //Force pushing the mobile number to the server. Covers the case where a user has set his mobile number in v1.x which was not pushed to server yet.
    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] pushMobileNumber:newNumber forcePush:YES success:^{
        [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"NUMBER_SAVED_SUCCESS", nil)];

        //Now that numbers have been saved, localy stored phone number and server side mobile number are in sync,
        //Migration was completed succesfully
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"v2.0_MigrationComplete"];

        [self.configureFormView.phoneNumberField resignFirstResponder];
        [self animateConfigureViewToVisible:0.f delay:0.f]; // Hide
        [self animateUnlockViewToVisible:1.f delay:1.5f];    // Show
        [self.scene runActThree];                     // Animate the clouds
        if ([SystemUser currentUser].sipEnabled) {
            [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {}];
        }
    } failure:^(NSString *localizedErrorString) {
        [SVProgressHUD dismiss];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                        message:localizedErrorString
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                              otherButtonTitles:nil];
        [alert show];
    }];
}

#pragma mark Keyboard

/**
 * Add observers to check when keyboards is hidden and shown, to know when to animatie view up or down
 */
- (void)addObservers{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification*)notification {
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];

    NSValue *keyboardRect = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGFloat keyboardHeight = CGRectGetHeight([keyboardRect CGRectValue]);

    // After the animation, the respective view should be centered on the remaining screen height (original screen height -keyboard height)
    CGFloat remainingScreenHeight = CGRectGetHeight(self.view.frame) - keyboardHeight;
    // Divide the remaining screen height by 2, this will be the center of the displayed view
    CGFloat newCenter = lroundf(remainingScreenHeight /2);

    // Move the left top most cloud away to make the text visable (white on white)
    [self.scene animateCloudsOutOfViewWithDuration:duration];

    // Animate every form once to prevent jumping screens.
    // Only animate when form is visible.
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:(curve << 16)
                     animations:^{
                         if (self.loginFormView.alpha > 0 && !self.loginFormView.isMoved) {
                             self.loginFormView.center = CGPointMake(self.loginFormView.center.x, newCenter);
                         }
                         if (self.configureFormView.alpha > 0 && !self.configureFormView.isMoved) {
                             self.configureFormView.center = CGPointMake(self.configureFormView.center.x, newCenter);
                         }
                         if (self.forgotPasswordView.alpha > 0 && !self.forgotPasswordView.isMoved) {
                             self.forgotPasswordView.center = CGPointMake(self.forgotPasswordView.center.x, newCenter);
                         }
                     }
                     completion:^(BOOL finished) {
                         if (self.loginFormView.alpha > 0) {
                             self.loginFormView.isMoved = YES;
                         }
                         if (self.configureFormView.alpha > 0) {
                             self.configureFormView.isMoved = YES;
                         }
                         if (self.forgotPasswordView.alpha > 0) {
                             self.forgotPasswordView.isMoved = YES;
                         }
                     }];
}

- (void)keyboardWillHide:(NSNotification*)notification {
    if(!self.alertShown) {
        NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        [self.scene animateCloudsIntoViewWithDuration:duration];
    }
}

#pragma mark - Helper method that greets you when you reach the lock screen.
- (void)setLockScreenFriendlyNameWithResponse:(id)responseObject {
    if ([responseObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *userDict = (NSDictionary*)responseObject;
        NSString *firstName = userDict[@"first_name"];
        NSString *lastName = userDict[@"last_name"];
        NSString *greeting;
        if (firstName && lastName)
            greeting = [NSString stringWithFormat:@"%@ %@!", userDict[@"first_name"], userDict[@"last_name"]];

        [self.unlockView.greetingsLabel setText:greeting];
    }
}

#pragma mark - Navigation actions
- (void)moveLogoOutOfScreen { /* Act one (1) */
    // Create an animation scenes that transitions to configure view.
    // VIAScene uses view dimensions to calculate the positions of clouds, at this point the self.view is resized correctly from xib values.
    self.scene = [[VIAScene alloc] initWithView:self.view];

    void (^logoAnimations)(void) = ^{
        [self.logoView setCenter:CGPointMake(self.logoView.center.x, -CGRectGetHeight(self.logoView.frame))];
    };
    [UIView animateWithDuration:2.2 animations:logoAnimations];

    switch (self.screenToShow) {
        case OnboardingScreenLogin:
            [self.scene runActOne];
            break;
        case OnboardingScreenConfigure:
            [self.scene runActOneInstantly];  // Remove the scene 1 clouds instantly
            [self.scene runActTwo];           // Animate the clouds
            [self retrievePhoneNumbersWithSuccessBlock:nil];
            break;
        default:
            //Show the login screen as default
            [self.scene runActOne];
            break;
    }

    void (^afterLogoAnimations)(void) = ^{
        switch (self.screenToShow) {
            case OnboardingScreenLogin:
                [self animateLoginViewToVisible:1.f delay:0.f]; // show
                break;
            case OnboardingScreenConfigure:
                [self animateConfigureViewToVisible:1.f delay:0.f]; // Show
                break;
            default:
                //Show the login screen as default
                [self.scene runActOne];
                break;
        }
    };
    [UIView animateWithDuration:1.9 delay:0.f options:UIViewAnimationOptionCurveEaseOut animations:afterLogoAnimations completion:nil];
}

- (IBAction)openForgotPassword:(id)sender {
    [self.loginFormView.usernameField resignFirstResponder];
    [self.loginFormView.passwordField resignFirstResponder];
    self.forgotPasswordView.emailTextfield.text = nil;

    [self animateLoginViewToVisible:0.f delay:0.f];
    [self animateForgotPasswordViewToVisible:1.f delay:2.f];
}

- (IBAction)closeButtonPressed:(UIButton *)sender {
    [self.forgotPasswordView.emailTextfield resignFirstResponder];

    [self animateForgotPasswordViewToVisible:0.f delay:0.f];
    [self animateLoginViewToVisible:1.f delay:1.5f];
}

- (void)resetPasswordWithEmail:(NSString*)email {
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Sending email...", nil) maskType:SVProgressHUDMaskTypeGradient];
    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] passwordResetWithEmail:email success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Email sent successfully.", nil)];

        [self animateLoginViewToVisible:1.f delay:1.f];
        [self animateForgotPasswordViewToVisible:0.f delay:0.8f];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Failed to send email.", nil)];
        [self animateLoginViewToVisible:1.f delay:0.8f];
        [self animateForgotPasswordViewToVisible:0.f delay:0.8];
    }];
}

- (void)openConfigurationInstructions:(id)sender {
    PBWebViewController *webViewController = [[PBWebViewController alloc] init];

    NSString *onboardingUrl = [Configuration UrlForKey:NSLocalizedString(@"onboarding", @"Reference to URL String in the config.plist to the localized onboarding information page")];
    webViewController.URL = [NSURL URLWithString:onboardingUrl];
    webViewController.showsNavigationToolbar = YES;
    webViewController.hidesBottomBarWhenPushed = YES;
    webViewController.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeConfigurationInstructions)];
    webViewController.navigationItem.rightBarButtonItem = cancelButton;

    [self presentViewController:navController animated:YES completion:nil];
}

- (void)closeConfigurationInstructions {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)doLoginCheckWithUname:(NSString *)username password:(NSString *)password successBlock:(void (^)())success {
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Logging in...", nil) maskType:SVProgressHUDMaskTypeGradient];
    SystemUser *currentUser = [SystemUser currentUser];
    [currentUser loginWithUser:username password:password completion:^(BOOL loggedin) {
        [SVProgressHUD dismiss];
        if (loggedin) {
            [self animateLoginViewToVisible:0.f delay:0.f];     // Hide
            [self animateConfigureViewToVisible:1.f delay:0.f]; // Show
            [self.scene runActTwo];                       // Animate the clouds

            //If a success block was provided, execute it
            if (success) {
                success();
            }
        }
    }];
}

- (void)retrievePhoneNumbersWithSuccessBlock:(void (^)())success {
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Retrieving phone numbers...", nil) maskType:SVProgressHUDMaskTypeGradient];
    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] userProfileWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        self.fetchAccountRetryCount = 0; // Reset the retry count
        NSString *outgoingNumber = [SystemUser currentUser].localizedOutgoingNumber;
        if (outgoingNumber) {
            [self.configureFormView.outgoingNumberLabel setText:outgoingNumber];
        } else {
            [self.configureFormView.outgoingNumberLabel setText:@""];
        }

        NSString *localStoreMobileNumber = [SystemUser currentUser].mobileNumber;
        //Give preference to the user entered phone number over the phone number stored on the server
        if ([localStoreMobileNumber length] > 0) {
            self.configureFormView.phoneNumberField.text = localStoreMobileNumber;
        } else {
            NSString *mobile_nr = [responseObject objectForKey:kMobileNumberKey];
            //if the response also contained the mobile nr, display it to the user
            if ([mobile_nr isKindOfClass:[NSString class]]) {
                self.configureFormView.phoneNumberField.text = mobile_nr;
            }
        }

        [SVProgressHUD dismiss];

        [self setLockScreenFriendlyNameWithResponse:responseObject];

        //If a success block was provided, execute it
        if (success) {
            success();
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [SVProgressHUD dismiss];
        self.fetchAccountRetryCount++;
        if (self.fetchAccountRetryCount != 3) { // When we retried 3 times
            [self retrievePhoneNumbersWithSuccessBlock:nil];
        } else {
            [self.configureFormView.outgoingNumberLabel setUserInteractionEnabled:YES];
            [self.configureFormView.outgoingNumberLabel setText:NSLocalizedString(@"Enter phonenumber manually", nil)];

            [UIAlertView showWithTitle:NSLocalizedString(@"Error", nil)
                               message:NSLocalizedString(@"Error while retrieving your outgoing number, please enter manually", nil)
                                 style:UIAlertViewStylePlainTextInput
                     cancelButtonTitle:nil
                     otherButtonTitles:@[NSLocalizedString(@"Ok", nil)]
                              tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                  //TODO: do something with the entered number
                                  NSLog(@"outgoing number = %@", [alertView textFieldAtIndex:0].text);

                              }];

        }
    }];
}

#pragma mark - Navigation animations

- (void)animateLoginViewToVisible:(CGFloat)alpha delay:(CGFloat)delay { /* Act one (2) */
    void(^animations)(void) = ^{
        [self.loginFormView setAlpha:alpha];
    };
    void(^completion)(BOOL) = ^(BOOL finished) {
        if (alpha == 1.f) {
            [self.loginFormView.usernameField becomeFirstResponder];
        } else if (alpha == 0.f) {
            [self.loginFormView.usernameField resignFirstResponder];
        }
    };
    [UIView animateWithDuration:0.2f
                          delay:delay
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:animations
                     completion:completion];
}

- (void)animateForgotPasswordViewToVisible:(CGFloat)alpha delay:(CGFloat)delay {
    void(^animations)(void) = ^{
        [self.closeButton setAlpha:alpha];
        [self.forgotPasswordView setAlpha:alpha];
    };
    void(^completion)(BOOL) = ^(BOOL finished) {
        if (alpha == 1.f) {
            [self.forgotPasswordView.emailTextfield becomeFirstResponder];
        } else if (alpha == 0.f) {
            [self.forgotPasswordView.emailTextfield resignFirstResponder];
        }
    };
    [UIView animateWithDuration:0.8f
                          delay:delay
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:animations
                     completion:completion];
}

- (void)animateConfigureViewToVisible:(CGFloat)alpha delay:(CGFloat)delay { /* Act two */
    void(^animations)(void) = ^{
        [self.configureFormView setAlpha:alpha];
    };
    void(^completion)(BOOL) = ^(BOOL finished) {
        if (alpha == 1.f) {
            [self.configureFormView.phoneNumberField becomeFirstResponder];
        } else if (alpha == 0.f) {
            [self.configureFormView.phoneNumberField resignFirstResponder];
        }
    };
    [UIView animateWithDuration:2.2f
                          delay:delay
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:animations
                     completion:completion];

}

- (void)animateUnlockViewToVisible:(CGFloat)alpha delay:(CGFloat)delay { /* act three */
    void(^animations)(void) = ^{
        [self.unlockView setAlpha:alpha];
    };
    // Add a tap to the view to close immediately.
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleUnlockTap:)];
    [self.view addGestureRecognizer:tap];

    [UIView animateWithDuration:2.2f
                          delay:delay
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                     animations:animations
                     completion:^(BOOL finished) {
                         // If the animation finished normally, start the timer otherwise we were interrupted with the tap
                         if (finished) {
                             // Automatically continue after 2 seconds
                             [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(unlockIt) userInfo:nil repeats:NO];
                         }
                     }];

}

- (void)handleUnlockTap:(UITapGestureRecognizer *)gesture {
    // Did we get a succesfull tap?
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        // Move out of the welcome screen
        [self unlockIt];
    }
}

- (void)unlockIt {
    // Put here what happens when it is unlocked
    [self.scene clean];
    [self dismissViewControllerAnimated:YES completion:^{
        [self.unlockView setAlpha:0.f];
        [self.logoView setAlpha:1.f];
        [self.logoView setCenter:self.view.center];
    }];
}

- (IBAction)mobileNumberInfoButtonPressed:(UIButton *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Mobile phone number", nil) message:NSLocalizedString(@"To make Two step calling possible, we need to have your mobile phone number.", nil) preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", nil) style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:defaultAction];

    [self presentViewController:alert animated:YES completion:nil];
}

@end
