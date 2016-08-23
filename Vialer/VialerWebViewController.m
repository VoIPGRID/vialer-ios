//
//  VialerWebViewController.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "VialerWebViewController.h"

#import "Vialer-Swift.h"
#import "VoIPGRIDRequestOperationManager.h"
#import "SVProgressHUD.h"

static NSString * const VialerWebViewControllerApiKeyToken = @"token";

@interface VialerWebViewController()
@property (strong, nonatomic) VoIPGRIDRequestOperationManager *operationManager;
@end

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

- (Configuration *)configuration {
    if (!_configuration) {
        _configuration = [Configuration defaultConfiguration];
    }
    return _configuration;
}

- (void)nextUrl:(NSString *)nextUrl {
    [self.operationManager autoLoginTokenWithCompletion:^(AFHTTPRequestOperation *operation, NSDictionary *responseData, NSError *error) {
        if (error) {
            DDLogError(@"Error %@", [error localizedDescription]);
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:NSLocalizedString(@"Failed to load %@", @"failed to load webpage with title"), self.title]];
            return;
        }
        NSString *partnerBaseUrl = [self.configuration UrlForKey:ConfigurationPartnerURLKey];
        NSString *user = [self urlEncodedString:self.currentUser.username];
        NSString *token = responseData[VialerWebViewControllerApiKeyToken];
        NSString *encodedNextUrl = [self urlEncodedString:nextUrl];

        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/user/autologin/?username=%@&token=%@&next=%@", partnerBaseUrl, user, token, encodedNextUrl]];
        DDLogDebug(@"Go to url: %@", url);
        self.URL = url;
        [self load];
    }];
}

- (VoIPGRIDRequestOperationManager *)operationManager {
    if (!_operationManager) {
        _operationManager = [[VoIPGRIDRequestOperationManager alloc] initWithDefaultBaseURL];
    }
    return _operationManager;
}

- (SystemUser *)currentUser {
    if (!_currentUser) {
        _currentUser = [SystemUser currentUser];
    }
    return _currentUser;
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
    [SVProgressHUD dismiss];
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - utils
- (NSString *)urlEncodedString:(NSString *)toEncode {
    NSMutableCharacterSet *URLQueryAllowedSetWithoutPlus = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [URLQueryAllowedSetWithoutPlus removeCharactersInString:@"+"];
    return [toEncode stringByAddingPercentEncodingWithAllowedCharacters:URLQueryAllowedSetWithoutPlus];
}

@end
