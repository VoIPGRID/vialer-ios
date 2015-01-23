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
#import "AppDelegate.h"

#import "UIAlertView+Blocks.h"

#import <AVFoundation/AVAudioSession.h>
#import <AddressBook/AddressBook.h>

#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>

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

    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);

    CGFloat buttonXSpace = self.view.frame.size.width / 3.4f;
    CGFloat leftOffset = (self.view.frame.size.width - (3.f * buttonXSpace)) / 2.f;
    self.contactLabel.frame = CGRectMake(leftOffset, self.contactLabel.frame.origin.y, self.view.frame.size.width - (leftOffset * 2.f), self.contactLabel.frame.size.height);
    self.statusLabel.frame = CGRectMake(leftOffset, self.statusLabel.frame.origin.y, self.view.frame.size.width - (leftOffset * 2.f), self.statusLabel.frame.size.height);

    [self.acceptButton setTitle:NSLocalizedString(@"accept", nil) forState:UIControlStateNormal];
    [self.declineButton setTitle:NSLocalizedString(@"decline", nil) forState:UIControlStateNormal];

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

    self.contactLabel.text = self.incomingCall.remoteInfo;
    self.statusLabel.text = NSLocalizedString(@"Mobile", nil);
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)incomingSIPCallNotification:(NSNotification *)notification {
    self.incomingCall = notification.object;
    if (self.incomingCall) {
        UIViewController *presentedViewController = [[[[UIApplication sharedApplication] delegate] window].rootViewController presentedViewController];
        if (presentedViewController) {
            [presentedViewController presentViewController:self animated:YES completion:nil];
        } else {
            [[[[UIApplication sharedApplication] delegate] window].rootViewController presentViewController:self animated:YES completion:nil];
        }
    }
}

- (IBAction)acceptButtonPressed:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    AppDelegate *appDelegate = ((AppDelegate *)[UIApplication sharedApplication].delegate);
    [appDelegate handleSipCall:self.incomingCall];
}

- (IBAction)declineButtonPressed:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.incomingCall end];
}

@end
