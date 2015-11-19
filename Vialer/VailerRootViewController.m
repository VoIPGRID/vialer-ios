//
//  VailerRootViewController.m
//  Vialer
//
//  Created by Bob Voorneveld on 18/11/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "VailerRootViewController.h"

#import "LogInViewController.h"
#import "SystemUser.h"
#import "VialerDrawerViewController.h"
#import "VoIPGRIDRequestOperationManager.h"

static NSString * const VailerRootViewControllerShowVialerDrawerViewSegue = @"ShowVialerDrawerViewSegue";

@interface VailerRootViewController ()
@property (strong, nonatomic) LogInViewController *loginViewController;
@property (weak, nonatomic) IBOutlet UIImageView *launchImage;
@end

@implementation VailerRootViewController

#pragma mark - view life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupLayout];
    [self setupLogin];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([SystemUser currentUser].isLoggedIn && !self.loginViewController.presentingViewController) {
        [self performSegueWithIdentifier:VailerRootViewControllerShowVialerDrawerViewSegue sender:nil];
    } else {
        [self presentViewController:self.loginViewController animated:NO completion:nil];
    }
}

- (void)setupLayout {
    NSString *launchImage;
    if  ([UIScreen mainScreen].bounds.size.height > 480.0f) {
        launchImage = @"LaunchImage-700-568h";
    } else {
        launchImage = @"LaunchImage-700";
    }
    self.launchImage.image = [UIImage imageNamed:launchImage];
}

#pragma mark - properties

- (LogInViewController *)loginViewController {
    if (!_loginViewController) {
        _loginViewController = [[LogInViewController alloc] initWithNibName:@"LogInViewController" bundle:[NSBundle mainBundle]];
    }
    return _loginViewController;
}

- (void)setupLogin {
    // Handler for failed authentications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginFailedNotification:) name:LOGIN_FAILED_NOTIFICATION object:nil];

    //Everybody, upgraders and new users, will see the onboarding. If you were logged in at v1.x, you will be logged in on
    //v2.x and start onboarding at the "configure numbers view".

    //TODO: Why not login again. What if the user was deactivated on the platform?
    if (![SystemUser currentUser].isLoggedIn) {
        //Not logged in, not v21.x, nor in v2.x
        [self showOnboarding:OnboardingScreenLogin];
    } else if (![[NSUserDefaults standardUserDefaults] boolForKey:@"v2.0_MigrationComplete"]){
        //Also show the Mobile number onboarding screen
        [self showOnboarding:OnboardingScreenConfigure];
// TODO: fix SIP
//    } else {
//        [[SystemUser currentUser] checkSipStatus];
    }
}

#pragma mark - Notification actions
- (void)showOnboarding:(OnboardingScreens)screenToShow {
    if (!self.loginViewController.presentingViewController) {
        self.loginViewController.screenToShow = screenToShow;
        self.loginViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

        [self dismissViewControllerAnimated:NO completion:nil];
        [self presentViewController:self.loginViewController animated:YES completion:nil];
    }
}

- (void)loginFailedNotification:(NSNotification *)notification {
    [self showOnboarding:OnboardingScreenLogin];
}
@end
