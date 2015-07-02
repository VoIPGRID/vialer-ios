//
//  ConfigTextField.h
//  Vialer
//
//  Created by Karsten Westra on 23/04/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface ConfigTextField : UIView

- (void)setupPlaceHolder:(NSString*)placeholder labelText:(NSString*)text;
- (void)setSecureTextEntry:(BOOL)useSecure;
- (void)setTextFieldDelegate:(id<UITextFieldDelegate>)delegate;

- (NSString*)text;
- (void)setText:(NSString*)text;

- (BOOL)isSelectedField:(UITextField*)field;

- (void)becomeFirstResponder;
- (void)resignFirstResponder;

- (void)setKeyboardType:(UIKeyboardType)type;
- (void)setReturnKeyType:(UIReturnKeyType)type;
- (void)setClearButtonMode:(UITextFieldViewMode)clearButtonMode;

@end
