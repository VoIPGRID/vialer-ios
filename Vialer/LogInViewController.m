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

#define SHOW_LOGIN_ALERT      100
#define PASSWORD_FORGOT_ALERT 101

@interface LogInViewController ()
@property (nonatomic, assign) BOOL loginAlertShown;
@property (nonatomic, strong) NSString *user;
@end

@implementation LogInViewController {
    BOOL UNLOCKED;
}

/** SLIDER: todo refactor to 'UnlockSlider' class */
- (IBAction)UnLockIt {
    if (!UNLOCKED) {
        if (slideToUnlock.value == slideToUnlock.maximumValue) {  // if user slide to the most right side, stop the operation
            // Put here what happens when it is unlocked
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self animateLogoToTop];            // 1) animate logo to top
    [self animateLoginViewToVisible];
    [self animateConfigureViewToVisible];
}

#pragma mark - Navigation animations
- (void)animateLogoToTop {
    [UIView animateWithDuration:4.0 animations:^{
        [self.logoView setCenter:CGPointMake(self.logoView.center.x, -CGRectGetHeight(self.logoView.frame))];
    }];
}

- (void)animateLoginViewToVisible {
    void(^animations)(void) = ^{
        [self.loginFormView setAlpha:1.f];
    };
    [UIView animateWithDuration:2.2f
                          delay:0.8f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:animations
                     completion:nil];
}

- (void)animateConfigureViewToVisible {
    void(^animations)(void) = ^{
        [self.loginFormView setAlpha:0.f];
        [self.configureFormView setAlpha:1.f];
    };
    [UIView animateWithDuration:2.2f
                          delay:0.8f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:animations
                     completion:nil];
}

#pragma mark -
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Alert view delegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == SHOW_LOGIN_ALERT) {
        UITextField *usernameTextField = [alertView textFieldAtIndex:0];
        UITextField *passwordTextField = [alertView textFieldAtIndex:1];
        
        self.user = usernameTextField.text;
        
        if (buttonIndex == 1) {
//            [self showForgotPassword];
            return;
        }
        
        self.loginAlertShown = YES;
        
        if (![usernameTextField.text length] || ![passwordTextField.text length]) {
//            [self showLogin];
            return;
        }
        
        [SVProgressHUD showWithStatus:NSLocalizedString(@"Logging in...", nil) maskType:SVProgressHUDMaskTypeGradient];
        [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] loginWithUser:self.user password:passwordTextField.text success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [SVProgressHUD dismiss];
            // Check if a SIP account 
            if ([VoIPGRIDRequestOperationManager sharedRequestOperationManager].sipAccount) {
                [[ConnectionHandler sharedConnectionHandler] sipConnect];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry!", nil) message:NSLocalizedString(@"No active voice over internet account found. Internet calls will be disabled.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
                [alert show];
            }
            [self dismissViewControllerAnimated:YES completion:nil];
            [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {}];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [SVProgressHUD dismiss];
        }];
    } else if (alertView.tag == PASSWORD_FORGOT_ALERT) {
        self.loginAlertShown = NO;
        
        if (buttonIndex == 0) {
//            [self showLogin];
        } else {
            UITextField *emailTextField = [alertView textFieldAtIndex:0];
            if ([emailTextField.text length]) {
                self.user = emailTextField.text;
                
                [SVProgressHUD showWithStatus:NSLocalizedString(@"Sending email...", nil) maskType:SVProgressHUDMaskTypeGradient];
                [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] passwordResetWithEmail:emailTextField.text success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Email sent successfully.", nil)];
                    [self performSelector:@selector(showLogin) withObject:nil afterDelay:3];
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Failed to send email.", nil)];
                    [self performSelector:@selector(showLogin) withObject:nil afterDelay:3];
                }];
            } else {
//                [self showForgotPassword];
            }
        }
    }
}

@end
