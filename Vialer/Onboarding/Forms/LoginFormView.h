//
//  LoginFormView.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Configuration.h"
#import "RoundedAndColoredUIButton.h"

IB_DESIGNABLE
@interface LoginFormView : UIView

@property (nonatomic, weak) IBOutlet UITextField *usernameField;
@property (nonatomic, weak) IBOutlet UITextField *passwordField;
@property (nonatomic, weak) IBOutlet RoundedAndColoredUIButton *loginButton;
@property (nonatomic, weak) IBOutlet RoundedAndColoredUIButton *forgotPasswordButton;
@property (nonatomic, weak) IBOutlet RoundedAndColoredUIButton *configurationInstructionsButton;

/* Dependency Injection */
@property (nonatomic) Configuration *configuration;

// Keep track if the form is moved already
@property (nonatomic) BOOL isMoved;


- (void)setTextFieldDelegate:(id<UITextFieldDelegate>)delegate;

@end
