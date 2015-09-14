//
//  CallingViewController.h
//  Vialer
//
//  Created by Reinier Wieringa on 05/12/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoundedLabel.h"
#import "TrackedViewController.h"

@interface CallingViewController : TrackedViewController<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UILabel *contactLabel;
@property (weak, nonatomic) IBOutlet RoundedLabel *infoLabel;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UIImageView *infoImageView;

- (void)handlePhoneNumber:(NSString *)phoneNumber forContact:(NSString *)contact;

@end
