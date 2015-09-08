//
//  NumberPadViewController.h
//  Vialer
//
//  Created by Reinier Wieringa on 9/1/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVAudioPlayer.h>

@protocol NumberPadViewControllerDelegate <NSObject>
@optional
- (void)numberPadPressedWithCharacter:(NSString *)character;
@end

@interface NumberPadViewController : UIViewController <AVAudioPlayerDelegate>

@property (nonatomic, assign) id <NumberPadViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL tonesEnabled;

- (void)playDtmfToneAtIndex:(NSUInteger)index;

@end
