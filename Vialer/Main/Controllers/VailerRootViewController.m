//
//  VailerRootViewController.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "VailerRootViewController.h"
#import "Middleware.h"
#import "Notifications-Bridging-Header.h"
#import "SystemUser.h"
#import "UIAlertController+Vialer.h"
#import "VialerDrawerViewController.h"
#import "VoIPGRIDRequestOperationManager.h"
#import "Vialer-Swift.h"

static NSString * const VialerRootViewControllerShowVialerDrawerViewSegue = @"ShowVialerDrawerViewSegue";
static NSString * const VialerRootViewControllerShowSIPIncomingCallViewSegue = @"ShowSIPIncomingCallViewSegue";
static NSString * const VialerRootViewControllerShowSIPCallingViewSegue = @"ShowSIPCallingViewSegue";
static NSString * const VialerRootViewControllerShowTwoStepCallingViewSegue = @"ShowTwoStepCallingViewSegue";

@interface VailerRootViewController ()
@property (nonatomic) BOOL willPresentCallingViewController;
@property(weak, nonatomic) NSString *twoStepNumberToCall;
@property (weak, nonatomic) IBOutlet GradientView *backgroundGrandientView;
@property (weak, nonatomic) IBOutlet UIView *backgroundSolidColorView;

@end

@implementation VailerRootViewController

#pragma mark - view life cycle

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logoutNotification:) name:SystemUserLogoutNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(twoFactorRequiredNotification:) name:SystemUserTwoFactorAuthenticationTokenNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:SystemUserLogoutNotification];
    }@catch(NSException *exception) {
        VialerLogError(@"Error removing observer %@: %@", SystemUserLogoutNotification, exception);
    }

    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:SystemUserTwoFactorAuthenticationTokenNotification];
    } @catch (NSException *exception) {
        VialerLogError(@"Error removing observer %@: %@", SystemUserTwoFactorAuthenticationTokenNotification, exception);
    }
//
//    @try {
//        [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:CallKitProviderDelegateInboundCallAcceptedNotification];
//    } @catch (NSException *exception) {
//        VialerLogError(@"Error removing observer %@: %@", CallKitProviderDelegateOutboundCallStartedNotification, exception);
//    }
//
//    @try {
//        [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:CallKitProviderDelegateOutboundCallStartedNotification];
//    } @catch (NSException *exception) {
//        VialerLogError(@"Error removing observer %@: %@", CallKitProviderDelegateOutboundCallStartedNotification, exception);
//    }

    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:MiddlewareRegistrationOnOtherDeviceNotification];
    }
    @catch (NSException *exception) {
        VialerLogError(@"Error removing observer %@: %@", MiddlewareRegistrationOnOtherDeviceNotification, exception);
    }

    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:AppDelegateStartConnectABCallNotification];
    }
    @catch(NSException *exception){
        VialerLogError(@"Error removing observer %@: %@", AppDelegateStartConnectABCallNotification, exception);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.backgroundSolidColorView.backgroundColor = [[ColorsConfiguration shared] colorForKey:ColorsBackgroundGradientStart];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showSipCallingViewOrIncomingCallNotification:) name:CallKitProviderDelegateInboundCallAcceptedNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showSipCallingViewOrIncomingCallNotification:) name:CallKitProviderDelegateOutboundCallStartedNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(voipWasDisabled:) name:MiddlewareRegistrationOnOtherDeviceNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startConnectABCall:) name:AppDelegateStartConnectABCallNotification object:nil];

    // Customize NavigationBar
    [UINavigationBar appearance].tintColor = [[ColorsConfiguration shared] colorForKey:ColorsNavigationBarTint];
    [UINavigationBar appearance].barTintColor = [[ColorsConfiguration shared]  colorForKey:ColorsNavigationBarBarTint];
    [UINavigationBar appearance].translucent = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // Animate background from solid to gradient color
    [UIView animateWithDuration:1 animations:^{
        [self.backgroundGrandientView setAlpha:1];
     }
     completion:^(BOOL finished){
         // Prevent segue if we are in the process of showing an incoming view controller.
         if (!self.willPresentCallingViewController) {
             if ([self shouldPresentLoginViewController]) {
                 [self.loginViewController setModalPresentationStyle: UIModalPresentationFullScreen];
                 [self presentViewController:self.loginViewController animated:NO completion:nil];
             } else {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [self performSegueWithIdentifier:VialerRootViewControllerShowVialerDrawerViewSegue sender:self];
                 });
             }
         }
     }];
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
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
    } else if (![SystemUser currentUser].migrationCompleted || ![SystemUser currentUser].mobileNumber){
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
        [[self topViewController] presentViewController:alert animated:YES completion:nil];
    } else {
        [self showLoginScreen];
    }
}

