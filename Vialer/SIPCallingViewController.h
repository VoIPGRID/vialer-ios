//
//  SIPCallingViewController.h
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <VialerSIPLib-iOS/VialerSIPLib.h>


@interface SIPCallingViewController : UIViewController

/**
 *  The end of call button.
 */
@property (weak, nonatomic) IBOutlet UIButton *endCallButton;

/**
 *  This will setup a SIP call with the provided phonenumber.
 *
 *  @param phoneNumber the phonenumber to be displayed in the UI.
 */
- (void)handleOutgoingCallWithPhoneNumber:(NSString * _Nonnull)phoneNumber;

/**
 *  This method will try to end the current active call.
 *
 *  @param sender UIButton instance.
 */
- (IBAction)endCallButtonPressed:(UIButton * _Nonnull)sender;

@end
