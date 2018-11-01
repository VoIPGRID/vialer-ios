//
//  LogInViewController.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "LogInViewController.h"

#import "AnimatedImageView.h"
#import <AVFoundation/AVFoundation.h>
#import "PBWebViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "SettingsViewController.h"
#import "SVProgressHUD.h"
#import "SystemUser.h"
#import "UIAlertController+Vialer.h"
#import "UIView+RoundedStyle.h"
#import "Vialer-Swift.h"
#import "VIAScene.h"
#import "VoIPGRIDRequestOperationManager+ForgotPassword.h"


static NSString * const LoginViewControllerMobileNumberKey = @"mobile_nr";
static NSString * const LogInViewControllerLogoImageName = @"logo";
static NSString * const LoginViewControllerSettingsStoryboard = @"SettingsStoryboard";
static NSString * const LoginViewControllerSettingsNavigationControllerStoryboard = @"SettingsNavigationControllerStoryboard";

@interface LogInViewController ()
@property (assign, nonatomic) BOOL alertShown;
@property (strong, nonatomic) NSString *user;
@property (strong, nonatomic) VIAScene *scene;
@property (strong, nonatomic) UITapGestureRecognizer *tapToUnlock;
@property (strong, nonatomic) VoIPGRIDRequestOperationManager *operationManager;
@end

@implementation LogInViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UITapGestureRecognizer *tg = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(deselectAllTextFields:)];
    [self.view addGestureRecognizer:tg];

    self.logoView.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - properties

- (SystemUser *)currentUser {
    if (!_currentUser) {
        _currentUser = [SystemUser currentUser];
    }
    return _currentUser;
}

- (VIAScene *)scene {
    if (!_scene) {
        _scene = [[VIAScene alloc] initWithView:self.view];
    }
    return _scene;
}

- (UITapGestureRecognizer *)tapToUnlock {
    if (!_tapToUnlock) {
        _tapToUnlock = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleUnlockTap:)];
    }
    return _tapToUnlock;
}

- (VoIPGRIDRequestOperationManager *)operationManager {
    if (!_operationManager) {
        _operationManager = [[VoIPGRIDRequestOperationManager alloc] initWithDefaultBaseURL];
    }
    return _operationManager;
}

/**
 * Deselect all textfields when a user taps somewhere in the view.
 */
- (void)deselectAllTextFields:(UITapGestureRecognizer*)recognizer {
    [self.loginFormView.usernameField resignFirstResponder];
    [self.loginFormView.passwordField resignFirstResponder];
    [self.twoFactorAuthenticationView.tokenField resignFirstResponder];
    [self.configureFormView.phoneNumberField resignFirstResponder];
    [self.forgotPasswordView.emailTextfield resignFirstResponder];
}

/**
 * clears all text field contents from all views
 */
- (void)clearAllTextFields {
    self.loginFormView.usernameField.text = nil;
    self.loginFormView.passwordField.text = nil;
    self.twoFactorAuthenticationView.tokenField.text = nil;
    self.configureFormView.phoneNumberField.text = nil;
    self.configureFormView.outgoingNumberLabel.text = nil;
    self.forgotPasswordView.emailTextfield.text = nil;
}

#pragma mark - UIView lifecycle methods.

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [VialerGAITracker trackScreenForControllerWithName:NSStringFromClass([self class])];
    [self clearAllTextFields];
    [self addObservers];

    // animate logo to top
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self moveLogoOutOfScreen];
    });
}

/*
 - Set all keyboard types and return keys for the textFields when the view did appear.
 - Furthermore create login flow through the Return key.
 */
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.forgotPasswordView.requestPasswordButton.enabled = NO;

    //to be able/disable the enable the request password button
    [self.forgotPasswordView.emailTextfield addTarget:self action:@selector(checkIfEmailIsSetInEmailTextField) forControlEvents:UIControlEventEditingChanged];

    // Make text field react to Enter to login!
    [self.loginFormView setTextFieldDelegate:self];
    [self.twoFactorAuthenticationView setTextFieldDelegate:self];
    [self.configureFormView setTextFieldDelegate:self];
    self.forgotPasswordView.emailTextfield.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [self removeObservers];
    [SVProgressHUD dismiss];
    [super viewWillDisappear:animated];
}

