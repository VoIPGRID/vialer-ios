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
    [self.phoneNumberField setTextFieldDelegate:delegate];
    [self.outgoingNumberField setTextFieldDelegate:delegate];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.titleLable.text = NSLocalizedString(@"Vialer is configuring", nil);
    self.subtitleLable.text = NSLocalizedString(@"your account", nil);
    
    [self.phoneNumberField setupPlaceHolder:NSLocalizedString(@"phonenumber", nil) labelText:NSLocalizedString(@"mobile_label", nil)];
    [self.outgoingNumberField setupPlaceHolder:NSLocalizedString(@"Automatically fetched", nil) labelText:NSLocalizedString(@"Outgoing", nil)];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    /* Remove all the default UITextField styling */
    [self.phoneNumberField cleanStyle];     // Remove the default styling of a UITextField.
    [self.outgoingNumberField cleanStyle];

//    [self.outgoingNumberField setUserInteractionEnabled:NO]; // Disable the outgoing field. we will fill it with profile data later!

    [self.phoneNumberField styleWithTopBorderRadius:8.f];          /* Add top rounded corner mask */
    [self.outgoingNumberField styleWithBottomBorderRadius:8.f];    /* Add bottom corner mask */
}

@end
