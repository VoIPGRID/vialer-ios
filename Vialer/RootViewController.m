//
//  RootViewController.m
//  Vialer
//
//  Created by Bob Voorneveld on 06/10/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//
#import "RootViewController.h"

#import "GAITracker.h"
#import "SIPCallingViewController.h"
#import "SIPIncomingViewController.h"

@interface RootViewController ()
@property (nonatomic, strong) SIPCallingViewController *sipCallingViewController;
@property (nonatomic, strong) SIPIncomingViewController *sipIncomingViewController;
@end

@implementation RootViewController

#pragma mark - properties

- (SIPCallingViewController *)sipCallingViewController {
    if (!_sipCallingViewController) {
        _sipCallingViewController = [[SIPCallingViewController alloc] initWithNibName:@"SIPCallingViewController" bundle:[NSBundle mainBundle]];
        _sipCallingViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    }
    return _sipCallingViewController;
}

- (SIPIncomingViewController *)sipIncomingViewController {
    if (!_sipIncomingViewController) {
        _sipIncomingViewController = [[SIPIncomingViewController alloc] initWithNibName:@"SIPIncomingViewController" bundle:[NSBundle mainBundle]];
        _sipIncomingViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return _sipIncomingViewController;
}

#pragma mark - Handle calls

- (void)handleSipCall:(GSCall *)sipCall {
    return [self.sipCallingViewController handleSipCall:sipCall];
}

@end
