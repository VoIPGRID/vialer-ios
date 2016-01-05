//
//  NumberPadViewController.m
//  Vialer
//
//  Created by Reinier Wieringa on 9/1/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "OldNumberPadViewController.h"

#import "ConnectionHandler.h"

#import "AFNetworkReachabilityManager.h"

@interface OldNumberPadViewController ()
@property (nonatomic, strong) NSArray *sounds;
@property (nonatomic, strong) NSMutableArray *soundsPlayers;
@property (nonatomic, strong) NSArray *titles;
@property (nonatomic, strong) NSArray *subtitles;

@end

@implementation OldNumberPadViewController

- (void)loadView {
    [super loadView];
    [self addDialerButtonsToView:self.view];
}

# pragma mark - properties

- (NSArray *)titles {
    if (!_titles) {
        _titles = @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"", @"0", @""];
    }
    return _titles;
}

- (NSArray *)subtitles {
    if (!_subtitles) {
        _subtitles = @[@"", @"ABC", @"DEF", @"GHI", @"JKL", @"MNO", @"PQRS", @"TUV", @"WXYZ", @"*", @"+", @"#"];
    }
    return _subtitles;
}

- (NSArray *)sounds {
    if (!_sounds) {
        NSMutableArray *sounds = [NSMutableArray array];
        for (NSString *sound in @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"s", @"0", @"#"]) {
            NSString *dtmfFile = [NSString stringWithFormat:@"dtmf-%@", sound];
            NSURL *dtmfUrl = [[NSBundle mainBundle] URLForResource:dtmfFile withExtension:@"aif" ];
            if (dtmfUrl) {
                [sounds addObject:dtmfUrl];
            } else {
                NSLog(@"Error loading sound at path: %@", dtmfFile);
                // Add a null object to correct array alignment
                [sounds addObject:[[NSURL alloc] init]];
            }
        }
        _sounds = [sounds copy];
    }
    return _sounds;
}

- (NSMutableArray *)soundsPlayers {
    if (!_soundsPlayers) {
        _soundsPlayers = [NSMutableArray array];
    }
    return _soundsPlayers;
}

#pragma mark - Setup view

- (void)addDialerButtonsToView:(UIView *)view {
    CGFloat buttonWidth = self.view.frame.size.width / 3.4f;
    CGFloat leftOffset = (self.view.frame.size.width - (3.f * buttonWidth)) / 2.f;

    // Calculate height based on the remaining size on the screen
    // - statusBarHeight - navBarHeight - tabBarHeight - numberFieldHeight - callButtonHeight
    CGFloat buttonHeight = (self.view.frame.size.height - 20 - 44.f - 49.f - 53.f - 16.f - 55.f - 24.f) / 4.f;

    CGPoint offset = CGPointMake(0, 0);

    for (int j = 0; j < 4; j++) {
        offset.x = leftOffset;
        for (int i = 0; i < 3; i++) {
            NSString *title = self.titles[j * 3 + i];
            NSString *subtitle = self.subtitles[j * 3 + i];
            UIButton *button = [self createDialerButtonWithTitle:title andSubtitle:subtitle constrainedToSize:CGSizeMake(buttonWidth, buttonHeight)];
            [button addTarget:self action:@selector(dialerButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            button.tag = j * 3 + i;

            [button sizeToFit];
            button.frame = CGRectMake(offset.x, offset.y, buttonWidth, buttonHeight);
            [view addSubview:button];

            if ([title isEqualToString:@"0"]) {
                UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
                [button addGestureRecognizer:longPress];
            }

            offset.x += buttonWidth;
        }

        offset.y += buttonHeight;
    }
}

- (UIButton *)createDialerButtonWithTitle:(NSString *)title
                              andSubtitle:(NSString *)subTitle
                        constrainedToSize:(CGSize)size
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[self stateImageForState:UIControlStateNormal
                                     andTitle:title
                                  andSubTitle:subTitle
                            constrainedToSize:size]
            forState:UIControlStateNormal];
    [button setImage:[self stateImageForState:UIControlStateHighlighted
                                     andTitle:title
                                  andSubTitle:subTitle
                            constrainedToSize:size]
            forState:UIControlStateHighlighted];
    button.frame = CGRectMake(0, 0, size.width, size.height);
    return button;
}

