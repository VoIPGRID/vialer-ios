//
//  PasteableUILabel.m
//  Vialer
//
//  Created by Bob Voorneveld on 03/11/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "PasteableUILabel.h"

@implementation PasteableUILabel

#pragma mark - view lifecycle

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupLongPress];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupLongPress];
    }
    return self;
}

#pragma mark - UILongPressGestureRecognizer

- (void)setupLongPress {
    UIGestureRecognizer *tap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self addGestureRecognizer:tap];
}

- (void)handleLongPress:(UIGestureRecognizer *)recognizer {
    [self becomeFirstResponder];
    UIMenuController *menu = [UIMenuController sharedMenuController];
    [menu setTargetRect:self.frame inView:self.superview];
    [menu setMenuVisible:YES animated:YES];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

#pragma mark - paste

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(paste:)) {
        return YES;
    }
    return [super canPerformAction:action withSender:sender];
}

- (void)paste:(id)sender {
    NSString *pastedText = [UIPasteboard generalPasteboard].string;
    [self.delegate pasteableUILabel:self didReceivePastedText:pastedText];
}

@end
