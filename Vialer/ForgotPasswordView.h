//
//  ForgotPasswordView.h
//  Vialer
//
//  Created by Karsten Westra on 30/04/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ForgotPasswordView : UIView

@property (nonatomic, weak) IBOutlet UITextField *emailTextfield;
@property (nonatomic, weak) IBOutlet UILabel* forgotPasswordLabel;
@property (nonatomic, weak) IBOutlet UILabel* pleaseEnterEmailLabel;
@property (nonatomic, weak) IBOutlet UIButton* requestPasswordButton;

// Keep track if the form is moved already
@property (nonatomic) BOOL isMoved;

@end
