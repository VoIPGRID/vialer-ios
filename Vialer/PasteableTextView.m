//
//  PasteableTextView.m
//  Vialer
//
//  Created by Reinier Wieringa on 13/08/14.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "PasteableTextView.h"

@implementation PasteableTextView

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(paste:)) {
        return YES;
    }
    return [super canPerformAction:action withSender:sender];
}

@end
