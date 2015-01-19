//
//  SIPCallingViewController.h
//  Vialer
//
//  Created by Reinier Wieringa on 15/12/14.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NumberPadViewController.h"

NSString * const OutgoingSIPCallNotification;

@interface SIPCallingViewController : UIViewController<NumberPadViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UIView *buttonsView;
@property (strong, nonatomic) IBOutlet UIView *numbersButtonsView;
@property (strong, nonatomic) IBOutlet UIButton *hangupButton;
@property (strong, nonatomic) IBOutlet UIButton *hideButton;
@property (strong, nonatomic) IBOutlet UILabel *contactLabel;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;

- (void)handlePhoneNumber:(NSString *)phoneNumber forContact:(NSString *)contact;
- (IBAction)hangupButtonPressed:(UIButton *)sender;
- (IBAction)hideButtonPressed:(UIButton *)sender;

@end
