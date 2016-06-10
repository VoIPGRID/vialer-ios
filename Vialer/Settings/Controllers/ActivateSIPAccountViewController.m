//
//  ActivateSIPAccountViewController.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "ActivateSIPAccountViewController.h"
#import "Configuration.h"
#import "RoundedAndColoredUIButton.h"
#import "UserProfileWebViewController.h"
#import "Vialer-Swift.h"

static NSString *ActivateSIPAccountViewControllerUserProfileURL = @"/user/change/";
static NSString * ActivateSIPAccountViewControllerVialerRootViewControllerSegue = @"VialerRootViewControllerSegue";
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
    [VialerGAITracker trackScreenForControllerWithName:NSStringFromClass([self class])];
}

- (void)setupUserProfileButton {
    self.userProfileButton.borderWidth = 1;
    self.userProfileButton.cornerRadius = ActivateSIPAccountViewControllerButtonRadius;
    self.userProfileButton.borderColor = [self.configuration.colorConfiguration colorForKey:ConfigurationActivateSIPAccountViewControllerButtonBorderColor];
    self.userProfileButton.backgroundColorForPressedState = [self.configuration.colorConfiguration colorForKey:ConfigurationActivateSIPAccountViewControllerButtonBackgroundColorForPressedState];
}

#pragma mark - Properties

- (Configuration *)configuration {
    if (!_configuration) {
        _configuration = [Configuration defaultConfiguration];
    }
    return _configuration;
}

#pragma mark - actions

- (IBAction)backButtonPressed:(UIBarButtonItem *)sender {
    if (self.backButtonToRootViewController) {
        [self performSegueWithIdentifier:ActivateSIPAccountViewControllerVialerRootViewControllerSegue sender:self];
        self.backButtonToRootViewController = NO;
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[UserProfileWebViewController class]]) {
        [VialerGAITracker trackScreenForControllerWithName:@"UserProfileWebView"];
        UserProfileWebViewController *webVC = segue.destinationViewController;
        webVC.nextUrl = ActivateSIPAccountViewControllerUserProfileURL;
        webVC.backButtonToRootViewController = self.backButtonToRootViewController;
    }
}

@end
