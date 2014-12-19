//
//  PJSIPTestViewController.m
//  Vialer
//
//  Created by Reinier Wieringa on 20/11/14.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "PJSIPTestViewController.h"
#import "Gossip.h"
#import "UIAlertView+Blocks.h"

#import <AudioToolbox/AudioServices.h>

@interface PJSIPTestViewController ()
@property (nonatomic, strong) GSAccountConfiguration *account;
@property (nonatomic, strong) GSConfiguration *config;
@property (nonatomic, strong) GSUserAgent *userAgent;
@property (nonatomic, strong) GSCall *outgoingCall;
@property (nonatomic, strong) GSCall *incomingCall;
@end

@implementation PJSIPTestViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"PJSIP Test", nil);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    [self.connectButton setTitle:@"Connect" forState:UIControlStateNormal];
    [self.callButton setTitle:@"Call" forState:UIControlStateNormal];
    self.callButton.enabled = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - GSAccountDelegate

- (void)account:(GSAccount *)account didReceiveIncomingCall:(GSCall *)call {
    self.incomingCall = call;
    [self.incomingCall begin];
}

- (IBAction)connectButtonPressed:(UIButton *)sender {
    if (!self.account) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Account" message:@"Enter SIP account" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        [alertView setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
        [alertView textFieldAtIndex:0].text = @"129500039@ha.voys.nl";
        [alertView textFieldAtIndex:0].keyboardType = UIKeyboardTypeEmailAddress;
        [alertView textFieldAtIndex:1].text = @"nj2xbhTe4AMfA2s";

        [alertView setTapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex == 0) {
                return;
            }

            NSString *address = [alertView textFieldAtIndex:0].text;
            NSString *password = [alertView textFieldAtIndex:1].text;

            NSArray *accountComponents = [address componentsSeparatedByString:@"@"];
            if ([accountComponents count] == 2) {
                NSString *username = accountComponents[0];
                NSString *domain = accountComponents[1];

                self.account = [GSAccountConfiguration defaultConfiguration];
                self.account.address = address;
                self.account.username = username;
                self.account.password = password;
                self.account.domain = domain;
                self.account.enableRingback = NO;

                [self connect];
            }
        }];

        [alertView show];
    } else {
        if (self.userAgent.account.status == GSAccountStatusConnected) {
            [self disconnect];
        } else {
            [self connect];
        }
    }
}

- (void)connect {
    if (!self.config) {
        self.config = [GSConfiguration defaultConfiguration];
        self.config.account = self.account;
        self.config.logLevel = 3;
        self.config.consoleLogLevel = 3;
    }

    if (!self.userAgent) {
        self.userAgent = [GSUserAgent sharedAgent];

        [self.userAgent configure:self.config];
        [self.userAgent start];

        [self.userAgent.account addObserver:self
                                 forKeyPath:@"status"
                                    options:NSKeyValueObservingOptionInitial
                                    context:nil];
    }

    self.userAgent.account.delegate = self;

    if (self.userAgent.account.status == GSAccountStatusOffline) {
        [self.userAgent.account connect];
    }
}

- (void)disconnect {
    if (self.userAgent.account.status == GSAccountStatusConnected) {
        [self.userAgent.account disconnect];
    }
}

- (IBAction)callButtonPressed:(UIButton *)sender {
    if (self.outgoingCall) {
        [self hangup];
    } else {
        [self call];
    }
}

- (void)call {
    if (self.userAgent.status >= GSUserAgentStateConfigured) {
        NSArray *codecs = [self.userAgent arrayOfAvailableCodecs];
        for (GSCodecInfo *codec in codecs) {
            if ([codec.codecId isEqual:@"PCMA/8000/1"]) {
                [codec setPriority:254];
            }
        }
    }

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Account" message:@"Enter SIP account" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    [alertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [alertView textFieldAtIndex:0].text = @"0508009000";
//    [alertView textFieldAtIndex:0].text = @"129500005@ha.voys.nl";
//    [alertView textFieldAtIndex:0].text = @"129500039@ha.voys.nl";
    [alertView textFieldAtIndex:0].keyboardType = UIKeyboardTypeEmailAddress;

    [alertView setTapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex == 0) {
            return;
        }

        NSString *address = [alertView textFieldAtIndex:0].text;
        if ([address rangeOfString:@"@"].location == NSNotFound) {
            address = [address stringByAppendingString:@"@ha.voys.nl"];
        }

        self.outgoingCall = [GSCall outgoingCallToUri:address fromAccount:self.userAgent.account];

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
    }];

    [alertView show];
}

- (void)hangup {
    if (!self.outgoingCall) {
        return;
    }

    [self.outgoingCall end];
    [self.outgoingCall removeObserver:self forKeyPath:@"status"];
    self.outgoingCall = nil;
}

- (void)callStatusDidChange {
    switch (self.outgoingCall.status) {
        case GSCallStatusReady: {
            [self.statusLabel setText:@"Ready."];
        } break;

        case GSCallStatusConnecting: {
            [self.statusLabel setText:@"Connecting..."];
        } break;

        case GSCallStatusCalling: {
            [self.statusLabel setText:@"Calling..."];
        } break;

        case GSCallStatusConnected: {
            [self.statusLabel setText:@"Connected."];
            [self.callButton setTitle:@"Hang up" forState:UIControlStateNormal];
        } break;

        case GSCallStatusDisconnected: {
            [self.statusLabel setText:@"Disconnected."];
            [self.callButton setTitle:@"Call" forState:UIControlStateNormal];
            [self.outgoingCall removeObserver:self forKeyPath:@"status"];
            self.outgoingCall = nil;
        } break;
    }
}

- (void)accountStatusDidChange {
    switch (self.userAgent.account.status) {
        case GSAccountStatusOffline: {
            [self.statusLabel setText:@"Offline."];
            [self.connectButton setTitle:@"Connect" forState:UIControlStateNormal];
            self.callButton.enabled = NO;
        } break;

        case GSAccountStatusInvalid: {
            [self.statusLabel setText:@"Invalid."];
        } break;

        case GSAccountStatusConnecting: {
            [self.statusLabel setText:@"Connecting..."];
        } break;

        case GSAccountStatusConnected: {
            [self.statusLabel setText:@"Online."];
            [self.connectButton setTitle:@"Disconnect" forState:UIControlStateNormal];
            self.callButton.enabled = YES;
        } break;

        case GSAccountStatusDisconnecting: {
            [self.statusLabel setText:@"Disconnecting..."];
        } break;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        if ([object isKindOfClass:[GSAccount class]]) {
            [self accountStatusDidChange];
        } else {
            [self callStatusDidChange];
        }
    }
}

@end
