//
//  ActivateSIPAccountViewController.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "ActivateSIPAccountViewController.h"
#import "Configuration.h"
#import "GAITracker.h"
#import "RoundedAndColoredUIButton.h"
#import "UserProfileWebViewController.h"

static NSString *ActivateSIPAccountViewControllerUserProfileURL = @"/user/change/";
static CGFloat const ActivateSIPAccountViewControllerButtonRadius = 5.0;

@interface ActivateSIPAccountViewController()
@property (weak, nonatomic) IBOutlet RoundedAndColoredUIButton *userProfileButton;
@property (strong, nonatomic) Configuration *configuration;
@end

@implementation ActivateSIPAccountViewController

#pragma mark - View life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUserProfileButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [GAITracker trackScreenForControllerName:NSStringFromClass([self class])];
}

- (void)setupUserProfileButton {
    self.userProfileButton.borderWidth = 1;
    self.userProfileButton.cornerRadius = ActivateSIPAccountViewControllerButtonRadius;
    self.userProfileButton.borderColor = [self.configuration tintColorForKey:ConfigurationActivateSIPAccountViewControllerButtonBorderColor];
    self.userProfileButton.backgroundColorForPressedState = [self.configuration tintColorForKey:ConfigurationActivateSIPAccountViewControllerButtonBackgroundColorForPressedState];
}

#pragma mark - Properties

- (Configuration *)configuration {
    if (!_configuration) {
        _configuration = [Configuration defaultConfiguration];
    }
    return _configuration;
}

#pragma mark - actions

- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[UserProfileWebViewController class]]) {
        [GAITracker trackScreenForControllerName:@"UserProfileWebView"];
        UserProfileWebViewController *webVC = segue.destinationViewController;
        webVC.nextUrl = ActivateSIPAccountViewControllerUserProfileURL;
    }
}

@end
