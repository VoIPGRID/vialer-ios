//
//  VialerWebViewController.m
//  Vialer
//
//  Created by Bob Voorneveld on 17/11/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "VialerWebViewController.h"

#import "VoIPGRIDRequestOperationManager.h"
#import "SystemUser.h"

#import "SVProgressHUD.h"

@implementation VialerWebViewController

#pragma mark - view life cycle

- (void)viewDidLoad {
    self.hidesBottomBarWhenPushed = YES;
}

#pragma mark - properties

-(void)setNextUrl:(NSString *)nextUrl {
    NSString *partnerBaseUrl = [Configuration UrlForKey:@"Partner"];

    [SVProgressHUD showWithStatus:[NSString stringWithFormat:NSLocalizedString(@"Loading %@...", nil), self.title]];

    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] autoLoginTokenWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSString *token = [responseObject objectForKey:@"token"];
            if ([token isKindOfClass:[NSString class]]) {
                // Encode the token and nextUrl, and also the user after retrieving it.
                token = [self urlEncodedString:token];
                _nextUrl = [self urlEncodedString:nextUrl];
                NSString *user = [self urlEncodedString:[SystemUser currentUser].user];
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/user/autologin/?username=%@&token=%@&next=%@", partnerBaseUrl, user, token, nextUrl]];
                NSLog(@"Go to url: %@", url);
                self.URL = url;
                [self load];
            }
            [SVProgressHUD dismiss];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error %@", [error localizedDescription]);
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:NSLocalizedString(@"Failed to load %@", @"failed to load webpage with title"), self.title]];
    }];
}

#pragma mark - actions

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender {
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - utils

// Correctly encode according to RFC 3986
- (NSString *)urlEncodedString:(NSString *)toEncode {
    if (!toEncode) {
        return @"";
    }
    return [toEncode stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

@end
