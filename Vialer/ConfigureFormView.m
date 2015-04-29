//
//  ConfigureFormView.m
//  Vialer
//
//  Created by Karsten Westra on 21/04/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "ConfigureFormView.h"
#import "UIView+RoundedStyle.h"

@implementation ConfigureFormView

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupView];
        [self setupConstraints];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
        [self setupConstraints];
    }
    return self;
}

- (void)setTextFieldDelegate:(id<UITextFieldDelegate>)delegate {
    [self.phoneNumberField setTextFieldDelegate:delegate];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    /* Remove all the default UITextField styling */
    [self.phoneNumberField cleanStyle];     // Remove the default styling of a UITextField.
    [self.outgoingNumberField cleanStyle];
    [self.outgoingNumberField setUserInteractionEnabled:NO]; // Disable the outgoing field. we will fill it with profile data later!

    [self.phoneNumberField styleWithTopBorderRadius:8.f];          /* Add top rounded corner mask */
    [self.outgoingNumberField styleWithBottomBorderRadius:8.f];    /* Add bottom corner mask */
    
    [self.phoneNumberField setupPlaceHolder:@"required" labelText:@"Mobile"];
    [self.outgoingNumberField setupPlaceHolder:@"Automatically fetched" labelText:@"Outgoing"];
}

- (void)setupView {
    /**
     * TODO: setup form!
     */
}

- (void)setupConstraints {
    /**
     * TODO: constraints
     */
}

@end
