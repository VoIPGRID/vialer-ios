//
//  LoginFormView.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface LoginFormView : UIView

@property (nonatomic, weak) IBOutlet UITextField *usernameField;
@property (nonatomic, weak) IBOutlet UITextField *passwordField;

// Keep track if the form is moved already
@property (nonatomic) BOOL isMoved;


- (void)setTextFieldDelegate:(id<UITextFieldDelegate>)delegate;

@end
