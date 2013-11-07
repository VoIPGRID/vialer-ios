//
//  LogInViewController.m
//  Appic
//
//  Created by Reinier Wieringa on 06/11/13.
//  Copyright (c) 2013 Voys. All rights reserved.
//

#import "LogInViewController.h"
#import "VoysRequestOperationManager.h"

#import "SVProgressHUD.h"

@interface LogInViewController ()

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
    return UIStatusBarStyleLightContent;
}

- (void)showLogin {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sign In to Voys Telecom", nil) message:NSLocalizedString(@"Enter your username and password.", nil) delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
    [alert setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
    [alert show];
}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    UITextField *usernameTextField = [alertView textFieldAtIndex:0];
    UITextField *passwordTextField = [alertView textFieldAtIndex:1];

    [SVProgressHUD showWithStatus:NSLocalizedString(@"Logging in...", nil)];
    [[VoysRequestOperationManager sharedRequestOperationManager] loginWithUser:usernameTextField.text password:passwordTextField.text success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