- (void)twoFactorRequiredNotification:(NSNotification *)notification {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Two-factor authentication", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = NSLocalizedString(@"Token", nil);
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];

    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              UITextField *tokenField = alert.textFields[0];

                                                              SystemUser *user = [SystemUser currentUser];

                                                              [user loginToCheckTwoFactorWithUserName:user.username
                                                                                             password:user.password
                                                                                             andToken:tokenField.text
                                                                                           completion:^(BOOL loggedin, BOOL tokenRequired, NSError *error) {
                                                                                               if (error && error.code == SystemUserTwoFactorAuthenticationTokenInvalid) {
                                                                                                   [self twoFactorRequiredNotification:nil];
                                                                                               } 
                                                                                           }];
                                                          }];
    [alert addAction:defaultAction];

    [[self topViewController] presentViewController:alert animated:YES completion:nil];
}

- (void)showSipCallingViewOrIncomingCallNotification:(NSNotification *)notification {
//    if (![self.presentedViewController isKindOfClass:[SIPIncomingCallViewController class]]) {
//        if (![self.presentedViewController isKindOfClass:[SIPCallingViewController class]] &&
//            ![self.presentedViewController.presentedViewController isKindOfClass:[SIPCallingViewController class]]) {
//            self.willPresentCallingViewController = YES;
//            [self dismissViewControllerAnimated:NO completion:^{
//                self.activeCall = [[notification userInfo] objectForKey:VSLNotificationUserInfoCallKey];
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [self performSegueWithIdentifier:VialerRootViewControllerShowSIPCallingViewSegue sender:self];
//                });
//            }];
//        }
//    }
}

- (void)startConnectABCall:(NSNotification *)notification {
    if (![self.presentedViewController isKindOfClass:[TwoStepCallingViewController class]]) {
        self.willPresentCallingViewController = YES;
        [self dismissViewControllerAnimated:NO completion:^{
            self.twoStepNumberToCall = [[notification userInfo] objectForKey:AppDelegateStartConnectABCallUserInfoKey];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self performSegueWithIdentifier:VialerRootViewControllerShowTwoStepCallingViewSegue sender:self];
            });
        }];
    }
}

- (void)voipWasDisabled:(NSNotification *)notification {
    NSString *localizedErrorString = NSLocalizedString(@"Your VoIP account has been registered on another device. You can re-enable VoIP in Settings", nil);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"VoIP Disabled", nil)
                                                                   message:localizedErrorString
                                                      andDefaultButtonText:NSLocalizedString(@"Ok", nil)];
    [self presentViewController:alert animated:YES completion:nil];
}

- (UIViewController *)topViewController{
    return [self topViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    VialerLogInfo(@"preparing...");
    self.willPresentCallingViewController = NO;
//    if ([segue.destinationViewController isKindOfClass:[SIPIncomingCallViewController class]]) {
//        SIPIncomingCallViewController *sipIncomingViewController = (SIPIncomingCallViewController *)segue.destinationViewController;
//        sipIncomingViewController.call = self.activeCall;
//
//    } else if ([segue.destinationViewController isKindOfClass:[SIPCallingViewController class]]) {
//        SIPCallingViewController *sipCallingVC = (SIPCallingViewController *)segue.destinationViewController;
//        sipCallingVC.activeCall = self.activeCall;
//    } else if ([segue.destinationViewController isKindOfClass:[TwoStepCallingViewController class]]) {
//        TwoStepCallingViewController *tscvc = (TwoStepCallingViewController *)segue.destinationViewController;
//        [tscvc handlePhoneNumber:self.twoStepNumberToCall];
//    }
}

# pragma mark - Unwind segue

- (IBAction)unwindVialerRootViewController:(UIStoryboardSegue *)segue {
    [UIDevice currentDevice].proximityMonitoringEnabled = NO;
}

# pragma mark - ViewController stack navigation
// Credit goes to: https://gist.github.com/snikch/3661188
- (UIViewController *)topViewController:(UIViewController *)rootViewController {
    if (rootViewController.presentedViewController == nil) {
        return rootViewController;
    }

    if ([rootViewController.presentedViewController isMemberOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController.presentedViewController;
        UIViewController *lastViewController = [[navigationController viewControllers] lastObject];
        return [self topViewController:lastViewController];
    }

    UIViewController *presentedViewController = (UIViewController *)rootViewController.presentedViewController;
    return [self topViewController:presentedViewController];
}
@end
