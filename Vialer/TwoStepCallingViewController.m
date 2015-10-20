//
//  TwoStepCallingViewController.m
//  Vialer
//
//  Created by Bob Voorneveld on 19/10/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "TwoStepCallingViewController.h"

#import "BubblingPoints.h"
#import "CircleWithWhiteIcon.h"
#import "Configuration.h"
#import "GAITracker.h"
#import "SystemUser.h"
#import "TwoStepCall.h"
#import "VialerIconView.h"

typedef NS_ENUM(NSInteger, CallingState) {
    CallingStateIdle,
    CallingStateCallingA,
    CallingStateConnectedA,
    CallingStateConnectionFailedA,
    CallingStateCallingB,
    CallingStateConnectedB,
    CallingStateConnectionFailedB,
    CallingStateDisconnectedB,
};

static float const TwoStepCallingViewControllerGreyedOutAlpha = .5f;
static float const TwoStepCallingViewControllerDismissTime = 3.0;

@interface TwoStepCallingViewController ()
@property (weak, nonatomic) IBOutlet BubblingPoints *bubblingOne;
@property (weak, nonatomic) IBOutlet BubblingPoints *bubblingTwo;
@property (weak, nonatomic) IBOutlet VialerIconView *vialerIconView;
@property (weak, nonatomic) IBOutlet UILabel *outgoingNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *numberALabel;
@property (weak, nonatomic) IBOutlet UILabel *numberBLabel;
@property (weak, nonatomic) IBOutlet UILabel *errorASide;
@property (weak, nonatomic) IBOutlet UILabel *errorBSide;
@property (weak, nonatomic) IBOutlet CircleWithWhiteIcon *aSide;
@property (weak, nonatomic) IBOutlet CircleWithWhiteIcon *bSide;
@property (weak, nonatomic) IBOutlet UILabel *numberAHeaderLabel;
@property (weak, nonatomic) IBOutlet UILabel *numberBHeaderLabel;
@property (weak, nonatomic) IBOutlet UIView *backgroundHeader;
@property (weak, nonatomic) IBOutlet UILabel *callStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneNumberLabel;
@property (weak, nonatomic) IBOutlet UIView *infobarBackground;

@property (nonatomic) CallingState state;
@property (nonatomic, weak) NSString *outgoingNumber;
@property (nonatomic, weak) NSString *numberA;
@property (nonatomic, weak) NSString *numberB;

@property (nonatomic, strong) TwoStepCall *callManager;
@property (nonatomic, strong) NSTimer *dismissTimer;
@end

@implementation TwoStepCallingViewController

- (void)handlePhoneNumber:(NSString *)phoneNumber forContact:(NSString *)contact {
    if (!self.presentingViewController) {
        [[[[UIApplication sharedApplication] delegate] window].rootViewController presentViewController:self animated:YES completion:nil];

        self.numberB = phoneNumber;
        self.numberA = [SystemUser currentUser].mobileNumber;
        self.outgoingNumber = [SystemUser currentUser].outgoingNumber;
        [self.callManager start];
    }
}

- (void)viewDidLoad {
    [self setup];
}

- (void)setup {
    // Setup colors & icons
    self.backgroundHeader.backgroundColor = [Configuration tintColorForKey:kBackgroundHeaderTwoStepScreen];
    self.infobarBackground.backgroundColor = [Configuration tintColorForKey:kBackgroundInfoBarTwoStepScreen];
    self.vialerIconView.iconColor = [Configuration tintColorForKey:kVialerIconTwoStepScreen];
    self.aSide.innerCircleColor = [Configuration tintColorForKey:kSideAIconTwoStepScreen];
    self.aSide.icon = [UIImage imageNamed:@"personIcon"];
    self.bSide.innerCircleColor = [Configuration tintColorForKey:kSideBIconTwoStepScreen];
    self.bSide.icon = [UIImage imageNamed:@"personIcon"];
    self.bubblingOne.color = [Configuration tintColorForKey:kBubblingTwoStepScreen];
    self.bubblingTwo.color = [Configuration tintColorForKey:kBubblingTwoStepScreen];

    self.state = CallingStateIdle;
}

# pragma mark - Properties

- (NSString *)outgoingNumber {
    return self.outgoingNumberLabel.text;
}

- (void)setOutgoingNumber:(NSString *)outgoingNumber {
    self.outgoingNumberLabel.text = outgoingNumber;
}

- (NSString *)numberA {
    return self.numberALabel.text;
}

- (void)setNumberA:(NSString *)numberA {
    self.numberALabel.text = numberA;
}

- (NSString *)numberB {
    return self.numberBLabel.text;
}

- (void)setNumberB:(NSString *)numberB {
    self.numberBLabel.text = numberB;
}

- (TwoStepCall *)callManager {
    if (!_callManager) {
        _callManager = [[TwoStepCall alloc] initWithANumber:self.numberA andBNumber:self.numberB];
        [_callManager addObserver:self forKeyPath:NSStringFromSelector(@selector(status)) options:0 context:NULL];
    }
    return _callManager;
}

# pragma mark - actions

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([object isKindOfClass:[TwoStepCall class]]) {
        switch (self.callManager.status) {
            case twoStepCallStatusUnknown:
                self.state = CallingStateIdle;
                break;
            case twoStepCallStatusDialing_a:
                self.state = CallingStateCallingA;
                break;
            case twoStepCallStatusConfirm:
                self.state = CallingStateConnectedA;
                break;
            case twoStepCallStatusDialing_b:
                self.state = CallingStateCallingB;
                break;
            case twoStepCallStatusConnected:
                self.state = CallingStateConnectedB;
                break;
            case twoStepCallStatusDisconnected:
                self.state = CallingStateDisconnectedB;
                [self prepareDismissView];
                break;
            case twoStepCallStatusFailed_a:
                self.state = CallingStateConnectionFailedA;
                [self prepareDismissView];
                break;
            case twoStepCallStatusFailed_b:
                self.state = CallingStateConnectionFailedB;
                [self prepareDismissView];
                break;
            default:
                break;
        }
    }
}

