//
//  LogInViewController.m
//  Vialer
//
//  Created by Reinier Wieringa on 06/11/13.
//  Copyright (c) 2013 Voys. All rights reserved.
//

#import "LogInViewController.h"
#import "VoysRequestOperationManager.h"

#import "SVProgressHUD.h"

#define SHOW_LOGIN_ALERT      100
#define PASSWORD_FORGOT_ALERT 101

@interface LogInViewController ()
@property (nonatomic, assign) BOOL loginAlertShown;
@property (nonatomic, strong) NSString *user;
@end

@implementation LogInViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginFailedNotification:) name:LOGIN_FAILED_NOTIFICATION object:nil];
    [self showLogin];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

- (void)showLogin {
    if (!self.loginAlertShown) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sign In", nil) message:NSLocalizedString(@"Enter your email and password.", nil) delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Ok", nil), NSLocalizedString(@"Forgot password?", nil), nil];
        [alert setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
        [alert textFieldAtIndex:0].text = self.user;
        alert.tag = SHOW_LOGIN_ALERT;
        [alert show];
        
        UITextField *usernameTextField = [alert textFieldAtIndex:0];
        usernameTextField.placeholder = NSLocalizedString(@"Email", nil);

        self.loginAlertShown = YES;
    }
}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == SHOW_LOGIN_ALERT) {
        UITextField *usernameTextField = [alertView textFieldAtIndex:0];
        UITextField *passwordTextField = [alertView textFieldAtIndex:1];

        self.user = usernameTextField.text;
        
        if (buttonIndex == 1) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Forgot Password", nil) message:NSLocalizedString(@"Forgotten your password?\nPlease enter your email address, and we will email you instructions for setting a new one.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
            [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
            [alert textFieldAtIndex:0].text = self.user;
            alert.tag = PASSWORD_FORGOT_ALERT;
            [alert show];
            
            return;
        }
        
        self.loginAlertShown = NO;
        
        if (![usernameTextField.text length] || ![passwordTextField.text length]) {
            [self showLogin];
            return;
        }
        
        [SVProgressHUD showWithStatus:NSLocalizedString(@"Logging in...", nil) maskType:SVProgressHUDMaskTypeGradient];
        [[VoysRequestOperationManager sharedRequestOperationManager] loginWithUser:self.user password:passwordTextField.text success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [SVProgressHUD dismiss];
            [self dismissViewControllerAnimated:YES completion:nil];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [SVProgressHUD dismiss];
        }];
    } else if (alertView.tag == PASSWORD_FORGOT_ALERT) {
        self.loginAlertShown = NO;
        
        if (buttonIndex == 0) {
            [self showLogin];
        } else {
            UITextField *emailTextField = [alertView textFieldAtIndex:0];
            if ([emailTextField.text length]) {
                self.user = emailTextField.text;
                
                [SVProgressHUD showWithStatus:NSLocalizedString(@"Sending email...", nil) maskType:SVProgressHUDMaskTypeGradient];
                [[VoysRequestOperationManager sharedRequestOperationManager] passwordResetWithEmail:emailTextField.text success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Email sent successfully.", nil)];
                    [self performSelector:@selector(showLogin) withObject:nil afterDelay:3];
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Failed to send email.", nil)];
                    [self performSelector:@selector(showLogin) withObject:nil afterDelay:3];
                }];
            }
        }
    }
}

#pragma mark - Notifications

- (void)loginFailedNotification:(NSNotification *)notification {
    [self showLogin];
}

@end
