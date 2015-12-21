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
    [super viewDidLoad];
    self.hidesBottomBarWhenPushed = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [SVProgressHUD showWithStatus:[NSString stringWithFormat:NSLocalizedString(@"Loading %@...", nil), self.title]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [SVProgressHUD dismiss];
    [super viewWillDisappear:animated];
}

#pragma mark - properties

- (void)setURL:(NSURL *)URL {
    [super setURL:URL];
}

-(void)setNextUrl:(NSString *)nextUrl {
    NSString *partnerBaseUrl = [Configuration UrlForKey:@"Partner"];

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
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error %@", [error localizedDescription]);
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:NSLocalizedString(@"Failed to load %@", @"failed to load webpage with title"), self.title]];
    }];
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [super webViewDidStartLoad:webView];
    [SVProgressHUD showWithStatus:[NSString stringWithFormat:NSLocalizedString(@"Loading %@...", nil), self.title]];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [super webViewDidFinishLoad:webView];
    [SVProgressHUD dismiss];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [super webView:webView didFailLoadWithError:error];
    [SVProgressHUD dismiss];
}

#pragma mark - actions

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender {
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
    [SVProgressHUD dismiss];
}

#pragma mark - utils
- (NSString *)urlEncodedString:(NSString *)toEncode {
    NSMutableCharacterSet *URLQueryAllowedSetWithoutPlus = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [URLQueryAllowedSetWithoutPlus removeCharactersInString:@"+"];
    return [toEncode stringByAddingPercentEncodingWithAllowedCharacters:URLQueryAllowedSetWithoutPlus];
}

@end
