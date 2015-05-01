//
//  ForgotPasswordView.m
//  Vialer
//
//  Created by Karsten Westra on 30/04/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "ForgotPasswordView.h"

@implementation ForgotPasswordView

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect frame = (CGRect) {
        .origin = self.emailTextfield.frame.origin,
        .size = CGSizeMake(CGRectGetWidth(self.emailTextfield.frame), 44.f)
    };
    [self.emailTextfield setFrame:frame];
}

@end