- (UIImage *)stateImageForState:(UIControlState)state
                       andTitle:(NSString *)title
                    andSubTitle:(NSString *)subTitle
              constrainedToSize:(CGSize)size
{
    UIView *buttonGraphic = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:32.f];
    titleLabel.textColor = state == UIControlStateHighlighted ? [UIColor colorWithRed:0xed green:0xed blue:0xed alpha:0.4f] : [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.text = title;
    [titleLabel sizeToFit];

    UILabel *subTitleLabel = [[UILabel alloc] init];
    subTitleLabel.backgroundColor = [UIColor clearColor];
    subTitleLabel.textColor = state == UIControlStateHighlighted ? [UIColor colorWithRed:0xed green:0xed blue:0xed alpha:0.4f] : [UIColor colorWithRed:0xed green:0xed blue:0xed alpha:1.f];
    subTitleLabel.textAlignment = NSTextAlignmentCenter;

    if (title.length > 0) {
        if (subTitle.length > 1) {
            subTitleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:9.f];
        } else {
            subTitleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:16.f];
        }
    } else {
        subTitleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:32.f];
    }

    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:subTitle];
    [attributedString addAttribute:NSKernAttributeName
                             value:@(5.f)
                             range:NSMakeRange(0, subTitle.length)];

    subTitleLabel.attributedText = attributedString;
    [subTitleLabel sizeToFit];

    CGFloat yOffset = 10.f;
    if ([UIScreen mainScreen].bounds.size.height < 568.f) {
        yOffset = 0;
    }

    if (title.length) {
        titleLabel.frame = CGRectMake(0.f, yOffset, size.width, titleLabel.frame.size.height);

        CGFloat yPadding = (subTitle.length > 1) ? 2.f : -4.f;
        subTitleLabel.frame = CGRectMake(0.f, titleLabel.frame.origin.y + titleLabel.frame.size.height + yPadding, size.width, subTitleLabel.frame.size.height);
    } else {
        subTitleLabel.frame = CGRectMake(0.f, yOffset, size.width, subTitleLabel.frame.size.height);
    }

    [buttonGraphic addSubview:titleLabel];
    [buttonGraphic addSubview:subTitleLabel];

    CGRect rect = [buttonGraphic bounds];
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [buttonGraphic.layer renderInContext:context];
    UIImage *capturedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return capturedImage;
}

#pragma mark - Actions

- (void)longPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self playDtmfToneAtIndex:gesture.view.tag];

        if ([self.delegate respondsToSelector:@selector(numberPadPressedWithCharacter:)]) {
            [self.delegate numberPadPressedWithCharacter:@"+"];
        }
    }
}

- (void)dialerButtonPressed:(UIButton *)sender {
    [self playDtmfToneAtIndex:sender.tag];

    if ([self.delegate respondsToSelector:@selector(numberPadPressedWithCharacter:)]) {
        NSString *cipher = [self.titles objectAtIndex:sender.tag];
        if (cipher.length) {
            [self.delegate numberPadPressedWithCharacter:cipher];
        } else {
            NSString *character = [self.subtitles objectAtIndex:sender.tag];
            if (character.length) {
                [self.delegate numberPadPressedWithCharacter:character];
            }
        }
    }
}

- (void)playDtmfToneAtIndex:(NSUInteger)index {
    if (self.tonesEnabled &&
        self.sounds.count > index) {
        NSURL *url = [self.sounds objectAtIndex:index];
        // Create a player for each play, to allow simultanious and fast input
        AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
        if (player) {
            // Keep reference to the player object, and destroy it in the delegate methods
            [self.soundsPlayers addObject:player];
            player.delegate = self;
            [player play];
        }
    }
}

#pragma mark - Handle the AVAudioPlayers and free the instances

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    // Finished playing, so destroy the player object
    if ([self.soundsPlayers containsObject:player]) {
        [self.soundsPlayers removeObject:player];
    }
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    // Failed playing, but destroy the player object anyway
    if ([self.soundsPlayers containsObject:player]) {
        [self.soundsPlayers removeObject:player];
    }
}

@end
