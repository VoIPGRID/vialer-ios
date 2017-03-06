//
//  ForgotPasswordView.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Configuration.h"
#import "RoundedAndColoredUIButton.h"

@interface ForgotPasswordView : UIView

@property (nonatomic, weak) IBOutlet UITextField *emailTextfield;
@property (nonatomic, weak) IBOutlet UILabel *forgotPasswordLabel;
@property (nonatomic, weak) IBOutlet UILabel *pleaseEnterEmailLabel;
@property (nonatomic, weak) IBOutlet RoundedAndColoredUIButton *requestPasswordButton;

/* Dependency Injection */
@property (nonatomic) Configuration *configuration;

// Keep track if the form is moved already
@property (nonatomic) BOOL isMoved;

@end
