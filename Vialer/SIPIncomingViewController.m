//
//  SIPIncomingViewController.m
//  Vialer
//
//  Created by Reinier Wieringa on 19/01/15.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "SIPIncomingViewController.h"
#import "ConnectionHandler.h"
#import "Gossip+Extra.h"

#import "UIAlertView+Blocks.h"

#import <AVFoundation/AVAudioSession.h>
#import <AddressBook/AddressBook.h>

#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>

@interface SIPIncomingViewController ()
@end

@implementation SIPIncomingViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

@end
