//
//  SIPCallingViewController.m
//  Vialer
//
//  Created by Reinier Wieringa on 15/12/14.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "SIPCallingViewController.h"
#import "ConnectionHandler.h"
#import "Gossip+Extra.h"

#import "UIAlertView+Blocks.h"

#import <AVFoundation/AVAudioSession.h>
#import <AddressBook/AddressBook.h>

#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>

NSString * const OutgoingSIPCallNotification = @"com.vialer.OutgoingSIPCallNotification";

@interface SIPCallingViewController ()
@property (nonatomic, strong) NumberPadViewController *numberPadViewController;
@property (nonatomic, strong) NSString *toNumber;
@property (nonatomic, strong) NSString *toContact;
@property (nonatomic, strong) NSArray *images;
@property (nonatomic, strong) NSArray *subTitles;
@property (nonatomic, assign) UIButton *numbersButton;
@property (nonatomic, assign) UIButton *pauseButton;
@property (nonatomic, assign) UIButton *muteButton;
@property (nonatomic, assign) UIButton *speakerButton;
@property (nonatomic, strong) GSCall *outgoingCall;
@property (nonatomic, strong) GSCall *incomingCall;
@property (nonatomic, strong) NSDate *tickerStartDate;
@property (nonatomic, strong) NSDate *tickerPausedDate;
@property (nonatomic, strong) NSTimer *tickerTimer;
@end

@implementation SIPCallingViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);

    self.numberPadViewController = [[NumberPadViewController alloc] init];
    self.numberPadViewController.view.frame = CGRectOffset(self.buttonsView.frame, 0, -16.f);
    [self.view insertSubview:self.numberPadViewController.view aboveSubview:self.buttonsView];
    [self addChildViewController:self.numberPadViewController];
    self.numberPadViewController.delegate = self;
    self.numberPadViewController.view.hidden = YES;

    self.images = @[@"numbers-button", @"pause-button", @"mute-button", @"", @"speaker-button", @""];
    self.subTitles = @[NSLocalizedString(@"numbers", nil), NSLocalizedString(@"pause", nil), NSLocalizedString(@"sound off", nil), @"", NSLocalizedString(@"speaker", nil), @""];

    CGFloat buttonXSpace = self.view.frame.size.width / 3.4f;
    CGFloat leftOffset = (self.view.frame.size.width - (3.f * buttonXSpace)) / 2.f;
    self.contactLabel.frame = CGRectMake(leftOffset, self.contactLabel.frame.origin.y, self.view.frame.size.width - (leftOffset * 2.f), self.contactLabel.frame.size.height);
    self.statusLabel.frame = CGRectMake(leftOffset, self.statusLabel.frame.origin.y, self.view.frame.size.width - (leftOffset * 2.f), self.statusLabel.frame.size.height);

    [self addButtonsToView:self.buttonsView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(IncomingSIPCallNotification:) name:IncomingSIPCallNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [self showWithStatus:NSLocalizedString(@"Setting up connection...", nil)];

    // Disable all buttons
    self.pauseButton.selected = self.muteButton.selected = self.speakerButton.selected = YES;
    [self speakerButtonPressed:self.speakerButton];
    [self muteButtonPressed:self.muteButton];
    [self pauseButtonPressed:self.pauseButton];

    // Hide number pad view
    self.numberPadViewController.view.hidden = YES;
    self.hideButton.hidden = YES;
    self.buttonsView.hidden = NO;
}

- (void)addButtonsToView:(UIView *)view {
    CGFloat buttonXSpace = self.view.frame.size.width / 3.4f;
    CGFloat buttonYSpace = self.view.frame.size.width / 3.f;
    CGFloat leftOffset = (view.frame.size.width - (3.f * buttonXSpace)) / 2.f;

    CGPoint offset = CGPointMake(0, ((self.view.frame.size.height + 49.f - (buttonYSpace * 2.f)) / 2.f) - view.frame.origin.y);
    for (int j = 0; j < 2; j++) {
        offset.x = leftOffset;
        for (int i = 0; i < 3; i++) {
            NSString *image = self.images[j * 3 + i];
            if ([image length] != 0) {
                NSString *subTitle = self.subTitles[j * 3 + i];
                UIButton *button = [self createDialerButtonWithImage:image andSubTitle:subTitle];
                switch (j * 3 + i) {
                    case 0:
                        self.numbersButton = button;
                        [button addTarget:self action:@selector(numbersButtonPressed:) forControlEvents:UIControlEventTouchDown];
                        break;
                    case 1:
                        self.pauseButton = button;
                        [button addTarget:self action:@selector(pauseButtonPressed:) forControlEvents:UIControlEventTouchDown];
                        break;
                    case 2:
                        self.muteButton = button;
                        [button addTarget:self action:@selector(muteButtonPressed:) forControlEvents:UIControlEventTouchDown];
                        break;
                    case 4:
                        self.speakerButton = button;
                        [button addTarget:self action:@selector(speakerButtonPressed:) forControlEvents:UIControlEventTouchDown];
                        break;
                    default:
                        break;
                }

                button.frame = CGRectMake(offset.x, offset.y, buttonXSpace, buttonXSpace);
                [view addSubview:button];
            }

            offset.x += buttonXSpace;
        }
        offset.y += buttonYSpace;
    }
}

