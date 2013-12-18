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
    [self showLogin];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginFailedNotification:) name:LOGIN_FAILED_NOTIFICATION object:nil];
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
        [alert show];
        
        UITextField *usernameTextField = [alert textFieldAtIndex:0];
        usernameTextField.placeholder = NSLocalizedString(@"Email", nil);

        self.loginAlertShown = YES;
    }
}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    self.loginAlertShown = NO;

    UITextField *usernameTextField = [alertView textFieldAtIndex:0];
    UITextField *passwordTextField = [alertView textFieldAtIndex:1];
    
    self.user = usernameTextField.text;
    
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
}

#pragma mark - Notifications

- (void)loginFailedNotification:(NSNotification *)notification {
    [self showLogin];
}

@end
