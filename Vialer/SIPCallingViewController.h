//
//  SIPCallingViewController.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OldNumberPadViewController.h"

NSString * const SIPCallStartedNotification;

@class GSCall;

@interface SIPCallingViewController : UIViewController <OldNumberPadViewControllerDelegate>

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
