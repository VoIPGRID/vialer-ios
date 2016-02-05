//
//  SIPCallingViewController.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "SIPCallingViewController.h"

@interface SIPCallingViewController()
@property (weak, nonatomic) IBOutlet UILabel *phoneNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *callStatusLabel;
@property (strong, nonatomic) NSString *phoneNumber;
@end

@implementation SIPCallingViewController

- (void)handlePhoneNumber:(NSString *)phoneNumber {
    self.phoneNumber = phoneNumber;
}

- (void)setPhoneNumberLabel:(UILabel *)phoneNumberLabel {
    phoneNumberLabel.text = self.phoneNumber;
}

- (IBAction)endCallButtonPressed:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
