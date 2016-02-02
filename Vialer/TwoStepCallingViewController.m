//
//  TwoStepCallingViewController.m
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

static float const TwoStepCallingViewControllerGreyedOutAlpha = .5f;
static float const TwoStepCallingViewControllerDismissTime = 3.0;
static NSString * const TwoStepCallingViewControllerAsideIcon = @"personIcon";

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
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@property (nonatomic, strong) TwoStepCall *callManager;
@property (nonatomic, strong) NSTimer *dismissTimer;
@end

@implementation TwoStepCallingViewController

- (void)handlePhoneNumber:(NSString *)phoneNumber {
    self.callManager = [[TwoStepCall alloc] initWithANumber:[SystemUser currentUser].mobileNumber andBNumber:phoneNumber];
    [self setPhoneNumbers];
    [self.callManager addObserver:self forKeyPath:NSStringFromSelector(@selector(status)) options:0 context:NULL];
    [self.callManager start];
    [self checkCallManagerStatus];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupView];
    [self setPhoneNumbers];
    [self checkCallManagerStatus];
}

- (void)setupView {
    // Setup colors & icons
    self.backgroundHeader.backgroundColor = [Configuration tintColorForKey:ConfigurationTwoStepScreenBackgroundHeaderColor];
    self.infobarBackground.backgroundColor = [Configuration tintColorForKey:ConfigurationTwoStepScreenInfoBarBackgroundColor];
    self.vialerIconView.iconColor = [Configuration tintColorForKey:ConfigurationTwoStepScreenVialerIconColor];
    self.aSide.innerCircleColor = [Configuration tintColorForKey:ConfigurationTwoStepScreenSideAIconColor];
    UIImage *iconForAAndBSide = [UIImage imageNamed:TwoStepCallingViewControllerAsideIcon];
    self.aSide.icon = iconForAAndBSide;
    self.bSide.innerCircleColor = [Configuration tintColorForKey:ConfigurationTwoStepScreenSideBIconColor];
    self.bSide.icon = iconForAAndBSide;
    self.bubblingOne.color = [Configuration tintColorForKey:ConfigurationTwoStepScreenBubblingColor];
    self.bubblingTwo.color = [Configuration tintColorForKey:ConfigurationTwoStepScreenBubblingColor];
}

- (void)setPhoneNumbers {
    self.numberALabel.text = self.callManager.aNumber;
    self.numberBLabel.text = self.callManager.bNumber;
    self.outgoingNumberLabel.text = [SystemUser currentUser].outgoingNumber;
}

# pragma mark - actions

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([object isKindOfClass:[TwoStepCall class]]) {
        [self checkCallManagerStatus];
    }
}

