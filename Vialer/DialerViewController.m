//
//  DialerViewController.m
//  Vialer
//
//  Created by Bob Voorneveld on 03/11/15.
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
#import "SIPCallingViewController.h"
#import "TwoStepCallingViewController.h"

#import "UIViewController+MMDrawerController.h"

#import <AVFoundation/AVAudioSession.h>

static NSString * const DialerViewControllerTabBarItemImage = @"tab-keypad";
static NSString * const DialerViewControllerTabBarItemActiveImage = @"tab-keypad-active";
static NSString * const DialerViewControllerLogoImage = @"logo";
static NSString * const DialerViewControllerLeftDrawerButtonImage = @"menu";

static NSString * const DialerViewControllerReachabilityStatusKey = @"status";

@interface DialerViewController () <PasteableUILabelDelegate, NumberPadViewControllerDelegate>

@property (nonatomic, strong) UIBarButtonItem *leftDrawerButton;
@property (weak, nonatomic) IBOutlet PasteableUILabel *numberLabel;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton *callButton;
@property (nonatomic, weak) ReachabilityBarViewController *reachabilityBarViewController;
@property (nonatomic, strong) TwoStepCallingViewController *twoStepCallingViewController;
@property (nonatomic, strong) SIPCallingViewController *sipCallingViewController;

@property (strong, nonatomic) NSString *numberText;
@property (nonatomic, strong) ReachabilityManager *reachabilityManager;
@property (nonatomic, strong) NSString *lastCalledNumber;

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
    [self.reachabilityManager stopMonitoring];
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
    [self.reachabilityManager addObserver:self forKeyPath:DialerViewControllerReachabilityStatusKey options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    [self.reachabilityManager startMonitoring];
    self.reachabilityBarViewController.status = self.reachabilityManager.status;
}

- (void)setupCallButton {
    if (self.reachabilityManager == ReachabilityManagerStatusOffline ||
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

- (SIPCallingViewController *)sipCallingViewController {
    if (!_sipCallingViewController) {
        _sipCallingViewController = [[SIPCallingViewController alloc] initWithNibName:@"SIPCallingViewController" bundle:[NSBundle mainBundle]];
        _sipCallingViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    }
    return _sipCallingViewController;
}

- (TwoStepCallingViewController *)twoStepCallingViewController {
    if (!_twoStepCallingViewController) {
        _twoStepCallingViewController = [[TwoStepCallingViewController alloc] initWithNibName:@"TwoStepCallingViewController" bundle:[NSBundle mainBundle]];
    }
    return _twoStepCallingViewController;
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
        // TODO: implement 4g calling
        if (false) {
            [GAITracker setupOutgoingSIPCallEvent];
            [self presentViewController:self.sipCallingViewController animated:YES completion:nil];
            [self.sipCallingViewController handlePhoneNumber:self.numberText forContact:nil];
        } else {
            [GAITracker setupOutgoingConnectABCallEvent];
            [self presentViewController:self.twoStepCallingViewController animated:YES completion:nil];
            [self.twoStepCallingViewController handlePhoneNumber:self.numberText];
        }
    }
}

#pragma mark - seques

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[NumberPadViewController class]]) {
        NumberPadViewController *npvc = (NumberPadViewController *)segue.destinationViewController;
        npvc.delegate = self;
    } else if ([segue.destinationViewController isKindOfClass:[ReachabilityBarViewController class]]) {
        self.reachabilityBarViewController = (ReachabilityBarViewController *)segue.destinationViewController;
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

#pragma mark - kvo

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {

    // Keep track of connection status from reachabilityManager
    if ([keyPath isEqualToString:@"status"] && change[@"new"] != change[@"old"]) {
        self.reachabilityBarViewController.status = self.reachabilityManager.status;
        [self setupCallButton];
    }
}

@end
