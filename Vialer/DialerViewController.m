//
//  DialerViewController.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "DialerViewController.h"

#import "AppDelegate.h"
#import "Configuration.h"
#import "GAITracker.h"
#import "NumberPadViewController.h"
#import "PasteableUILabel.h"
#import "ReachabilityManager.h"
#import "ReachabilityBarViewController.h"
#import "TwoStepCallingViewController.h"
#import "SIPCallingViewController.h"
#import "SystemUser.h"

#import "UIViewController+MMDrawerController.h"

#import <AVFoundation/AVAudioSession.h>

static NSString * const DialerViewControllerTabBarItemImage = @"tab-keypad";
static NSString * const DialerViewControllerTabBarItemActiveImage = @"tab-keypad-active";
static NSString * const DialerViewControllerLogoImage = @"logo";
static NSString * const DialerViewControllerLeftDrawerButtonImage = @"menu";
static NSString * const DialerViewControllerTwoStepCallingSegue = @"TwoStepCallingSegue";
static NSString * const DialerViewControllerSIPCallingSegue = @"SIPCallingSegue";

@interface DialerViewController () <PasteableUILabelDelegate, NumberPadViewControllerDelegate>

@property (strong, nonatomic) UIBarButtonItem *leftDrawerButton;
@property (weak, nonatomic) IBOutlet PasteableUILabel *numberLabel;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton *callButton;
@property (weak, nonatomic) ReachabilityBarViewController *reachabilityBarViewController;

@property (strong, nonatomic) NSString *numberText;
@property (strong, nonatomic) ReachabilityManager *reachabilityManager;
@property (strong, nonatomic) NSString *lastCalledNumber;

@end

@implementation DialerViewController

#pragma mark - view lifecycle

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.title = NSLocalizedString(@"Keypad", nil);
        self.tabBarItem.image = [UIImage imageNamed:DialerViewControllerTabBarItemImage];
        self.tabBarItem.selectedImage = [UIImage imageNamed:DialerViewControllerTabBarItemActiveImage];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupLayout];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [GAITracker trackScreenForControllerName:NSStringFromClass([self class])];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupReachability) name:UIApplicationDidBecomeActiveNotification object:nil];
    [self setupReachability];
    [self setupCallButton];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self teardownReachability];
    @try{
        [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:UIApplicationDidBecomeActiveNotification];
    }@catch(id anException){
        //do nothing, obviously it wasn't attached because an exception was thrown
    }
}

#pragma mark - setup
    
- (void)setupLayout {
    self.numberText = @"";
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:DialerViewControllerLogoImage]];
}

- (void)setupReachability {
    [self.reachabilityManager addObserver:self forKeyPath:NSStringFromSelector(@selector(reachabilityStatus)) options:0 context:NULL];
    [self.reachabilityManager startMonitoring];
    self.reachabilityBarViewController.status = [self.reachabilityManager currentReachabilityStatus];
}

- (void)teardownReachability {
    [self.reachabilityManager removeObserver:self forKeyPath:NSStringFromSelector(@selector(reachabilityStatus))];
    self.reachabilityManager = nil;
}

- (void)setupCallButton {
    if ([self.reachabilityManager currentReachabilityStatus] == ReachabilityManagerStatusOffline ||
        (!self.lastCalledNumber.length && !self.numberText.length)) {

        self.callButton.enabled = NO;
    } else {
        self.callButton.enabled = YES;
    }
}

#pragma mark - properties

- (void)setNumberLabel:(PasteableUILabel *)numberLabel {
    _numberLabel = numberLabel;
    _numberLabel.delegate = self;
}

- (void)setNumberText:(NSString *)numberText {
    self.numberLabel.text = [self cleanPhonenumber:numberText];
    self.deleteButton.hidden = self.numberText.length == 0;
    [self setupCallButton];
}

- (NSString *)cleanPhonenumber:(NSString *)phonenumber {
    phonenumber = [[phonenumber componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString:@""];
    return [[phonenumber componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"+0123456789*#"] invertedSet]] componentsJoinedByString:@""];
}

- (NSString *)numberText {
    return self.numberLabel.text;
}

- (ReachabilityManager *)reachabilityManager {
    if (!_reachabilityManager) {
        _reachabilityManager = [[ReachabilityManager alloc] init];
    }
    return _reachabilityManager;
}

- (void)setLastCalledNumber:(NSString *)lastCalledNumber {
    _lastCalledNumber = lastCalledNumber;
    [self setupCallButton];
}

# pragma mark - actions

- (IBAction)leftDrawerButtonPress:(UIBarButtonItem *)sender{
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (IBAction)backButtonPressed:(UIButton *)sender {
    self.numberText = [self.numberText substringToIndex:self.numberText.length - 1];
}


- (IBAction)backButtonLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        self.numberText = @"";
    }
}

- (IBAction)callButtonPressed:(UIButton *)sender {
    // No number filled in yet, use old number (if stored)
    if (![self.numberText length]) {
        self.numberText = self.lastCalledNumber;

        // There is a number, let's call
    } else {
        self.lastCalledNumber = self.numberText;

        if ([self.reachabilityManager currentReachabilityStatus] == ReachabilityManagerStatusHighSpeed && [SystemUser currentUser].sipEnabled) {
            [GAITracker setupOutgoingSIPCallEvent];
            [self performSegueWithIdentifier:DialerViewControllerSIPCallingSegue sender:self];
        } else {
            [GAITracker setupOutgoingConnectABCallEvent];
            [self performSegueWithIdentifier:DialerViewControllerTwoStepCallingSegue sender:self];
        }
    }
}

#pragma mark - seques

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[NumberPadViewController class]]) {
        NumberPadViewController *npvc = (NumberPadViewController *)segue.destinationViewController;
        npvc.delegate = self;
    } else if ([segue.destinationViewController isKindOfClass:[ReachabilityBarViewController class]]) {
        self.reachabilityBarViewController = (ReachabilityBarViewController *)segue.destinationViewController;
    } else if ([segue.destinationViewController isKindOfClass:[TwoStepCallingViewController class]]) {
        TwoStepCallingViewController *tscvc = (TwoStepCallingViewController *)segue.destinationViewController;
        [tscvc handlePhoneNumber:self.numberText];
    } else if ([segue.destinationViewController isKindOfClass:[SIPCallingViewController class]]) {
        SIPCallingViewController *sipCallingViewController = (SIPCallingViewController *)segue.destinationViewController;
        [sipCallingViewController handleOutgoingCallWithPhoneNumber:self.numberText];
    }
}

#pragma mark - NumberPadViewControllerDelegate

- (void)numberPadPressedWithCharacter:(NSString *)character {
    if ([character isEqualToString:@"+"]) {
        if ([self.numberText isEqualToString:@"0"] || !self.numberText.length) {
            self.numberText = @"+";
        }
    } else {
        self.numberText = [self.numberText stringByAppendingString:character];
    }
}

#pragma mark - PasteableUILabelDelegate

- (void) pasteableUILabel:(UILabel *)label didReceivePastedText:(NSString *)text {
    self.numberText = text;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    // Keep track of connection status from reachabilityManager
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(reachabilityStatus))]) {
        self.reachabilityBarViewController.status = self.reachabilityManager.reachabilityStatus;
        [self setupCallButton];
    }
}

@end
