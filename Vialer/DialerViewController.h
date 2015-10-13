//
//  DialerViewController.h
//  Vialer
//
//  Created by Reinier Wieringa on 15/11/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NumberPadViewController.h"
#import "TrackedViewController.h"
#import "PasteableTextView.h"

@interface DialerViewController : TrackedViewController<UITextViewDelegate, NumberPadViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *buttonsView;
@property (weak, nonatomic) IBOutlet UIButton *callButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet PasteableTextView *numberTextView;

@property (weak, nonatomic) IBOutlet UIView  *statusView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIButton *statusButton;
@property (strong, nonatomic) NSString *infoMessage;

- (IBAction)dialerBackButtonPressed:(UIButton *)sender;
- (IBAction)callButtonPressed:(UIButton *)sender;
- (IBAction)messageInfoPressed:(UIButton *)sender;
@end