- (void)prepareDismissView {
    self.dismissTimer = [NSTimer scheduledTimerWithTimeInterval:TwoStepCallingViewControllerDismissTime target:self selector:@selector(dismissTimerDone:) userInfo:nil repeats:NO];
}

- (void)dismissTimerDone:(NSTimer *)timer {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setState:(CallingState)state {
    _state = state;
    switch (state) {
        case CallingStateIdle:
            self.callStatusLabel.text = NSLocalizedString(@"", nil);
            self.phoneNumberLabel.text = @"";
            self.bubblingOne.state = BubblingPointsStateIdle;
            [self greyoutASide];
            [self greyOutBSide];
            break;
        case CallingStateCallingA:
            self.callStatusLabel.text = NSLocalizedString(@"Calling your phone", nil);
            self.phoneNumberLabel.text = self.numberA;
            self.bubblingOne.state = BubblingPointsStateConnecting;
            [self activateASide];
            [self greyOutBSide];
            break;
        case CallingStateConnectedA:
            self.callStatusLabel.text = NSLocalizedString(@"Connected with your phone", nil);
            self.phoneNumberLabel.text = self.numberA;
            self.bubblingOne.state = BubblingPointsStateConnected;
            [self activateASide];
            [self greyOutBSide];
            break;
        case CallingStateConnectionFailedA:
            self.callStatusLabel.text = NSLocalizedString(@"Couldn't connect with your phone", nil);
            self.phoneNumberLabel.text = self.numberA;
            self.bubblingOne.state = BubblingPointsStateConnectionFailed;
            [self activateASide];
            [self greyOutBSide];
            break;
        case CallingStateCallingB:
            self.callStatusLabel.text = NSLocalizedString(@"Calling other party", nil);
            self.phoneNumberLabel.text = self.numberB;
            self.bubblingOne.state = BubblingPointsStateConnected;
            self.bubblingTwo.state = BubblingPointsStateConnecting;
            [self activateASide];
            [self activeBSide];
            break;
        case CallingStateConnectedB:
            self.callStatusLabel.text = NSLocalizedString(@"Connected with other party", nil);
            self.phoneNumberLabel.text = self.numberB;
            self.bubblingOne.state = BubblingPointsStateConnected;
            self.bubblingTwo.state = BubblingPointsStateConnected;
            [self activateASide];
            [self activeBSide];
            break;
        case CallingStateConnectionFailedB:
            self.callStatusLabel.text = NSLocalizedString(@"Couldn't connect with other party", nil);
            self.phoneNumberLabel.text = self.numberB;
            self.bubblingOne.state = BubblingPointsStateConnected;
            self.bubblingTwo.state = BubblingPointsStateConnectionFailed;
            [self activateASide];
            [self activeBSide];
            break;
        case CallingStateDisconnectedB:
            self.callStatusLabel.text = NSLocalizedString(@"Call ended", nil);
            self.phoneNumberLabel.text = @"";
            self.bubblingOne.state = BubblingPointsStateConnectionFailed;
            self.bubblingTwo.state = BubblingPointsStateConnectionFailed;
            [self activateASide];
            [self activeBSide];
    }
    [self showErrorMessagesForState:state];
}

- (void)showErrorMessagesForState:(CallingState)state {
    self.errorASide.hidden = true;
    self.errorBSide.hidden = true;
    if (state == CallingStateConnectionFailedA) {
        self.errorASide.hidden = false;
    } else if (state == CallingStateConnectionFailedB) {
        self.errorBSide.hidden = false;
    }
}

- (void)greyOutBSide {
    self.bubblingTwo.state = BubblingPointsStateIdle;
    self.bubblingTwo.alpha = TwoStepCallingViewControllerGreyedOutAlpha;
    self.bSide.alpha = TwoStepCallingViewControllerGreyedOutAlpha;
    self.numberBLabel.alpha = TwoStepCallingViewControllerGreyedOutAlpha;
    self.numberBHeaderLabel.alpha = TwoStepCallingViewControllerGreyedOutAlpha;
}

- (void)activeBSide {
    self.bubblingTwo.alpha = 1.0;
    self.bSide.alpha = 1.0;
    self.numberBLabel.alpha = 1.0;
    self.numberBHeaderLabel.alpha = 1.0;
}

- (void)greyoutASide {
    self.aSide.alpha = TwoStepCallingViewControllerGreyedOutAlpha;
    self.numberALabel.alpha = TwoStepCallingViewControllerGreyedOutAlpha;
    self.numberAHeaderLabel.alpha = TwoStepCallingViewControllerGreyedOutAlpha;
}

- (void)activateASide {
    self.aSide.alpha = 1.0;
    self.numberALabel.alpha = 1.0;
    self.numberAHeaderLabel.alpha = 1.0;
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.state = CallingStateIdle;
    [GAITracker trackScreenForControllerName:NSStringFromClass([self class])];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self stopUpdates];
}

- (void)dealloc {
    [self.callManager removeObserver:self forKeyPath:NSStringFromSelector(@selector(status))];
    [self stopUpdates];
}

- (void)stopUpdates {
    self.callManager = nil;
    if (self.dismissTimer) {
        [self.dismissTimer invalidate];
    }
}

@end
