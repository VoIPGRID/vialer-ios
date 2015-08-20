//
//  ConfigureFormView.m
//  Vialer
//
//  Created by Karsten Westra on 21/04/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "ConfigureFormView.h"
#import "UIView+RoundedStyle.h"

@interface ConfigureFormView ()
//Displays: Vialer is configuring Outlet needed for localization
@property (nonatomic, weak) IBOutlet UILabel *titleLable;
//Displays: Your account Outlet needed for localization
@property (nonatomic, weak) IBOutlet UILabel *subtitleLable;
@end

@implementation ConfigureFormView

- (void)setTextFieldDelegate:(id<UITextFieldDelegate>)delegate {
    self.phoneNumberField.delegate = delegate;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.titleLable.text = NSLocalizedString(@"Vialer is configuring", nil);
    self.subtitleLable.text = NSLocalizedString(@"your account", nil);
    
    self.phoneNumberDescriptionField.text = NSLocalizedString(@"CONFIGURE_PHONENUMBER_DESCRIPTION_TEXT", nil);
    self.phoneNumberField.placeholder = NSLocalizedString(@"mobile_label", nil);
    [self.phoneNumberField setClearButtonMode:UITextFieldViewModeWhileEditing];
    
    self.outgoingNumberDescriptionField.text = NSLocalizedString(@"CONFIGURE_OUTGOING_DESCRIPTION_TEXT", nil);
    
    [self.continueButton setTitle:NSLocalizedString(@"Continue", nil) forState:UIControlStateNormal];
}

@end