- (void)checkCallManagerStatus {
    self.errorASide.hidden = true;
    self.errorBSide.hidden = true;
    self.cancelButton.enabled = self.callManager.canCancel;

    switch (self.callManager.status) {
        case TwoStepCallStatusUnknown: {
            self.callStatusLabel.text = NSLocalizedString(@"", nil);
            self.phoneNumberLabel.text = @"";
            self.bubblingOne.state = BubblingPointsStateIdle;
            [self greyoutASide];
            [self greyOutBSide];
            break;
        }
        case TwoStepCallStatusSetupCall: {
            self.callStatusLabel.text = NSLocalizedString(@"Set up call", nil);
            self.phoneNumberLabel.text = @"";
            self.bubblingOne.state = BubblingPointsStateIdle;
            [self greyoutASide];
            [self greyOutBSide];
            break;
        }
        case TwoStepCallStatusDialing_a: {
            self.callStatusLabel.text = NSLocalizedString(@"Calling your phone", nil);
            self.phoneNumberLabel.text = self.callManager.aNumber;
            self.bubblingOne.state = BubblingPointsStateConnecting;
            [self activateASide];
            [self greyOutBSide];
            break;
        }
        case TwoStepCallStatusDialing_b: {
            self.callStatusLabel.text = NSLocalizedString(@"Calling other party", nil);
            self.phoneNumberLabel.text = self.callManager.bNumber;
            self.bubblingOne.state = BubblingPointsStateConnected;
            self.bubblingTwo.state = BubblingPointsStateConnecting;
            [self activateASide];
            [self activeBSide];
            break;
        }
        case TwoStepCallStatusConnected: {
            self.callStatusLabel.text = NSLocalizedString(@"Connected with other party", nil);
            self.phoneNumberLabel.text = self.callManager.bNumber;
            self.bubblingOne.state = BubblingPointsStateConnected;
            self.bubblingTwo.state = BubblingPointsStateConnected;
            [self activateASide];
            [self activeBSide];
            break;
        }
        case TwoStepCallStatusDisconnected:{
            self.callStatusLabel.text = NSLocalizedString(@"Call ended", nil);
            self.phoneNumberLabel.text = @"";
            self.bubblingOne.state = BubblingPointsStateConnectionFailed;
            self.bubblingTwo.state = BubblingPointsStateConnectionFailed;
            [self activateASide];
            [self activeBSide];
            [self prepareDismissView];
            break;
        }
        case TwoStepCallStatusFailed_a: {
            self.callStatusLabel.text = NSLocalizedString(@"Couldn't connect with your phone", nil);
            self.phoneNumberLabel.text = self.callManager.aNumber;
            self.bubblingOne.state = BubblingPointsStateConnectionFailed;
            self.errorASide.hidden = NO;
            [self activateASide];
            [self greyOutBSide];
            [self prepareDismissView];
            break;
        }
        case TwoStepCallStatusFailed_b: {
            self.callStatusLabel.text = NSLocalizedString(@"Couldn't connect with other party", nil);
            self.phoneNumberLabel.text = self.callManager.bNumber;
            self.bubblingOne.state = BubblingPointsStateConnected;
            self.bubblingTwo.state = BubblingPointsStateConnectionFailed;
            self.errorBSide.hidden = NO;
            [self activateASide];
            [self activeBSide];
            [self prepareDismissView];
            break;
        }
        case TwoStepCallStatusUnAuthorized: {
            self.callStatusLabel.text = NSLocalizedString(@"Couldn't connect with other party", nil);
            self.phoneNumberLabel.text = self.callManager.bNumber;
            self.bubblingOne.state = BubblingPointsStateConnected;
            self.bubblingTwo.state = BubblingPointsStateConnectionFailed;
            [self activateASide];
            [self activeBSide];
            [self prepareDismissView];
            break;
        }
        case TwoStepCallStatusFailedSetup: {
            self.callStatusLabel.text = NSLocalizedString(@"Failed to setup call", nil);
            self.phoneNumberLabel.text = @"";
            self.bubblingOne.state = BubblingPointsStateConnectionFailed;
            self.bubblingTwo.state = BubblingPointsStateIdle;
            [self activateASide];
            [self greyOutBSide];
            [self prepareDismissView];
            break;
        }
        case TwoStepCallStatusInvalidNumber: {
            self.callStatusLabel.text = NSLocalizedString(@"Phone number incorrect", nil);
            self.phoneNumberLabel.text = @"";
            self.bubblingOne.state = BubblingPointsStateIdle;
            self.bubblingTwo.state = BubblingPointsStateConnectionFailed;
            [self activateASide];
            [self activeBSide];
            [self prepareDismissView];
            break;
        }
        case TwoStepCallStatusCanceled: {
            self.callStatusLabel.text = NSLocalizedString(@"Call canceled", nil);
            self.phoneNumberLabel.text = @"";
            self.bubblingOne.state = BubblingPointsStateConnectionFailed;
            self.bubblingTwo.state = BubblingPointsStateConnectionFailed;
            [self activateASide];
            [self activeBSide];
            [self prepareDismissView];
            break;
        }
    }
}

- (IBAction)cancelCall:(UIButton *)sender {
    [self.callManager cancel];
}

- (void)prepareDismissView {
    self.dismissTimer = [NSTimer scheduledTimerWithTimeInterval:TwoStepCallingViewControllerDismissTime target:self selector:@selector(dismissTimerDone:) userInfo:nil repeats:NO];
}

- (void)dismissTimerDone:(NSTimer *)timer {
    [self dismissViewControllerAnimated:YES completion:nil];
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
    [GAITracker trackScreenForControllerName:NSStringFromClass([self class])];
    [self checkCallManagerStatus];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopUpdates];
}

- (void)dealloc {
    [self stopUpdates];
}

- (void)stopUpdates {
    [self.callManager removeObserver:self forKeyPath:NSStringFromSelector(@selector(status))];
    self.callManager = nil;
    [self.dismissTimer invalidate];
}

@end
