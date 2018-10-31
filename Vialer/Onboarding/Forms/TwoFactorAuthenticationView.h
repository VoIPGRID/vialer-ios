//
//  TwoFactorAuthenticationView.h
//  Copyright © 2018 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Configuration.h"
#import "RoundedAndColoredUIButton.h"

IB_DESIGNABLE
@interface TwoFactorAuthenticationView : UIView

@property (nonatomic, weak) IBOutlet UILabel *twoFactorAuthenticationDescriptionField;
@property (nonatomic, weak) IBOutlet UITextField *tokenField;
@property (nonatomic, weak) IBOutlet RoundedAndColoredUIButton *continueButton;

- (void)setTextFieldDelegate:(id<UITextFieldDelegate>)delegate;

@end
