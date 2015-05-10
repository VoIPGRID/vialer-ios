//
//  PasteableTextView.m
//  Vialer
//
//  Created by Reinier Wieringa on 13/08/14.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "PasteableTextView.h"

@interface PasteableTextView ()
@property (nonatomic, strong) UILabel *label;
@end

@implementation PasteableTextView

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.textColor = self.backgroundColor = [UIColor clearColor];

        // Add label for shrinking purposes
        self.label = [[UILabel alloc] initWithCoder:aDecoder];
        self.label.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:36.f];
        self.label.backgroundColor = [UIColor clearColor];
        self.label.textColor = [UIColor whiteColor];
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.minimumScaleFactor = 0.5f;
        self.label.numberOfLines = 0;
        self.label.adjustsFontSizeToFitWidth = YES;
        self.label.userInteractionEnabled = NO;
        [self addSubview:self.label];
    }
    return self;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(paste:)) {
        return YES;
    }
    return [super canPerformAction:action withSender:sender];
}

- (void)setText:(NSString *)text {
    [super setText:text];
    self.label.text = text;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.label.text = self.text;
    self.label.frame = self.bounds;
}

@end
