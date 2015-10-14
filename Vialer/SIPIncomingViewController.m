//
//  SIPIncomingViewController.m
//  Vialer
//
//  Created by Reinier Wieringa on 19/01/15.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "SIPIncomingViewController.h"

#import "AppDelegate.h"
#import "ConnectionHandler.h"
#import "GAITracker.h"
#import "Gossip+Extra.h"
#import "UIAlertView+Blocks.h"

#import <AddressBook/AddressBook.h>
#import <AVFoundation/AVAudioSession.h>
#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTCallCenter.h>

@interface SIPIncomingViewController ()
@property (nonatomic, strong) GSCall *incomingCall;
@end

@implementation SIPIncomingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(incomingSIPCallNotification:) name:IncomingSIPCallNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.contactLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:28.f];
    self.statusLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:20.f];
    self.declineButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:20.f];
    self.declineButton.titleLabel.textColor = [UIColor blackColor];
    self.acceptButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:20.f];
    self.acceptButton.titleLabel.textColor = [UIColor blackColor];

    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);

    CGFloat buttonXSpace = self.view.frame.size.width / 3.4f;
    CGFloat leftOffset = (self.view.frame.size.width - (3.f * buttonXSpace)) / 2.f;
    self.contactLabel.frame = CGRectMake(leftOffset, self.contactLabel.frame.origin.y, self.view.frame.size.width - (leftOffset * 2.f), self.contactLabel.frame.size.height);
    self.statusLabel.frame = CGRectMake(leftOffset, self.statusLabel.frame.origin.y, self.view.frame.size.width - (leftOffset * 2.f), self.statusLabel.frame.size.height);

    [self.acceptButton setTitle:NSLocalizedString(@"Accept", nil) forState:UIControlStateNormal];
    [self.declineButton setTitle:NSLocalizedString(@"Decline", nil) forState:UIControlStateNormal];

    CGFloat spacing = 4.0;
    CGSize imageSize = self.acceptButton.imageView.image.size;
    self.acceptButton.titleEdgeInsets = UIEdgeInsetsMake(0.0, -imageSize.width, -(imageSize.height + spacing), 0.0);
    CGSize titleSize = [self.acceptButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:self.acceptButton.titleLabel.font}];
    self.acceptButton.imageEdgeInsets = UIEdgeInsetsMake(-(titleSize.height + spacing), 0.0, 0.0, -titleSize.width);

    self.declineButton.titleEdgeInsets = UIEdgeInsetsMake(0.0, -imageSize.width, -(imageSize.height + spacing), 0.0);
    titleSize = [self.declineButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:self.declineButton.titleLabel.font}];
    self.declineButton.imageEdgeInsets = UIEdgeInsetsMake(-(titleSize.height + spacing), 0.0, 0.0, -titleSize.width);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [GAITracker trackScreenForControllerName:NSStringFromClass([self class])];

    self.contactLabel.text = self.incomingCall.remoteInfo;
    self.statusLabel.text = NSLocalizedString(@"Mobile", nil);
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

/**
 * Handle an incoming SIP call. Active GSCall object is attached to notification.object. 
 * The 'self.incomingCall' property is the active GSCall object which manages call interaction. 
 * It is set to nil when the call is ended or interupted by [self callStatusDidChange].
 * So, on every incoming call; check if there is an active one. If there is: end the newly incoming call.
 */
- (void)incomingSIPCallNotification:(NSNotification *)notification {

    // First check if the notification.object contains an incoming GSCall object instance
    id possibleNewCall = notification.object;
    if (!(possibleNewCall && [possibleNewCall isKindOfClass:GSCall.class])) {
        return; // The new expected "call" is nil or not of the expected type!
    }
    
    if (self.incomingCall == nil) { // There is no active call. Handle newly incoming.
        self.incomingCall = notification.object;
        // Register status change observer
        [self.incomingCall addObserver:self
                            forKeyPath:@"status"
                               options:NSKeyValueObservingOptionInitial
                               context:nil];

        UIViewController *presentedViewController = [[[[UIApplication sharedApplication] delegate] window].rootViewController presentedViewController];
        if (presentedViewController) {
            [presentedViewController presentViewController:self animated:YES completion:nil];
        } else {
            [[[[UIApplication sharedApplication] delegate] window].rootViewController presentViewController:self animated:YES completion:nil];
        }
    } else {
        // There is an active call: end the newly incoming one. We did a nil and type check earlier.
        [(GSCall *)possibleNewCall end];
    }
}

- (IBAction)acceptButtonPressed:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    AppDelegate *appDelegate = ((AppDelegate *)[UIApplication sharedApplication].delegate);
    [appDelegate handleSipCall:self.incomingCall];
}

- (IBAction)declineButtonPressed:(UIButton *)sender {
    [self dismiss];
}

- (void)hangup {
    if (self.incomingCall) {
        if (self.incomingCall.status == GSCallStatusConnected) {
            [self.incomingCall end];
        }

        [self.incomingCall stopRinging];
        [self.incomingCall removeObserver:self forKeyPath:@"status"];
        self.incomingCall = nil;
    }

    // Update connection when a call has ended
    [[ConnectionHandler sharedConnectionHandler] sipUpdateConnectionStatus];
}

- (void)dismiss {
    [self hangup];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)callStatusDidChange {
    switch (self.incomingCall.status) {
        case GSCallStatusReady: {
            [self.incomingCall startRinging];
        } break;

        case GSCallStatusConnecting: {
        } break;

        case GSCallStatusCalling: {
        } break;

        case GSCallStatusConnected: {
            [self.incomingCall stopRinging];
        } break;

        case GSCallStatusDisconnected: {
            [self dismiss];
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

@end
