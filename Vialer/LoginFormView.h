//
//  LoginFormView.h
//  Vialer
//
//  Created by Karsten Westra on 20/04/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ConfigTextField.h"

IB_DESIGNABLE
@interface LoginFormView : UIView

@property (nonatomic, weak) IBOutlet UITextField *usernameField;
@property (nonatomic, weak) IBOutlet UITextField *passwordField;
@property (nonatomic, weak) IBOutlet UIButton *loginButton;

//Storing the frame's center in an ivar just to be able to restore is a bit of a hack
//but I could not think of a better way.
@property (nonatomic) CGPoint centerBeforeKeyboardAnimation;

- (void)setTextFieldDelegate:(id<UITextFieldDelegate>)delegate;

@end
