//
//  NumberPadViewController.h
//  Vialer
//
//  Created by Reinier Wieringa on 9/1/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import <AVFoundation/AVAudioPlayer.h>
#import <UIKit/UIKit.h>

@protocol OldNumberPadViewControllerDelegate <NSObject>
@optional
- (void)numberPadPressedWithCharacter:(NSString *)character;
@end

@interface OldNumberPadViewController : UIViewController <AVAudioPlayerDelegate>

@property (nonatomic, assign) id <OldNumberPadViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL tonesEnabled;
@property (nonatomic, readonly) NSArray *titles;
@property (nonatomic, readonly) NSArray *subtitles;

- (void)playDtmfToneAtIndex:(NSUInteger)index;

@end
