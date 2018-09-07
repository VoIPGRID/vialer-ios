//
//  VailerRootViewController.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "VailerRootViewController.h"

#import "Middleware.h"
#import "Notifications-Bridging-Header.h"
#import "SIPIncomingCallViewController.h"
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
@property (weak, nonatomic) IBOutlet UIImageView *launchImage;
@property (nonatomic) BOOL willPresentCallingViewController;
@property (weak, nonatomic) VSLCall *activeCall;
@property(weak, nonatomic) NSString *twoStepNumberToCall;
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

    if ([VialerSIPLib callKitAvailable]) {
        @try {
            [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:CallKitProviderDelegateInboundCallAcceptedNotification];
        } @catch (NSException *exception) {
            VialerLogError(@"Error removing observer %@: %@", CallKitProviderDelegateOutboundCallStartedNotification, exception);
        }

        @try {
            [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:CallKitProviderDelegateOutboundCallStartedNotification];
        } @catch (NSException *exception) {
            VialerLogError(@"Error removing observer %@: %@", CallKitProviderDelegateOutboundCallStartedNotification, exception);
        }

    } else {
        @try {
            [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:AppDelegateIncomingCallNotification];
        }
        @catch (NSException *exception) {
            VialerLogError(@"Error removing observer %@: %@", AppDelegateIncomingCallNotification, exception);
        }

        @try {
            [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:AppDelegateIncomingBackgroundCallAcceptedNotification];
        }
        @catch (NSException *exception) {
            VialerLogError(@"Error removing observer %@: %@", AppDelegateIncomingBackgroundCallAcceptedNotification, exception);
        }
    }

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
    [self setupLayout];
    if ([VialerSIPLib callKitAvailable]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showSipCallingView:) name:CallKitProviderDelegateInboundCallAcceptedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showSipCallingView:) name:CallKitProviderDelegateOutboundCallStartedNotification object:nil];

    } else {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(incomingCallNotification:) name:AppDelegateIncomingCallNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(incomingBackgroundCallAcceptedNotification:) name:AppDelegateIncomingBackgroundCallAcceptedNotification object:nil];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(voipWasDisabled:) name:MiddlewareRegistrationOnOtherDeviceNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startConnectABCall:) name:AppDelegateStartConnectABCallNotification object:nil];

    // Customize NavigationBar
    [UINavigationBar appearance].tintColor = [[ColorsConfiguration shared] colorForKey:ColorsNavigationBarTint];
    [UINavigationBar appearance].barTintColor = [[ColorsConfiguration shared]  colorForKey:ColorsNavigationBarBarTint];
    [UINavigationBar appearance].translucent = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // Prevent segue if we are in the process of showing an incoming view controller.
    if (!self.willPresentCallingViewController) {
        if ([self shouldPresentLoginViewController]) {
            [self presentViewController:self.loginViewController animated:NO completion:nil];
        } else {
            [self performSegueWithIdentifier:VialerRootViewControllerShowVialerDrawerViewSegue sender:self];
        }
    }
}

- (void)setupLayout {
    NSString *launchImage;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    if(screenHeight > 736.0f) {
        launchImage = @"LaunchImage-1100-Portrait-2436h"; // iphone-x
    }
    else if(screenHeight > 667.0f) {
        launchImage = @"LaunchImage-800-Portrait-736h"; // iphone6 plus
    }
    else if(screenHeight > 568.0f) {
        launchImage = @"LaunchImage-800-667h"; // iphone6
    }
    else if(screenHeight > 480.0f){
        launchImage = @"LaunchImage-700-568h";// iphone5/5plus
    } else {
        launchImage = @"LaunchImage-700"; // iphone4 or below
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

- (void)incomingCallNotification:(NSNotification *)notification {
    if (![self.presentedViewController isKindOfClass:[SIPIncomingCallViewController class]]) {
        self.willPresentCallingViewController = YES;
        [self dismissViewControllerAnimated:NO completion:^(void){
            self.activeCall = [[notification userInfo] objectForKey:VSLNotificationUserInfoCallKey];
            [self performSegueWithIdentifier:VialerRootViewControllerShowSIPIncomingCallViewSegue sender:self];
        }];
    }
}

- (void)showSipCallingView:(NSNotification *)notification {
    if (![self.presentedViewController isKindOfClass:[SIPIncomingCallViewController class]] &&
        ![self.presentedViewController isKindOfClass:[SIPCallingViewController class]] &&
        ![self.presentedViewController.presentedViewController isKindOfClass:[SIPCallingViewController class]]) {
        self.willPresentCallingViewController = YES;
        [self dismissViewControllerAnimated:NO completion:^{
            self.activeCall = [[notification userInfo] objectForKey:VSLNotificationUserInfoCallKey];
            [self performSegueWithIdentifier:VialerRootViewControllerShowSIPCallingViewSegue sender:self];
        }];
    }
}

- (void)incomingBackgroundCallAcceptedNotification:(NSNotification *)notification {
    if (![self.presentedViewController isKindOfClass:[SIPIncomingCallViewController class]]) {
        self.willPresentCallingViewController = YES;
        [self dismissViewControllerAnimated:NO completion:^{
            self.activeCall = [[notification userInfo] objectForKey:VSLNotificationUserInfoCallKey];
            [self performSegueWithIdentifier:VialerRootViewControllerShowSIPCallingViewSegue sender:self];
        }];
    }
}

- (void)startConnectABCall:(NSNotification *)notification {
    if (![self.presentedViewController isKindOfClass:[TwoStepCallingViewController class]]) {
        self.willPresentCallingViewController = YES;
        [self dismissViewControllerAnimated:NO completion:^{
            self.twoStepNumberToCall = [[notification userInfo] objectForKey:AppDelegateStartConnectABCallUserInfoKey];
            
            [self performSegueWithIdentifier:VialerRootViewControllerShowTwoStepCallingViewSegue sender:self];
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
    self.willPresentCallingViewController = NO;
    if ([segue.destinationViewController isKindOfClass:[SIPIncomingCallViewController class]]) {
        SIPIncomingCallViewController *sipIncomingViewController = (SIPIncomingCallViewController *)segue.destinationViewController;
        sipIncomingViewController.call = self.activeCall;

    } else if ([segue.destinationViewController isKindOfClass:[SIPCallingViewController class]]) {
        SIPCallingViewController *sipCallingVC = (SIPCallingViewController *)segue.destinationViewController;
        sipCallingVC.activeCall = self.activeCall;
    } else if ([segue.destinationViewController isKindOfClass:[TwoStepCallingViewController class]]) {
        TwoStepCallingViewController *tscvc = (TwoStepCallingViewController *)segue.destinationViewController;
        [tscvc handlePhoneNumber:self.twoStepNumberToCall];
    }
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
