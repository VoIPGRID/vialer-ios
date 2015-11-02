//
//  DialerViewController.m
//  Vialer
//
//  Created by Reinier Wieringa on 15/11/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "DialerViewController.h"

#import "AnimatedNumberPadViewController.h"
#import "AppDelegate.h"
#import "ConnectionHandler.h"
#import "GAITracker.h"
#import "SIPCallingViewController.h"
#import "SystemUser.h"

#import <AudioToolbox/AudioServices.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCall.h>

#import "AFNetworkReachabilityManager.h"
#import "UIViewController+MMDrawerController.h"
#import "Reachability.h"

static NSString * const kMenuImage = @"menu";

@interface DialerViewController ()
@property (nonatomic, strong) CTCallCenter *callCenter;
@property (nonatomic, strong) AnimatedNumberPadViewController *numberPadViewController;
@property (nonatomic, strong) Reachability *reachabilityManager;
@property (nonatomic, strong) UIBarButtonItem *leftDrawerButton;
@property (nonatomic, strong) SystemUser *currentUser;
@end

@implementation DialerViewController


# pragma mark - Setup View

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Keypad", nil);
        self.tabBarItem.image = [UIImage imageNamed:@"tab-keypad"];
        self.tabBarItem.selectedImage = [UIImage imageNamed:@"tab-keypad-active"];
        self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];
        self.navigationItem.leftBarButtonItem = self.leftDrawerButton;

        [self setupCellularCallEventsListener];
        [self.reachabilityManager startNotifier];
    }
    return self;
}

- (void)dealloc {
    [self.reachabilityManager stopNotifier];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupLayout];

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(backButtonLongPress:)];
    [self.backButton addGestureRecognizer:longPress];
}

- (void)setupLayout {
    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.width);

    [self.buttonsView addSubview:self.numberPadViewController.view];
    [self addChildViewController:self.numberPadViewController];
    self.backButton.hidden = YES;
    self.callButton.enabled = NO;

    // Color the warning
    self.statusView.backgroundColor = [Configuration tintColorForKey:kTintColorMessage];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomActiveNotification) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionStatusChangedNotification) name:ConnectionStatusChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sipCallStartedNotification) name:SIPCallStartedNotification object:nil];
    [self connectionStatusChangedNotification];
    [self setCallButtonState];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ConnectionStatusChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SIPCallStartedNotification object:nil];
}

#pragma mark - Lazy loading properties

- (CTCallCenter *)callCenter {
    if (!_callCenter) {
        self.callCenter = [[CTCallCenter alloc] init];
    }
    return _callCenter;
}

- (SystemUser *)currentUser {
    if (!_currentUser) {
        _currentUser = [SystemUser currentUser];
    }
    return _currentUser;
}

- (UIBarButtonItem *)leftDrawerButton {
    if (!_leftDrawerButton) {
        // Add hamburger menu on navigation bar
        _leftDrawerButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:kMenuImage] style:UIBarButtonItemStylePlain target:self action:@selector(leftDrawerButtonPress:)];
        _leftDrawerButton.tintColor = [Configuration tintColorForKey:kTintColorLeftDrawerButton];
    }
    return _leftDrawerButton;
}

- (Reachability *)reachabilityManager{
    if (!_reachabilityManager) {
        _reachabilityManager = [Reachability reachabilityForInternetConnection];
        // Set the blocks
        __weak typeof(self) weakSelf = self;
        _reachabilityManager.reachableBlock = ^(Reachability*reach) {
            // keep in mind this is called on a background thread
            // and if you are updating the UI it needs to happen
            // on the main thread, like this:
            dispatch_async(dispatch_get_main_queue(), ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"REACHABLE!");
                    [weakSelf connectionStatusChangedNotification];
                });
            });
        };

        _reachabilityManager.unreachableBlock = ^(Reachability*reach) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"UNREACHABLE!");
                [weakSelf connectionStatusChangedNotification];
            });
        };
    }
    return _reachabilityManager;
}

- (AnimatedNumberPadViewController *)numberPadViewController {
    if (!_numberPadViewController) {
        _numberPadViewController = [[AnimatedNumberPadViewController alloc] init];
        _numberPadViewController.view.frame = self.buttonsView.bounds;
        _numberPadViewController.delegate = self;
        _numberPadViewController.tonesEnabled = YES;
    }
    return _numberPadViewController;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [GAITracker trackScreenForControllerName:NSStringFromClass([self class])];
}

#pragma mark - Notification handling

- (void)applicationDidBecomActiveNotification {
    [self connectionStatusChangedNotification];
    [self setCallButtonState];
}

- (void)setCallButtonState {
    if (!self.numberTextView.text.length) {
        self.callButton.enabled = NO;
        self.backButton.hidden = YES;
    }
}

