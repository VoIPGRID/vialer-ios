//
//  UserProfileWebViewController.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "SVProgressHUD.h"
#import "SystemUser.h"
#import "UserProfileWebViewController.h"

static NSString * const UserProfileWebViewControllerUnwindToSettingsSegue = @"UnwindToSettingsSegue";

@implementation UserProfileWebViewController

#pragma mark - properties

- (void)cancelButtonPressed:(UIBarButtonItem *)sender {
    [SVProgressHUD dismiss];
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Checking VoIP account", nil) maskType:SVProgressHUDMaskTypeGradient];

    // Check if the user has set an SIP account.
    [self.currentUser getAndActivateSIPAccountWithCompletion:^(BOOL success, NSError *error) {
        [SVProgressHUD dismiss];

        // If account was set, lets unwind to the settings.
        if (success && self.currentUser.sipAccount) {
            [self performSegueWithIdentifier:UserProfileWebViewControllerUnwindToSettingsSegue sender:self];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
}

@end
