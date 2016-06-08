//
//  NumberPadViewController.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NumberPadViewControllerDelegate <NSObject>
@optional
- (void)numberPadPressedWithCharacter:(NSString *)character;
@end

@interface NumberPadViewController : UIViewController
@property (nonatomic, weak) id<NumberPadViewControllerDelegate> delegate;
@end
