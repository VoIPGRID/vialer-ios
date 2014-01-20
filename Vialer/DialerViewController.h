//
//  DialerViewController.h
//  Vialer
//
//  Created by Reinier Wieringa on 15/11/13.
//  Copyright (c) 2013 Voys. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DialerViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *buttonsView;
@property (weak, nonatomic) IBOutlet UIButton *callButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UITextField *numberTextField;

- (IBAction)dialerBackButtonPressed:(UIButton *)sender;
- (IBAction)callButtonPressed:(UIButton *)sender;
@end