- (UIButton *)createDialerButtonWithImage:(NSString *)image andSubTitle:(NSString *)subTitle {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:[image stringByAppendingString:@"-highlighted"]] forState:UIControlStateHighlighted];
    [button setImage:[UIImage imageNamed:image] forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:[image stringByAppendingString:@"-highlighted"]] forState:UIControlStateSelected];
    [button setTitle:subTitle forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:14.f];
    button.enabled = NO;

    // Center the image and title
    CGFloat spacing = 4.0;
    CGSize imageSize = button.imageView.image.size;
    button.titleEdgeInsets = UIEdgeInsetsMake(0.0, -imageSize.width, -(imageSize.height + spacing), 0.0);
    CGSize titleSize = [button.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:button.titleLabel.font}];
    button.imageEdgeInsets = UIEdgeInsetsMake(-(titleSize.height + spacing), 0.0, 0.0, -titleSize.width);
    return button;
}

- (void)startTickerTimer {
    self.tickerStartDate = [NSDate date];
    self.tickerTimer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(updateTickerInterval:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.tickerTimer forMode:NSDefaultRunLoopMode];
}

- (void)stopTickerTimer {
    self.tickerStartDate = nil;
    [self.tickerTimer invalidate];
    self.tickerTimer = nil;
}

- (void)call {
    NSString *address = self.toNumber;
    if ([address rangeOfString:@"@"].location == NSNotFound) {
        address = [address stringByAppendingFormat:@"@%@", [ConnectionHandler sharedConnectionHandler].sipDomain];
    }

    self.outgoingCall = [GSCall outgoingCallToUri:address fromAccount:[GSUserAgent sharedAgent].account];

    // Register status change observer
    [self.outgoingCall addObserver:self
                        forKeyPath:@"status"
                           options:NSKeyValueObservingOptionInitial
                           context:nil];

    // begin calling after 1s
    const double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.outgoingCall begin];
        [self callStatusDidChange];
    });
}

- (void)hangup {
    if (!self.outgoingCall) {
        return;
    }

    if (self.outgoingCall.status == GSCallStatusConnected) {
        [self.outgoingCall end];
    }

    [self.outgoingCall removeObserver:self forKeyPath:@"status"];
    self.outgoingCall = nil;
}

- (void)dismiss {
    [UIDevice currentDevice].proximityMonitoringEnabled = NO;
    [self hangup];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissStatus:(NSString *)status {
    if (status) {
        [self showErrorWithStatus:status];
    } else {
        [self dismiss];
    }
}

- (void)showWithStatus:(NSString *)status {
    self.statusLabel.text = status;
}

- (void)showErrorWithStatus:(NSString *)status {
    self.statusLabel.text = status;
    [self performSelector:@selector(dismiss) withObject:nil afterDelay:1.5f];
}

- (void)handlePhoneNumber:(NSString *)phoneNumber forContact:(NSString *)contact {
    self.toNumber = phoneNumber;
    self.toContact = contact ? contact : phoneNumber;
    [self sipDial];
}

- (void)sipDial {
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"SIPAccount"]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Account" message:@"Enter SIP account" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        [alertView setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
        [alertView textFieldAtIndex:0].text = @"129500039";
        [alertView textFieldAtIndex:0].keyboardType = UIKeyboardTypeEmailAddress;
        [alertView textFieldAtIndex:1].text = @"nj2xbhTe4AMfA2s";

        [alertView setTapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex == 0) {
                return;
            }

            NSString *account = [alertView textFieldAtIndex:0].text;
            NSString *password = [alertView textFieldAtIndex:1].text;
            NSArray *accountComponents = [account componentsSeparatedByString:@"@"];
            if ([accountComponents count] == 2) {
                account = accountComponents[0];
            }

            account = [[account componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString:@""];
            password = [[password componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString:@""];
            if ([account length] && [password length]) {
                [[NSUserDefaults standardUserDefaults] setObject:account forKey:@"SIPAccount"];
                [[NSUserDefaults standardUserDefaults] setObject:password forKey:@"SIPPassword"];   // TODO: Use key chain when SIP account is available through API
                [[NSUserDefaults standardUserDefaults] synchronize];
            }

            [self sipDial];
        }];

        [alertView show];

        return;
    }

    if (!self.presentingViewController) {
        [[[[UIApplication sharedApplication] delegate] window].rootViewController presentViewController:self animated:YES completion:nil];
    }

    self.toNumber = [[self.toNumber componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString:@""];
    self.toNumber = [[self.toNumber componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"+0123456789"] invertedSet]] componentsJoinedByString:@""];
    self.contactLabel.text = self.toContact;

    NSLog(@"Calling %@...", self.toNumber);

    [self call];
}

