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

@property (nonatomic, strong) IBOutlet ConfigTextField *emailField;
@property (nonatomic, strong) IBOutlet ConfigTextField *passwordField;

- (void)setTextFieldDelegate:(id<UITextFieldDelegate>)delegate;

@end
