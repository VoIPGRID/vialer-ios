//
//  ConfigureFormView.h
//  Vialer
//
//  Created by Karsten Westra on 21/04/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface ConfigureFormView : UIView

@property (nonatomic, weak) IBOutlet UILabel *phoneNumberDescriptionField;
@property (nonatomic, weak) IBOutlet UITextField *phoneNumberField;
@property (nonatomic, weak) IBOutlet UILabel *outgoingNumberDescriptionField;
@property (nonatomic, weak) IBOutlet UILabel *outgoingNumberLabel;
@property (nonatomic, weak) IBOutlet UIButton *continueButton;

// Keep track if the form is moved already
@property (nonatomic) BOOL isMoved;

- (void)setTextFieldDelegate:(id<UITextFieldDelegate>)delegate;

@end
