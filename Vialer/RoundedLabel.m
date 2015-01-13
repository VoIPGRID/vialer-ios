//
//  RoundedLabel.m
//  Vialer
//
//  Created by Reinier Wieringa on 13/01/15.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "RoundedLabel.h"

@implementation RoundedLabel

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.layer.cornerRadius = 12.f;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:UIEdgeInsetsInsetRect(frame, UIEdgeInsetsMake(0.f, 0.f, 0.f, -6.f))];
    if (self) {
        self.layer.cornerRadius = 12.f;
    }
    return self;
}

- (void)sizeToFit {
    [super sizeToFit];
    
    self.frame = UIEdgeInsetsInsetRect(self.frame, UIEdgeInsetsMake(0.f, 0.f, 0.f, -6.f));
}

- (void)drawTextInRect:(CGRect)rect {
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, UIEdgeInsetsMake(0.f, 3.f, 0.f, 3.f))];
}

@end
