//
//  ConfigTextField.m
//  Vialer
//
//  Created by Karsten Westra on 23/04/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "ConfigTextField.h"
#import "UIView+RoundedStyle.h"

@implementation ConfigTextField {
    UILabel *_label;
    UITextField *_field;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {

    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

    }
    return self;
}

- (void)setupPlaceHolder:(NSString*)placeholder labelText:(NSString*)text {
    [self setupView:placeholder text:text];
    [self setupConstraints];
    [self.layer setBorderColor:[UIColor colorWithRed:219.f / 255.f green:219.f / 255.f blue:221.f / 255.f alpha:1.f].CGColor];
    [self.layer setBorderWidth:0.5f];
}

- (void)setupView:(NSString*)placeholder text:(NSString*)text {

    if (!_label) {
        _label = [UILabel new];
        [_label setTranslatesAutoresizingMaskIntoConstraints:NO];
    }
    [_label setText:text];
    [self addSubview:_label];

    if (!_field) {
        _field = [UITextField new];
        [_field  setTranslatesAutoresizingMaskIntoConstraints:NO];
    }
    [_field setPlaceholder:placeholder];
    [self addSubview:_field];
}

- (void)setupConstraints {
    NSDictionary *views = @{
        @"superview": self,
        @"label": _label,
        @"textField": _field
    };

    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(16)-[label(==80)]-[textField]|"
                                                                  options:0
                                                                  metrics:nil
                                                                    views:views];
    [self addConstraints:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[label(==superview)]"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:views];
    [self addConstraints:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[textField(==superview)]"
                                                          options:0
                                                          metrics:nil
                                                            views:views];
    [self addConstraints:constraints];
}

@end
