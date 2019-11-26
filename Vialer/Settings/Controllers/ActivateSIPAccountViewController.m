//
//  ActivateSIPAccountViewController.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "ActivateSIPAccountViewController.h"
#import "RoundedAndColoredUIButton.h"
#import "UserProfileWebViewController.h"
#import "Vialer-Swift.h"


static NSString *ActivateSIPAccountViewControllerUserProfileURL = @"/user/change/";
static NSString *ActivateSIPAccountViewControllerVialerRootViewControllerSegue = @"VialerRootViewControllerSegue";
static CGFloat const ActivateSIPAccountViewControllerButtonRadius = 5.0;

@interface ActivateSIPAccountViewController()
@property (weak, nonatomic) IBOutlet RoundedAndColoredUIButton *userProfileButton;
@property (strong, nonatomic) SystemUser *user;
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
    ColorsConfiguration *colorsConfiguration = [ColorsConfiguration shared];
    self.userProfileButton.borderWidth = 1;
    self.userProfileButton.cornerRadius = ActivateSIPAccountViewControllerButtonRadius;
    self.userProfileButton.borderColor = [colorsConfiguration colorForKey:ColorsActivateSIPAccountViewControllerButtonBorder];
    self.userProfileButton.backgroundColorForPressedState = [colorsConfiguration colorForKey:ColorsActivateSIPAccountViewControllerButtonBackgroundPressedState];
}

#pragma mark - Properties

- (SystemUser *)user {
    if (!_user) {
        _user = [SystemUser currentUser];
    }
    return _user;
}

#pragma mark - actions

- (IBAction)backButtonPressed:(UIBarButtonItem *)sender {
    [self.user updateSystemUserFromVGWithCompletion:nil];

    if (self.backButtonToRootViewController) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:ActivateSIPAccountViewControllerVialerRootViewControllerSegue sender:self];
            self.backButtonToRootViewController = NO;
        });
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[UserProfileWebViewController class]]) {
        [VialerGAITracker trackScreenForControllerWithName:[VialerGAITracker GAUserProfileWebViewTrackingName]];
        UserProfileWebViewController *webVC = segue.destinationViewController;
        [webVC nextUrl:ActivateSIPAccountViewControllerUserProfileURL];
        webVC.backButtonToRootViewController = self.backButtonToRootViewController;
    }
}

@end
