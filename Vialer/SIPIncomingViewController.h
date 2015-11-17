//
//  SIPIncomingViewController.h
//  Vialer
//
//  Created by Reinier Wieringa on 19/01/15.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SIPIncomingViewController : UIViewController
@property (strong, nonatomic) IBOutlet UILabel *contactLabel;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UIButton *acceptButton;
@property (strong, nonatomic) IBOutlet UIButton *declineButton;

- (IBAction)acceptButtonPressed:(UIButton *)sender;
- (IBAction)declineButtonPressed:(UIButton *)sender;
@end
