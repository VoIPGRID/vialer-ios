//
//  TwoStepCallingViewController.h
//  Vialer
//
//  Created by Bob Voorneveld on 19/10/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TwoStepCallingViewController : UIViewController

/**
 Setup TwoStep call and present view.

 @param phoneNumber The phoneNumber that should be called.
 @param contact The name of the contact that is called. Currently not in use.
*/
- (void)handlePhoneNumber:(NSString *)phoneNumber forContact:(NSString *)contact;

@end