- (void)callStatusDidChange {
    switch (self.outgoingCall.status) {
        case GSCallStatusReady: {
            self.numbersButton.enabled = self.pauseButton.enabled = self.muteButton.enabled = self.speakerButton.enabled = NO;
        } break;

        case GSCallStatusConnecting: {
            [self showWithStatus:NSLocalizedString(@"Setting up connection...", nil)];
        } break;

        case GSCallStatusCalling: {
        } break;

        case GSCallStatusConnected: {
            self.numbersButton.enabled = self.muteButton.enabled = self.speakerButton.enabled = YES;

            [self startTickerTimer];
            [UIDevice currentDevice].proximityMonitoringEnabled = YES;
            self.pauseButton.enabled = YES;

            [[NSNotificationCenter defaultCenter] postNotificationName:OutgoingSIPCallNotification object:self.outgoingCall];
        } break;

        case GSCallStatusDisconnected: {
            self.numbersButton.enabled = self.pauseButton.enabled = self.muteButton.enabled = self.speakerButton.enabled = NO;

            [self stopTickerTimer];
            [self showErrorWithStatus:NSLocalizedString(@"Call ended", nil)];
            [self.outgoingCall removeObserver:self forKeyPath:@"status"];
            self.outgoingCall = nil;
        } break;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"status"] && [object isKindOfClass:[GSCall class]]) {
        [self callStatusDidChange];
    }
}

#pragma mark - Timer

- (void)updateTickerInterval:(NSTimer *)timer {
    if (self.pauseButton.isSelected) {
        return;
    }

    if (self.outgoingCall.status == GSCallStatusConnected) {
        NSInteger timePassed = -[self.tickerStartDate timeIntervalSinceNow];
        [self showWithStatus:[NSString stringWithFormat:@"%02d:%02d", (unsigned)(timePassed / 60), (unsigned)(timePassed % 60)]];
    }
}

#pragma mark - Actions

- (void)numbersButtonPressed:(UIButton *)sender {
    self.hideButton.alpha = 0.f;
    self.hideButton.hidden = NO;
    self.numberPadViewController.view.alpha = 0.f;
    self.numberPadViewController.view.hidden = NO;
    self.numberPadViewController.view.transform = CGAffineTransformMakeScale(0.5f, 0.5f);
    [UIView animateWithDuration:0.4f animations:^{
        self.buttonsView.transform = CGAffineTransformMakeScale(0.5f, 0.5f);
        self.buttonsView.alpha = 0.f;
        self.hideButton.alpha = 1.f;
        self.numberPadViewController.view.alpha = 1.f;
        self.numberPadViewController.view.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.buttonsView.hidden = YES;
        self.buttonsView.alpha = 1.f;
        self.buttonsView.transform = CGAffineTransformIdentity;
    }];
}

- (void)muteButtonPressed:(UIButton *)sender {
    [sender setSelected:!sender.isSelected];
    self.outgoingCall.volume = sender.isSelected ? 0.f : 1.f;
}

- (void)pauseButtonPressed:(UIButton *)sender {
    [sender setSelected:!sender.isSelected];
    self.outgoingCall.paused = sender.isSelected;
    if (sender.isSelected) {
        self.tickerPausedDate = [NSDate date];
    } else {
        self.tickerStartDate = [self.tickerStartDate dateByAddingTimeInterval:-[self.tickerPausedDate timeIntervalSinceNow]];
        self.tickerPausedDate = nil;
    }
}

- (void)speakerButtonPressed:(UIButton *)sender {
    [sender setSelected:!sender.isSelected];

    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:NULL];
    [session overrideOutputAudioPort:sender.isSelected ? AVAudioSessionPortOverrideSpeaker : AVAudioSessionPortOverrideNone error:NULL];
    [session setActive:YES error:NULL];
}

- (IBAction)hangupButtonPressed:(UIButton *)sender {
    [self dismiss];
}

- (IBAction)hideButtonPressed:(UIButton *)sender {
    self.buttonsView.alpha = 0.f;
    self.buttonsView.hidden = NO;
    self.buttonsView.transform = CGAffineTransformMakeScale(0.5f, 0.5f);
    [UIView animateWithDuration:0.4f animations:^{
        self.hideButton.alpha = 0.f;
        self.numberPadViewController.view.transform = CGAffineTransformMakeScale(0.5f, 0.5f);
        self.numberPadViewController.view.alpha = 0.f;
        self.buttonsView.alpha = 1.f;
        self.buttonsView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.hideButton.hidden = YES;
        self.numberPadViewController.view.hidden = YES;
        self.numberPadViewController.view.alpha = 1.f;
        self.numberPadViewController.view.transform = CGAffineTransformIdentity;
    }];
}

- (void)IncomingSIPCallNotification:(NSNotification *)notification {
    self.incomingCall = notification.object;
    [self.incomingCall begin];
}

#pragma mark - NumberPadViewController delegate

- (void)numberPadPressedWithCharacter:(NSString *)character {
    if (self.outgoingCall) {
        [self.outgoingCall sendDTMFDigits:character];
    }
}

@end
