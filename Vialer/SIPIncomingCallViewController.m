//
//  SIPIncomingCallViewController.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "SIPCallingViewController.h"
#import "SIPIncomingCallViewController.h"

static NSString * const SIPIncomingCallViewControllerShowSIPCallingStoryboard = @"ShowSIPCallingStoryboard";

@implementation SIPIncomingCallViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[SIPCallingViewController class]]) {
        SIPCallingViewController *sipCallingViewController = (SIPCallingViewController *)segue.destinationViewController;
//        [sipCallingViewController handleIncomingCallWithVSLCall:@"264"];
    }
}

- (IBAction)declineCallButtonPressed:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)acceptCallButtonPressed:(UIButton *)sender {
    [self performSegueWithIdentifier:SIPIncomingCallViewControllerShowSIPCallingStoryboard sender:nil];
}

- (void)didDismissSIPCallingViewController:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

@end
