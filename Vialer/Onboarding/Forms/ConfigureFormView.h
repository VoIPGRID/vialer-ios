//
//  ConfigureFormView.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoundedAndColoredUIButton.h"

IB_DESIGNABLE
@interface ConfigureFormView : UIView

@property (nonatomic, weak) IBOutlet UILabel *phoneNumberDescriptionField;
@property (nonatomic, weak) IBOutlet UITextField *phoneNumberField;
@property (nonatomic, weak) IBOutlet UILabel *outgoingNumberDescriptionField;
@property (nonatomic, weak) IBOutlet UILabel *outgoingNumberLabel;
@property (nonatomic, weak) IBOutlet RoundedAndColoredUIButton *continueButton;

// Keep track if the form is moved already
@property (nonatomic) BOOL isMoved;

- (void)setTextFieldDelegate:(id<UITextFieldDelegate>)delegate;

@end