#pragma mark - UITextField delegate methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([self.loginFormView.usernameField isEqual:textField]) {
        [textField resignFirstResponder];
        [self.loginFormView.passwordField becomeFirstResponder];
    } else if ([self.loginFormView.passwordField isEqual:textField]) {
        NSString *username = self.loginFormView.usernameField.text;
        NSString *password = self.loginFormView.passwordField.text;
        if ([username length] > 0 && [password length] > 0) {
            [self continueFromLoginView];
            return YES;
        } else {
            self.alertShown = YES;
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:NSLocalizedString(@"No login data", nil)
                                                  message:NSLocalizedString(@"Enter Your email address and password to login.", nil)
                                                  preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", nil)
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
                                                                 self.alertShown = NO;
                                                             }];

            [alertController addAction:okAction];
            [self presentViewController:alertController animated:YES completion:nil];

            return NO;
        }
    } else if ([self.twoFactorAuthenticationView.tokenField isEqual:textField]) {
        [textField resignFirstResponder];
        if ([self.twoFactorAuthenticationView.tokenField.text length] > 0) {
            [self continueFromTwoFactorAuthenticationViewToConfigureView];
            return YES;
        } else {

            return NO;
        }
        return YES;
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
            self.alertShown = YES;
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:NSLocalizedString(@"Sorry!", nil)
                                                  message:NSLocalizedString(@"Please enter a valid email address.", nil)
                                                  preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", nil)
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
                                                                 self.alertShown = NO;
                                                             }];

            [alertController addAction:okAction];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }
    return NO;
}

// Checks have been done to ensure the text fields have data, otherwise the button would not be clickable.
- (IBAction)loginButtonPushed:(UIButton *)sender {
    [self continueFromLoginView];
}

- (void)checkIfEmailIsSetInEmailTextField {
    NSString *emailRegEx = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
    if ([[NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx]
         evaluateWithObject:self.forgotPasswordView.emailTextfield.text])
        self.forgotPasswordView.requestPasswordButton.enabled = YES;
    else
        self.forgotPasswordView.requestPasswordButton.enabled = NO;
}

// Check for valid email is done, otherwise the button would not be enabled.
- (IBAction)requestPasswordButtonPressed:(UIButton *)sender {
    [self resetPasswordWithEmail:self.forgotPasswordView.emailTextfield.text];
}

- (IBAction)configureViewContinueButtonPressed:(UIButton *)sender {
    if ([self.configureFormView.outgoingNumberLabel.text isEqualToString:@""]){
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Missing outgoing number", nil)
                                                                       message:NSLocalizedString(@"Please note that as you don\'t own an outgoing number, you may only call internal numbers",nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {[self continueFromConfigureFormViewToUnlockView];}];
        
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        [alert addAction:cancelAction];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        [self continueFromConfigureFormViewToUnlockView];
    }
    
    
    
}

- (IBAction)twoFactorAuthenticationViewContinueButtonPressed:(UIButton *)sender {
    [self continueFromTwoFactorAuthenticationViewToConfigureView];
}

- (void)continueFromLoginView {
    NSString *username = self.loginFormView.usernameField.text;
    NSString *password = self.loginFormView.passwordField.text;

    [self doLoginCheckForTwoFactorWithUserName:username password:password token:@"" successBlock:^ {
        if ([SystemUser currentUser].apiToken != nil && ![[SystemUser currentUser].apiToken isEqualToString:@""]) {
            [self retrievePhoneNumbersWithSuccessBlock:nil];
        }
    }];
    [self deselectAllTextFields:nil];
}

- (void)continueFromTwoFactorAuthenticationViewToConfigureView {
    NSString *token = self.twoFactorAuthenticationView.tokenField.text;

    [self doLoginCheckForTwoFactorWithUserName:self.loginFormView.usernameField.text password:self.loginFormView.passwordField.text token:token successBlock:^{
        if (![[SystemUser currentUser].apiToken isEqualToString:@""]) {
            [self retrievePhoneNumbersWithSuccessBlock:nil];
        }
    }];
    [self deselectAllTextFields:nil];
}

