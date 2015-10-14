//
//  NumberPadViewController.h
//  Vialer
//
//  Created by Reinier Wieringa on 9/1/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import <AVFoundation/AVAudioPlayer.h>
#import <UIKit/UIKit.h>

@protocol NumberPadViewControllerDelegate <NSObject>
@optional
- (void)numberPadPressedWithCharacter:(NSString *)character;
@end

@interface NumberPadViewController : UIViewController <AVAudioPlayerDelegate>

@property (nonatomic, assign) id <NumberPadViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL tonesEnabled;
@property (nonatomic, readonly) NSArray *titles;
@property (nonatomic, readonly) NSArray *subtitles;

- (void)playDtmfToneAtIndex:(NSUInteger)index;

@end
