//
//  SIPCallingViewController.h
//  Vialer
//
//  Created by Reinier Wieringa on 15/12/14.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SIPCallingViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIView *buttonsView;
@property (strong, nonatomic) IBOutlet UIButton *hangupButton;
@property (strong, nonatomic) IBOutlet UILabel *contactLabel;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;

- (void)handlePhoneNumber:(NSString *)phoneNumber forContact:(NSString *)contact;
- (IBAction)hangupButtonPressed:(UIButton *)sender;

@end
