//
//  SipCallingButtonViewController.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SipCallingButtonViewControllerDelegate <NSObject>
- (void)pauseButtonPressed:(BOOL)pause;
- (void)soundOffButtonPressed:(BOOL)mute;
- (void)speakerButtonPressed:(BOOL)speaker;
@end

@interface SipCallingButtonViewController : UIViewController
@property (weak, nonatomic) id<SipCallingButtonViewControllerDelegate> delegate;
@end