- (void)continueFromConfigureFormViewToUnlockView {
    NSString *newNumber = self.configureFormView.phoneNumberField.text;
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Saving number...", nil)];

    [[SystemUser currentUser] updateMobileNumber:newNumber withCompletion:^(BOOL success, NSError *error) {
        [SVProgressHUD dismiss];
        if (success) {
            [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Number saved", nil)];

            [self.configureFormView.phoneNumberField resignFirstResponder];
            [self animateConfigureViewToVisible:0.f delay:0.f]; // Hide
            [self animateUnlockViewToVisible:1.f delay:1.5f];   // Show
            [self.scene runActThree];                           // Animate the clouds

            if ([SystemUser currentUser].sipEnabled) {
                [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
                    if (!granted) {
                        UIAlertController *alertController = [UIAlertController
                                                              alertControllerWithTitle:NSLocalizedString(@"Microphone Access Denied", nil)
                                                              message:NSLocalizedString(@"You must allow microphone access in Settings > Privacy > Microphone.", nil)
                                                              preferredStyle:UIAlertControllerStyleAlert];

                        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                               style:UIAlertActionStyleCancel
                                                                             handler:nil];

                        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", nil)
                                                                           style:UIAlertActionStyleDefault
                                                                         handler:^(UIAlertAction *action) {
                                                                             [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                                                                         }];

                        [alertController addAction:cancelAction];
                        [alertController addAction:okAction];
                        [self presentViewController:alertController animated:YES completion:nil];
                    }
                }];
            }
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error saving number", nil)
                                                                           message:error.localizedDescription
                                                              andDefaultButtonText:NSLocalizedString(@"Ok", nil)];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}

#pragma mark Keyboard

/**
 * Add observers to check when keyboards is hidden and shown, to know when to animatie view up or down
 */
- (void)addObservers{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecameActive:) name:UIApplicationWillEnterForegroundNotification object:nil];

}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
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

- (void)keyboardWillHide:(NSNotification *)notification {
    if(!self.alertShown) {
        NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        [self.scene animateCloudsIntoViewWithDuration:duration];
    }
}

- (void)appBecameActive:(NSNotification *)notification {
    // Check if the Two Factor Authenitication view is active. If so check the clipboard for a token code.
    if (self.twoFactorAuthenticationView.alpha == 1) {
        VialerLogDebug(@"Check the PasteBoard for a 6 digits token field");
        NSString *tokenFromPasteBoard = [TokenFromPasteBoard getToken];
        if (![tokenFromPasteBoard isEqualToString:@""]) {
            self.twoFactorAuthenticationView.tokenField.text = @"";
            self.twoFactorAuthenticationView.tokenField.text = tokenFromPasteBoard;
        }
    }
}

#pragma mark - Navigation actions
- (void)moveLogoOutOfScreen { /* Act one (1) */
    // Create an animation scenes that transitions to configure view.

    if (CGRectGetMaxY(self.logoView.frame) > 0) {
        [UIView animateWithDuration:2.2 animations:^{
            [self.logoView setCenter:CGPointMake(self.logoView.center.x, -CGRectGetHeight(self.logoView.frame))];
        }];
    }

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

    [UIView animateWithDuration:1.9 delay:0.f options:UIViewAnimationOptionCurveEaseOut animations:^{
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
    } completion:nil];
}

- (IBAction)openForgotPassword:(id)sender {
    [self.loginFormView.usernameField resignFirstResponder];
    [self.loginFormView.passwordField resignFirstResponder];
    self.forgotPasswordView.emailTextfield.text = self.loginFormView.usernameField.text;

    [self animateLoginViewToVisible:0.f delay:0.f];
    [self animateForgotPasswordViewToVisible:1.f delay:2.f];
}

- (IBAction)closeButtonPressed:(UIButton *)sender {
    [self.forgotPasswordView.emailTextfield resignFirstResponder];

    [self animateForgotPasswordViewToVisible:0.f delay:0.f];
    [self animateLoginViewToVisible:1.f delay:1.5f];
}

