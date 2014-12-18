//
//  PJSIPTestViewController.h
//  Vialer
//
//  Created by Reinier Wieringa on 20/11/14.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Gossip.h"

@interface PJSIPTestViewController : UIViewController<GSAccountDelegate>
- (IBAction)connectButtonPressed:(UIButton *)sender;
- (IBAction)callButtonPressed:(UIButton *)sender;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UIButton *connectButton;
@property (strong, nonatomic) IBOutlet UIButton *callButton;
@end
