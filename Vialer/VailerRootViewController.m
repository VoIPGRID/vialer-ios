//
//  VailerRootViewController.m
//  Vialer
//
//  Created by Bob Voorneveld on 18/11/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "VailerRootViewController.h"

#import "SystemUser.h"
#import "VialerDrawerViewController.h"
#import "VoIPGRIDRequestOperationManager.h"

static NSString * const VailerRootViewControllerShowVialerDrawerViewSegue = @"ShowVialerDrawerViewSegue";

@interface VailerRootViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *launchImage;
@end

@implementation VailerRootViewController

#pragma mark - view life cycle

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginFailedNotification:) name:LOGIN_FAILED_NOTIFICATION object:nil];
    }
    return self;
}

- (void)dealloc {
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:LOGIN_FAILED_NOTIFICATION];
    }@catch(id exception) {}
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupLayout];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([self shouldPresentLoginViewController]) {
        [self presentViewController:self.loginViewController animated:NO completion:nil];
    } else {
        [self performSegueWithIdentifier:VailerRootViewControllerShowVialerDrawerViewSegue sender:nil];
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
    //Everybody, upgraders and new users, will see the onboarding. If you were logged in at v1.x, you will be logged in on
    //v2.x and start onboarding at the "configure numbers view".

    if (![SystemUser currentUser].isLoggedIn) {
        //Not logged in, not v21.x, nor in v2.x
        self.loginViewController.screenToShow = OnboardingScreenLogin;
        return YES;
    } else if (![[NSUserDefaults standardUserDefaults] boolForKey:LoginViewControllerMigrationCompleted]){
        //Also show the Mobile number onboarding screen
        self.loginViewController.screenToShow = OnboardingScreenConfigure;
        return YES;
    }
    return NO;
}

#pragma mark - Notification actions
- (void)loginFailedNotification:(NSNotification *)notification {
    self.loginViewController.screenToShow = OnboardingScreenLogin;
    self.loginViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    if (![self.presentedViewController isEqual:self.loginViewController]) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

@end
