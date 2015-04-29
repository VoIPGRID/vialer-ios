//
//  LogInViewController.m
//  Vialer
//
//  Created by Reinier Wieringa on 06/11/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "LogInViewController.h"
#import "VoIPGRIDRequestOperationManager.h"
#import "ConnectionHandler.h"

#import "SVProgressHUD.h"
#import "UIView+RoundedStyle.h"

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>

#import "AnimatedImageView.h"
#import "VIAScene.h"

#define SHOW_LOGIN_ALERT      100
#define PASSWORD_FORGOT_ALERT 101

@interface LogInViewController ()
@property (nonatomic, assign) BOOL loginAlertShown;
@property (nonatomic, strong) NSString *user;
@end

@implementation LogInViewController {
    BOOL UNLOCKED;
    VIAScene *_scene;
}

/** SLIDER: todo refactor to 'UnlockSlider' class */
- (IBAction)unlockIt {
    if (slideToUnlock.value == slideToUnlock.maximumValue) {  // if user slide to the most right side, stop the operation
        // Put here what happens when it is unlocked
        [_scene clean];
        [self dismissViewControllerAnimated:NO completion:^{
            [self.unlockView setAlpha:0.f];
            [self.logoView setAlpha:1.f];
            [self.logoView setCenter:self.view.center];
            slideToUnlock.value = 0.f;
            myLabel.alpha = 1.f;
            
        }];
        UNLOCKED = YES;
    } else {
        // user did not slide far enough, so return back to 0 position
        void (^animations)(void) = ^{
            slideToUnlock.value = 0.0;
            myLabel.alpha = 1.f;
        };
        [UIView animateWithDuration:0.35
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:animations
                         completion:nil];
    }
}

- (IBAction)fadeLabel {
    myLabel.alpha = slideToUnlock.maximumValue - slideToUnlock.value;  
}

/***/

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        UNLOCKED= NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [slideToUnlock setThumbImage: [UIImage imageNamed:@"slider-button.png"] forState:UIControlStateNormal];
    [slideToUnlock setMinimumTrackImage:[UIImage new] forState:UIControlStateNormal]; // preventthe bar to be shown
    [slideToUnlock setMaximumTrackImage:[UIImage new] forState:UIControlStateNormal]; // preventthe bar to be shown
}

#pragma mark - UIView lifecycle methods.
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Make text field react to Enter to login!
    [self.loginFormView setTextFieldDelegate:self];
    [self.configureFormView setTextFieldDelegate:self];

    // Create an animation scenes that transitions to configure view.
    _scene = [[VIAScene alloc] initWithView:self.view];
    
    // animate logo to top
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self animateLogoToTop];
    });
}

#pragma mark - Navigation animations
- (void)animateLogoToTop { /* Act one (1) */
    void (^logoAnimations)(void) = ^{
        [self.logoView setCenter:CGPointMake(self.logoView.center.x, -CGRectGetHeight(self.logoView.frame))];
    };
    [UIView animateWithDuration:2.4 animations:logoAnimations];

    [_scene runActOne];
    
    void (^loginAnimations)(void) = ^{
        [self animateLoginViewToVisible];
    };
    [UIView animateWithDuration:1.9 delay:0.f options:UIViewAnimationOptionCurveEaseOut animations:loginAnimations completion:nil];
}

- (void)animateLoginViewToVisible { /* Act one (2) */
    void(^animations)(void) = ^{
        [self.loginFormView setAlpha:1.f];
    };
    [UIView animateWithDuration:2.2f
                          delay:0.8f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:animations
                     completion:nil];
}

- (void)animateConfigureViewToVisible { /* Act two */
    void(^animations)(void) = ^{
        [self.loginFormView setAlpha:0.f];
        [self.configureFormView setAlpha:1.f];
    };
    [UIView animateWithDuration:2.2f
                          delay:0.8f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:animations
                     completion:nil];

    [_scene runActTwo];
}

- (void)animateUnlockViewToVisible { /* act three */
    void(^animations)(void) = ^{
        [self.configureFormView setAlpha:0.f];
        [self.unlockView setAlpha:1.f];
    };
    [UIView animateWithDuration:2.2f
                          delay:0.8f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:animations
                     completion:nil];
    
    [_scene runActThree];
}

