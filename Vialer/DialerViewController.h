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

@property (strong, nonatomic) IBOutlet UILabel *statusLabel;

- (IBAction)dialerBackButtonPressed:(UIButton *)sender;
- (IBAction)callButtonPressed:(UIButton *)sender;

@end
