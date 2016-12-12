//
//  DialerViewController.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "DialerViewController.h"

#import "AppDelegate.h"
@import AVFoundation;
#import "Configuration.h"
#import "PasteableUILabel.h"
#import "PhoneNumberUtils.h"
#import "NumberPadButton.h"
#import "ReachabilityManager.h"
#import "ReachabilityBarViewController.h"
#import "SystemUser.h"
#import "SIPUtils.h"
#import "TwoStepCallingViewController.h"
#import "UIViewController+MMDrawerController.h"
#import "Vialer-Swift.h"

static NSString * const DialerViewControllerTabBarItemImage = @"tab-keypad";
static NSString * const DialerViewControllerTabBarItemActiveImage = @"tab-keypad-active";
static NSString * const DialerViewControllerLogoImage = @"logo";
static NSString * const DialerViewControllerLeftDrawerButtonImage = @"menu";
static NSString * const DialerViewControllerTwoStepCallingSegue = @"TwoStepCallingSegue";
static NSString * const DialerViewControllerSIPCallingSegue = @"SIPCallingSegue";

@interface DialerViewController () <PasteableUILabelDelegate, ReachabilityBarViewControllerDelegate>

@property (strong, nonatomic) UIBarButtonItem *leftDrawerButton;
@property (weak, nonatomic) IBOutlet PasteableUILabel *numberLabel;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton *callButton;

@property (nonatomic) ReachabilityManagerStatusType reachabilityStatus;
@property (strong, nonatomic) NSString *numberText;
@property (strong, nonatomic) NSString *lastCalledNumber;

@property (nonatomic, strong) NSDictionary *sounds;

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
    [self setupSounds];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [VialerGAITracker trackScreenForControllerWithName:NSStringFromClass([self class])];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
    [self setupCallButton];

    // Set initial state of deletebutton, hidden and disabled.
    self.deleteButton.alpha = 0;
    self.deleteButton.enabled = false;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

#pragma mark - setup

- (void)setupLayout {
    self.numberText = @"";
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:DialerViewControllerLogoImage]];
}

- (void)setupCallButton {
    if (self.reachabilityStatus == ReachabilityManagerStatusOffline ||
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
    self.numberLabel.text = [PhoneNumberUtils cleanPhoneNumber:numberText];
    [self setupCallButton];
    [self toggleDeleteButton];
}

- (void)toggleDeleteButton {
    self.deleteButton.enabled = !(self.numberText.length == 0);
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.deleteButton.alpha = (self.numberText.length == 0) ? 0.0 : 1.0;
    } completion:nil];
}

- (NSString *)numberText {
    return self.numberLabel.text ?: @"";
}

- (void)setLastCalledNumber:(NSString *)lastCalledNumber {
    _lastCalledNumber = lastCalledNumber;
    [self setupCallButton];
}

#pragma mark - actions

- (IBAction)leftDrawerButtonPress:(UIBarButtonItem *)sender{
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (IBAction)backButtonPressed:(UIButton *)sender {
    if (self.numberText.length > 0) {
        self.numberText = [self.numberText substringToIndex:self.numberText.length - 1];
        [self toggleDeleteButton];
    }
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

        if (self.reachabilityStatus == ReachabilityManagerStatusHighSpeed && [SystemUser currentUser].sipEnabled) {
            [VialerGAITracker setupOutgoingSIPCallEvent];
            [self performSegueWithIdentifier:DialerViewControllerSIPCallingSegue sender:self];
        } else {
            [VialerGAITracker setupOutgoingConnectABCallEvent];
            [self performSegueWithIdentifier:DialerViewControllerTwoStepCallingSegue sender:self];
        }
    }
}

- (IBAction)numberPressed:(NumberPadButton *)sender {
    [self numberPadPressedWithCharacter:sender.number];
    [self playSoundForCharacter:sender.number];
    [self toggleDeleteButton];
}

- (IBAction)longPressZeroButton:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        [self playSoundForCharacter:@"0"];
        [self numberPadPressedWithCharacter:@"+"];
    }
}

- (void)setupSounds {
    if (!self.sounds) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSMutableDictionary *sounds = [NSMutableDictionary dictionary];
            for (NSString *sound in @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"*", @"0", @"#"]) {
                NSString *dtmfFile;
                if ([sound isEqualToString:@"*"]) {
                    dtmfFile = @"dtmf-s";
                } else {
                    dtmfFile = [NSString stringWithFormat:@"dtmf-%@", sound];
                }
                NSURL *dtmfUrl = [[NSBundle mainBundle] URLForResource:dtmfFile withExtension:@"aif"];
                NSAssert(dtmfUrl, @"No sound available");
                NSError *error;
                AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:dtmfUrl error:&error];
                if (!error) {
                    [player prepareToPlay];
                }
                sounds[sound] = player;
            }
            self.sounds = [sounds copy];
        });
    }
}

- (void)playSoundForCharacter:(NSString *)character {
    AVAudioPlayer *player = self.sounds[character];
    [player setCurrentTime:0];
    [player play];
}

#pragma mark - segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[ReachabilityBarViewController class]]) {
        ReachabilityBarViewController *rbvc = (ReachabilityBarViewController *)segue.destinationViewController;
        rbvc.delegate = self;
    } else if ([segue.destinationViewController isKindOfClass:[TwoStepCallingViewController class]]) {
        TwoStepCallingViewController *tscvc = (TwoStepCallingViewController *)segue.destinationViewController;
        [tscvc handlePhoneNumber:self.numberText];
        self.numberText = @"";
    } else if ([segue.destinationViewController isKindOfClass:[SIPCallingViewController class]]) {
        SIPCallingViewController *sipCallingVC = (SIPCallingViewController *)segue.destinationViewController;

        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        if (appDelegate.isScreenshotRun) {
            [sipCallingVC handleOutgoingCallForScreenshotWithPhoneNumber:self.numberText];
        } else {
            [sipCallingVC handleOutgoingCallWithPhoneNumber:self.numberText contact:nil];
        }
        self.numberText = @"";
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

#pragma mark - ReachabilityBarViewControllerDelegate

- (void)reachabilityBar:(ReachabilityBarViewController *)reachabilityBar statusChanged:(ReachabilityManagerStatusType)status {
    self.reachabilityStatus = status;
}

@end