#pragma mark - Navigation actions
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
   
    if ([self.loginFormView.emailField isSelectedField:textField] ||  [self.loginFormView.passwordField isSelectedField:textField]) {
        NSString *username = [self.loginFormView.emailField text];
        NSString *password = [self.loginFormView.passwordField text];
        if ([username length] > 0 && [password length] > 0) {
            [self doLoginCheckWithUname:username password:password];
            [textField resignFirstResponder];
            return YES;
        }
    } else if ([self.configureFormView.phoneNumberField isSelectedField:textField]) {
        [self retrieveOutgoingNumber];
        [textField resignFirstResponder];
        return YES;
    }
    return NO;
}

- (void)retrieveOutgoingNumber {
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Retrieving outgoing number...", nil) maskType:SVProgressHUDMaskTypeGradient];
    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] userProfileWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *outgoingNumber = [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] outgoingNumber];
        if (outgoingNumber) {
            [self.configureFormView.outgoingNumberField setText:outgoingNumber];
        } else {
            [self.configureFormView.outgoingNumberField setText:@""];
        }
        [SVProgressHUD dismiss];
        [self animateUnlockViewToVisible];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [SVProgressHUD dismiss];
    }];
}

- (void)doLoginCheckWithUname:(NSString *)username password:(NSString *)password {
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Logging in...", nil) maskType:SVProgressHUDMaskTypeGradient];
    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] loginWithUser:username password:password success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [SVProgressHUD dismiss];
        // Check if a SIP account
        if ([VoIPGRIDRequestOperationManager sharedRequestOperationManager].sipAccount) {
            [self animateConfigureViewToVisible];

            [[ConnectionHandler sharedConnectionHandler] sipConnect];
            [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {}];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry!", nil) message:NSLocalizedString(@"No active voice over internet account found. Internet calls will be disabled.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
            [alert show];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [SVProgressHUD dismiss];
    }];
}

//#pragma mark - Alert view delegate
//- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
//    if (alertView.tag == SHOW_LOGIN_ALERT) {
//        UITextField *usernameTextField = [alertView textFieldAtIndex:0];
//        UITextField *passwordTextField = [alertView textFieldAtIndex:1];
//        
//        self.user = usernameTextField.text;
//        
//        if (buttonIndex == 1) {
////            [self showForgotPassword];
//            return;
//        }
//        
//        self.loginAlertShown = YES;
//        
//        if (![usernameTextField.text length] || ![passwordTextField.text length]) {
////            [self showLogin];
//            return;
//        }
//        
//        [SVProgressHUD showWithStatus:NSLocalizedString(@"Logging in...", nil) maskType:SVProgressHUDMaskTypeGradient];
//        [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] loginWithUser:self.user password:passwordTextField.text success:^(AFHTTPRequestOperation *operation, id responseObject) {
//            [SVProgressHUD dismiss];
//            // Check if a SIP account 
//            if ([VoIPGRIDRequestOperationManager sharedRequestOperationManager].sipAccount) {
//                [[ConnectionHandler sharedConnectionHandler] sipConnect];
//            } else {
//                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry!", nil) message:NSLocalizedString(@"No active voice over internet account found. Internet calls will be disabled.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
//                [alert show];
//            }
//            [self dismissViewControllerAnimated:YES completion:nil];
//            [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {}];
//        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//            [SVProgressHUD dismiss];
//        }];
//    } else if (alertView.tag == PASSWORD_FORGOT_ALERT) {
//        self.loginAlertShown = NO;
//        
//        if (buttonIndex == 0) {
////            [self showLogin];
//        } else {
//            UITextField *emailTextField = [alertView textFieldAtIndex:0];
//            if ([emailTextField.text length]) {
//                self.user = emailTextField.text;
//                
//                [SVProgressHUD showWithStatus:NSLocalizedString(@"Sending email...", nil) maskType:SVProgressHUDMaskTypeGradient];
//                [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] passwordResetWithEmail:emailTextField.text success:^(AFHTTPRequestOperation *operation, id responseObject) {
//                    [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Email sent successfully.", nil)];
//                    [self performSelector:@selector(showLogin) withObject:nil afterDelay:3];
//                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//                    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Failed to send email.", nil)];
//                    [self performSelector:@selector(showLogin) withObject:nil afterDelay:3];
//                }];
//            } else {
////                [self showForgotPassword];
//            }
//        }
//    }
//}

@end