- (void)connectionStatusChangedNotification {
    // Function is called when internet connection is changed.
    if ([self.reachabilityManager isReachable]) {
        // internet
        self.buttonsView.userInteractionEnabled = self.backButton.userInteractionEnabled = self.numberTextView.userInteractionEnabled = YES;
        self.callButton.enabled = YES;

        // Check if the user has sip enabled.
        if (self.currentUser.isAllowedToSip) {
            // Internet, No SIP enabled/allowed.
            [self hideMessage];
        } else if (self.currentUser.sipAccount) {
            if ([ConnectionHandler sharedConnectionHandler].connectionStatus == ConnectionStatusHigh) {
                // Internet, SIP, good connection.
                [self hideMessage];
            } else {
                // internet, SIP, but poor connection
                [self showMessage:NSLocalizedString(@"Poor internet connection Connect A/B", nil) withInfo:NSLocalizedString(@"Poor internet Info", nil)];
            }
        } else {
            // Internet, no SIP account configured.
            [self showMessage:NSLocalizedString(@"Connect A/B calls only", nil) withInfo:NSLocalizedString(@"Connect A/B Info", nil)];
        }
    } else {
        // No internet.
        self.buttonsView.userInteractionEnabled = self.backButton.userInteractionEnabled = self.numberTextView.userInteractionEnabled = NO;
        self.callButton.enabled = NO;
        [self showMessage:NSLocalizedString(@"No Connection", nil) withInfo:NSLocalizedString(@"No Connection Info Text", nil)];
    }
}

- (void)sipCallStartedNotification {
    self.backButton.hidden = YES;
    self.callButton.enabled = NO;
    self.numberTextView.text = @"";
}

- (void)setupCellularCallEventsListener {
    __weak typeof(self) weakSelf = self;
    [self.callCenter setCallEventHandler:^(CTCall *call) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.backButton.hidden = YES;
            weakSelf.callButton.enabled = NO;
            weakSelf.numberTextView.text = @"";
        });
        NSLog(@"callEventHandler2: %@", call.callState);
    }];
}

#pragma mark - TextView delegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString *originalText = textView.text ? textView.text : @"";
    NSString *newString = [originalText stringByReplacingCharactersInRange:range withString:text];
    NSMutableCharacterSet *characterSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"0123456789+#*() "];
    if (newString.length != [[newString componentsSeparatedByCharactersInSet:[characterSet invertedSet]] componentsJoinedByString:@""].length) {
        return NO;
    }

    self.backButton.hidden = NO;
    self.callButton.enabled = YES;

    return YES;
}

#pragma mark - Actions

- (void)backButtonLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.numberTextView.text = @"";
        self.backButton.hidden = YES;
        self.callButton.enabled = NO;
    }
}

- (IBAction)dialerBackButtonPressed:(UIButton *)sender {
    self.numberTextView.text = [self.numberTextView.text substringToIndex:self.numberTextView.text.length - 1];
    self.backButton.hidden = (self.numberTextView.text.length == 0);
    self.callButton.enabled = (self.numberTextView.text.length > 0);
}

- (IBAction)callButtonPressed:(UIButton *)sender {
    NSString *phoneNumber = self.numberTextView.text;
    if (!phoneNumber.length) {
        return;
    }

    AppDelegate *appDelegate = ((AppDelegate *)[UIApplication sharedApplication].delegate);
    [appDelegate handlePhoneNumber:phoneNumber];
}

- (void)leftDrawerButtonPress:(id)sender{
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

#pragma mark - NumberPadViewController delegate

- (void)numberPadPressedWithCharacter:(NSString *)character {
    if (!self.numberTextView.text) {
        self.numberTextView.text = @"";
    }

    if ([character isEqualToString:@"+"] && self.numberTextView.text.length > 0) {
        self.numberTextView.text = [self.numberTextView.text substringToIndex:self.numberTextView.text.length - 1];
    }
    self.numberTextView.text = [self.numberTextView.text stringByAppendingString:character];

    self.backButton.hidden = NO;
    self.callButton.enabled = YES;
}

#pragma mark - Private status message handling

- (void)showMessage:(NSString *)message withInfo:(NSString *)info {
    self.infoMessage = info;
    self.statusLabel.text = message;
    self.statusView.hidden = NO;
    // Move the input a bit down
    [UIView animateWithDuration:0.1
                     animations:^{
                         self.numberTextView.frame = CGRectMake(self.numberTextView.frame.origin.x, 25.0,
                                                                self.numberTextView.frame.size.width, self.numberTextView.frame.size.height);
                         self.backButton.frame = CGRectMake(self.backButton.frame.origin.x, 25.0,
                                                            self.backButton.frame.size.width, self.backButton.frame.size.height);
                     }];
}

- (void)hideMessage {
    self.infoMessage = nil;
    // Hide the status label
    self.statusView.hidden = YES;
    // Position back the input fields
    [UIView animateWithDuration:0.1
                     animations:^{
                         self.numberTextView.frame = CGRectMake(self.numberTextView.frame.origin.x, 8.f,
                                                                self.numberTextView.frame.size.width, self.numberTextView.frame.size.height);
                         self.backButton.frame = CGRectMake(self.backButton.frame.origin.x, 8.f,
                                                            self.backButton.frame.size.width, self.backButton.frame.size.height);
                     }];

}

- (void)messageInfoPressed:(UIButton *)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.statusLabel.text
                                                    message:self.infoMessage
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
    [alert show];
}

@end