- (void)resetPasswordWithEmail:(NSString*)email {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Send email?", nil)
                                                                   message:[NSString stringWithFormat:NSLocalizedString(@"If your email address is %@ we will send you an email with instructions to reset your password.", nil), email]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self sendEmail:email];
    }];
    [alert addAction:okAction];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAction];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)sendEmail:(NSString *)email {
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Sending email...", nil)];

    [self.operationManager passwordResetWithEmail:email withCompletion:^(AFHTTPRequestOperation *operation, NSDictionary *responseData, NSError *error) {
        // Check if there was an error.
        if (error) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Failed to send email.", nil)];
            [self animateLoginViewToVisible:1.f delay:0.8f];
            [self animateForgotPasswordViewToVisible:0.f delay:0.8];
            return;
        }

        [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Email sent successfully.", nil)];
        [self animateLoginViewToVisible:1.f delay:1.f];
        [self animateForgotPasswordViewToVisible:0.f delay:0.8f];
    }];
}

- (void)openConfigurationInstructions:(id)sender {
    PBWebViewController *webViewController = [[PBWebViewController alloc] init];

    OnboardingLanguage onboardingLanuage = OnboardingLanguageEn;
    if ([[[NSBundle mainBundle] preferredLocalizations][0] isEqualToString:@"nl"]) {
        onboardingLanuage = OnboardingLanguageNl;
    }

    NSString *onboardingUrl = [[UrlsConfiguration shared] onboardingUrlWithLanguage: onboardingLanuage];
    webViewController.URL = [NSURL URLWithString:onboardingUrl];
    webViewController.showsNavigationToolbar = NO;
    webViewController.hidesBottomBarWhenPushed = YES;
    webViewController.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:LogInViewControllerLogoImageName]];

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil) style:UIBarButtonItemStylePlain target:self action:@selector(closeConfigurationInstructions)];
    webViewController.navigationItem.leftBarButtonItem = cancelButton;

    [self presentViewController:navController animated:YES completion:nil];
}

- (void)closeConfigurationInstructions {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)doLoginCheckForTwoFactorWithUserName:(NSString *)username password:(NSString *)password token:(NSString *)token successBlock:(void(^)(void))success {
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Logging in...", nil)];
    [self.currentUser loginToCheckTwoFactorWithUserName:username password:password andToken:token completion:^(BOOL loggedin, BOOL tokenRequired, NSError *error) {
        [SVProgressHUD dismiss];

        if (!loggedin && tokenRequired && error && (error.code == SystemUserTwoFactorAuthenticationTokenInvalid || error.code == SystemUserTwoFactorAuthenticationTokenRequired)) {
            [self animateLoginViewToVisible:0.f delay:0.f]; // Hide
            [self animateTwoFactorAuthenticationViewToVisible:1.f delay:0.f];

            [self.scene runActOneAndHalf];

            if (error && error.code == SystemUserTwoFactorAuthenticationTokenInvalid) {
                [self presentViewController:[UIAlertController alertControllerWithTitle:NSLocalizedString(@"Token invalid", nil)
                                                                                message:NSLocalizedString(@"The two-factor authentication token is invalid", nil)
                                                                   andDefaultButtonText:NSLocalizedString(@"Ok", nil)]
                                   animated:YES
                                 completion:nil];
            } else if (success) {
                success();
            }
        } else if (loggedin) {
            // Hide the two factor authentication view.
            [self animateTwoFactorAuthenticationViewToVisible:0.f delay:0.f];
            // Hide the login view.
            [self animateLoginViewToVisible:0.f delay:0.f];
            // Show the configure the app view.
            [self animateConfigureViewToVisible:1.f delay:0.f];

            [self.scene runActTwo];

            //If a success block was provided, execute it
            if (success) {
                success();
            }
        } else if (error && error.code == SystemUserErrorUserTypeNotAllowed) {
            self.loginFormView.passwordField.text = @"";
            self.loginFormView.usernameField.text = @"";
            [self presentViewController:[UIAlertController alertControllerWithTitle:NSLocalizedString(@"Login failed", nil)
                                                                            message:NSLocalizedString(@"This user is not allowed to use the app", nil)
                                                               andDefaultButtonText:NSLocalizedString(@"Ok", nil)]
                               animated:YES
                             completion:nil];
        } else {
            self.loginFormView.passwordField.text = @"";
            [self presentViewController:[UIAlertController alertControllerWithTitle:NSLocalizedString(@"Login failed", nil)
                                                                            message:NSLocalizedString(@"Your email and/or password is incorrect.", nil)
                                                               andDefaultButtonText:NSLocalizedString(@"Ok", nil)]
                               animated:YES
                             completion:nil];
        }
    }];
}

