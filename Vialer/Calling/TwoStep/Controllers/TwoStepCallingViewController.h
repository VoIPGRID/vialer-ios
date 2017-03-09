//
//  TwoStepCallingViewController.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TwoStepCallingViewController : UIViewController

/**
 Setup TwoStep call and present view.

 @param phoneNumber The phoneNumber that should be called.
 @param contact The name of the contact that is called. Currently not in use.
*/
- (void)handlePhoneNumber:(NSString *)phoneNumber;

@end
