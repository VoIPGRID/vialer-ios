//
//  SIPCallingViewController.h
//  Vialer
//
//  Created by Reinier Wieringa on 15/12/14.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NumberPadViewController.h"
#import "TrackedViewController.h"

NSString * const SIPCallStartedNotification;

@class GSCall;

@interface SIPCallingViewController : TrackedViewController<NumberPadViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UIView *buttonsView;
@property (strong, nonatomic) IBOutlet UIView *numbersButtonsView;
@property (strong, nonatomic) IBOutlet UIButton *hideButton;
@property (strong, nonatomic) IBOutlet UILabel *contactLabel;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;

- (void)handlePhoneNumber:(NSString *)phoneNumber forContact:(NSString *)contact;
- (void)handleSipCall:(GSCall *)sipCall;
- (IBAction)hangupButtonPressed:(UIButton *)sender;
- (IBAction)hideButtonPressed:(UIButton *)sender;

@end
