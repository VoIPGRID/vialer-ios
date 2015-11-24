//
//  SIPIncomingViewController.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
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
