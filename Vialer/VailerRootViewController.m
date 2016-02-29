//
//  VailerRootViewController.m
//  Vialer
//
//  Created by Bob Voorneveld on 18/11/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "VailerRootViewController.h"

#import "AppDelegate.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "SIPIncomingCallViewController.h"
#import "SIPCallingViewController.h"
#import "SystemUser.h"
#import "UIAlertController+Vialer.h"
#import "VialerDrawerViewController.h"
#import "VoIPGRIDRequestOperationManager.h"

static NSString * const VialerRootViewControllerShowVialerDrawerViewSegue = @"ShowVialerDrawerViewSegue";
static NSString * const VialerRootViewControllerShowSIPIncomingCallViewSegue = @"ShowSIPIncomingCallViewSegue";
static NSString * const VialerRootViewControllerShowSIPCallingViewSegue = @"ShowSIPCallingViewSegue";
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

@interface VailerRootViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *launchImage;
@property (nonatomic) BOOL presentSIPViewController;
@end

@implementation VailerRootViewController

#pragma mark - view life cycle

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logoutNotification:) name:SystemUserLogoutNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:SystemUserLogoutNotification];
    }@catch(id exception) {
        DDLogError(@"Error removing observer %@: %@", SystemUserLogoutNotification, exception);
    }

    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:AppDelegateIncomingCallNotification];
    }
    @catch (NSException *exception) {
        DDLogError(@"Error removing observer %@: %@", AppDelegateIncomingCallNotification, exception);
    }

    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:AppDelegateIncomingBackgroundCallNotification];
    }
    @catch (NSException *exception) {
        DDLogError(@"Error removing observer %@: %@", AppDelegateIncomingBackgroundCallNotification, exception);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupLayout];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(incomingCallNotification:) name:AppDelegateIncomingCallNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(incomingBackgroundCallNotification:) name:AppDelegateIncomingBackgroundCallNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // This is needed because when dismissing the view stack to display the sip incoming view controller calls
    // the viewdidappear function so it will try to differen segue when you want to present a sip view controller.
    if (!self.presentSIPViewController) {
        if ([self shouldPresentLoginViewController]) {
            [self presentViewController:self.loginViewController animated:NO completion:nil];
        } else {
            [self performSegueWithIdentifier:VialerRootViewControllerShowVialerDrawerViewSegue sender:nil];
        }
    } else {
        self.presentSIPViewController = NO;
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

- (BOOL)shouldPresentLoginViewController {
    // Everybody, upgraders and new users, will see the onboarding. If you were logged in at v1.x, you will be logged in on
    // v2.x and start onboarding at the "configure numbers view".

    if (![SystemUser currentUser].loggedIn) {
        // Not logged in, not v21.x, nor in v2.x
        self.loginViewController.screenToShow = OnboardingScreenLogin;
        return YES;
    } else if (![SystemUser currentUser].migrationCompleted){
        // Also show the Mobile number onboarding screen
        self.loginViewController.screenToShow = OnboardingScreenConfigure;
        return YES;
    }
    return NO;
}

#pragma mark - actions

- (void)showLoginScreen {
    self.loginViewController = nil;
    self.loginViewController.screenToShow = OnboardingScreenLogin;
    self.loginViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    if (![self.presentedViewController isEqual:self.loginViewController]) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

#pragma mark - Notifications

- (void)logoutNotification:(NSNotification *)notification {
    if (notification.userInfo) {
        [self dismissViewControllerAnimated:NO completion:nil];
        NSError *error = notification.userInfo[SystemUserLogoutNotificationErrorKey];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ is logged out.", nil), notification.userInfo[SystemUserLogoutNotificationDisplayNameKey]]
                                                                       message:error.localizedDescription
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", nil)
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * _Nonnull action) {
            [self showLoginScreen];
        }];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        [self showLoginScreen];
    }
}

- (void)incomingCallNotification:(NSNotification *)notification {
    self.presentSIPViewController = YES;
    [self dismissViewControllerAnimated:NO completion:^(void){
        [self performSegueWithIdentifier:VialerRootViewControllerShowSIPIncomingCallViewSegue sender:notification.object];
    }];
}

- (void)incomingBackgroundCallNotification:(NSNotification *)notification {
    self.presentSIPViewController = YES;
    [self dismissViewControllerAnimated:NO completion:^{
        [self performSegueWithIdentifier:VialerRootViewControllerShowSIPCallingViewSegue sender:notification.object];
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[SIPIncomingCallViewController class]]) {
        SIPIncomingCallViewController *sipIncomingViewController = (SIPIncomingCallViewController *)segue.destinationViewController;
        sipIncomingViewController.call = sender;
    } else if ([segue.destinationViewController isKindOfClass:[SIPCallingViewController class]]) {
        SIPCallingViewController *sipCallingViewController = (SIPCallingViewController *)segue.destinationViewController;
        [sipCallingViewController handleIncomingCallWithVSLCall:sender];
    }
}

# pragma mark - Unwind segue

- (IBAction)unwindVialerRootViewController:(UIStoryboardSegue *)segue { }

@end
