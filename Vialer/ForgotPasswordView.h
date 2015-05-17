//
//  ForgotPasswordView.h
//  Vialer
//
//  Created by Karsten Westra on 30/04/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ForgotPasswordView : UIView

@property (nonatomic, strong) IBOutlet UITextField *emailTextfield;
@property (nonatomic, weak) IBOutlet UILabel* forgotPasswordLabel;
@property (nonatomic, weak) IBOutlet UILabel* pleaseEnterEmailLabel;

//Storing the frame's center in an ivar just to be able to restore is a bit of a hack
//but I could not think of a better way.
@property (nonatomic) CGPoint centerBeforeKeyboardAnimation;

@end
