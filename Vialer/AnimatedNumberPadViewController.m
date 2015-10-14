//
//  AnimatedNumberPadViewController.m
//  Vialer
//
//  Created by Reinier Wieringa on 4/23/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "AnimatedNumberPadViewController.h"

#import <AudioToolbox/AudioServices.h>

@implementation AnimatedNumberPadViewController

- (void)addDialerButtonsToView:(UIView *)view {
    CGFloat buttonWidth = self.view.frame.size.width / 3.4f;
    CGFloat leftOffset = (self.view.frame.size.width - (3.f * buttonWidth)) / 2.f;
    CGFloat buttonHeight = (self.view.frame.size.height - 20 - 44.f - 49.f - 53.f - 16.f - 55.f - 24.f) / 4.f;
    CGPoint offset = CGPointMake(0, 0);

    for (int j = 0; j < 4; j++) {
        offset.x = leftOffset;
        for (int i = 0; i < 3; i++) {
            NSString *title = self.titles[j * 3 + i];
            NSString *subtitle = self.subtitles[j * 3 + i];
            UIView *buttonView = [self createDialerButtonViewWithTitle:title
                                                           andSubTitle:subtitle
                                                                   tag:j * 3 + i
                                                     constrainedToSize:CGSizeMake(buttonWidth, buttonHeight)];
            buttonView.frame = CGRectMake(offset.x, offset.y, buttonWidth, buttonHeight);
            [view addSubview:buttonView];

            if ([title isEqualToString:@"0"]) {
                UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
                [buttonView addGestureRecognizer:longPress];
            }

            offset.x += buttonWidth;
        }

        offset.y += buttonHeight;
    }
}

- (UIView *)createDialerButtonViewWithTitle:(NSString *)title
                                andSubTitle:(NSString *)subtitle
                                        tag:(int)tag
                          constrainedToSize:(CGSize)size
{
    // Create number button
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:32.f];
    button.tintColor = [UIColor whiteColor];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.textColor = [UIColor whiteColor];
    button.frame = CGRectMake(0, 0, size.width, size.height);
    button.tag = tag;

    [button addTarget:self
               action:@selector(buttonTitleTouchDown:)
     forControlEvents:UIControlEventTouchDown];
    [button addTarget:self
               action:@selector(buttonTitleTouchUp:)
     forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];

    if ([UIScreen mainScreen].bounds.size.height < 568.f) {
        button.titleEdgeInsets = UIEdgeInsetsMake(-6.f, 0, 0, 0);
    }

    // Create subtitle label
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, size.height - 14.f, size.width, 14.f)];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];

    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:subtitle];
    [attributedString addAttribute:NSKernAttributeName
                             value:@(5.f)
                             range:NSMakeRange(0, subtitle.length)];
    label.attributedText = attributedString;

    if (title.length > 0) {
        if (subtitle.length > 1) {
            label.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:9.f];
        } else {
            label.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:16.f];
        }
    } else {
        [button setTitle:subtitle forState:UIControlStateNormal];
        label.attributedText = nil;
    }

    if ([UIScreen mainScreen].bounds.size.height >= 568.f) {
        label.frame = CGRectMake(0, size.height - 24.f, size.width, 24.f);
    }

    // Place to one parent controller
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    [container addSubview:button];
    [container addSubview:label];

    return container;
}

- (void)buttonPressedWithTag:(int)tag {
    [self playDtmfToneAtIndex:tag];

    if ([self.delegate respondsToSelector:@selector(numberPadPressedWithCharacter:)]) {
        NSString *cipher = [self.titles objectAtIndex:tag];
        if (cipher.length) {
            [self.delegate numberPadPressedWithCharacter:cipher];
        } else {
            NSString *character = [self.subtitles objectAtIndex:tag];
            if (character.length) {
                [self.delegate numberPadPressedWithCharacter:character];
            }
        }
    }
}

#pragma mark - Actions

- (void)buttonTitleTouchDown:(UIButton *)sender {
    [UIView animateWithDuration:0.1
                          delay:0.0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         sender.transform = CGAffineTransformMakeScale(1.5f, 1.5f);
                     } completion:nil];
    [self buttonPressedWithTag:(int)sender.tag];
}

- (void)buttonTitleTouchUp:(UIButton *)sender {
    [UIView animateWithDuration:0.1
                          delay:0.0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         sender.transform = CGAffineTransformMakeScale(1.f, 1.f);
                     } completion:nil];
}

- (void)longPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        if ([self.delegate respondsToSelector:@selector(numberPadPressedWithCharacter:)]) {
            [self.delegate numberPadPressedWithCharacter:@"+"];

            id button = [gesture.view.subviews firstObject];
            if (button && [button isKindOfClass:[UIButton class]]) {
                [self buttonTitleTouchUp:button];
            }
        }
    }
}

@end