- (void)retrievePhoneNumbersWithSuccessBlock:(void (^)(void))success {
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Retrieving phone numbers...", nil)];
    [[SystemUser currentUser] updateSystemUserFromVGWithCompletion:^(NSError *error) {
    [SVProgressHUD dismiss];

        if (!error) {
            SystemUser *systemUser = [SystemUser currentUser];
            if ([systemUser.outgoingNumber isKindOfClass:[NSNull class]] || [systemUser.outgoingNumber isEqualToString:@""])
            {
                self.configureFormView.outgoingNumberLabel.text = @"";
                self.configureFormView.outgoingNumberDescriptionField.text = @"";
            } else {
                self.configureFormView.outgoingNumberLabel.text = systemUser.outgoingNumber;
            }
            self.configureFormView.phoneNumberField.text = systemUser.mobileNumber;
            self.unlockView.greetingsLabel.text = systemUser.displayName;

            //If a success block was provided, execute it
            if (success) {
                success();
            }
        } else {
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                  message:NSLocalizedString(@"Error while retrieving your outgoing number, make sure you are connected to the internet.", nil)
                                                  preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction *retryAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Retry", nil)
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction *action) {
                                                                    [self retrievePhoneNumbersWithSuccessBlock:success];
                                                                }];

            [alertController addAction:retryAction];
            [self presentViewController:alertController animated:YES completion:nil];
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

- (void)animateTwoFactorAuthenticationViewToVisible:(CGFloat)alpha delay:(CGFloat)delay {
    void(^animations)(void) = ^{
        [self.twoFactorAuthenticationView setAlpha:alpha];
    };
    void(^completion)(BOOL) = ^(BOOL finished) {
        if (alpha == 1.f) {
            [self.twoFactorAuthenticationView.tokenField becomeFirstResponder];
        } else if (alpha == 0.f) {
            [self.twoFactorAuthenticationView.tokenField resignFirstResponder];
        }
    };
    [UIView animateWithDuration:0.8f
                          delay:delay
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:animations
                     completion:completion];
}

- (void)animateForgotPasswordViewToVisible:(CGFloat)alpha delay:(CGFloat)delay {
    if (![self.forgotPasswordView.emailTextfield.text length]) {
        self.forgotPasswordView.emailTextfield.text = self.currentUser.username;
    }
    [self checkIfEmailIsSetInEmailTextField];
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
    [self.view addGestureRecognizer:self.tapToUnlock];

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
    if (!self.currentUser.sipAccount) {
        UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:LoginViewControllerSettingsStoryboard bundle:nil];
        UINavigationController *navigationController = [storyBoard instantiateViewControllerWithIdentifier:LoginViewControllerSettingsNavigationControllerStoryboard];
        SettingsViewController *viewController = navigationController.viewControllers[0];
        viewController.showSIPAccountWebview = YES;
        [self presentViewController:navigationController animated:NO completion:nil];
    } else {
        // Enable SIP for this user after onboarding.
        self.currentUser.sipEnabled = YES;

        // Put here what happens when it is unlocked.
        [self dismissViewControllerAnimated:NO completion:^{
            [self.unlockView setAlpha:0.f];
            [self.logoView setAlpha:1.f];
            [self.logoView setCenter:self.view.center];

        }];
    }
    // Remove tap.
    [self.view removeGestureRecognizer:self.tapToUnlock];
}

- (IBAction)mobileNumberInfoButtonPressed:(UIButton *)sender {
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:NSLocalizedString(@"Mobile phone number", nil)
                                          message:NSLocalizedString(@"To make Two step calling possible, we need to have your mobile phone number.", nil)
                                          preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", nil)
                                                       style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
