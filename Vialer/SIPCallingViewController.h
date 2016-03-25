//
//  SIPCallingViewController.h
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SipCallingButtonsViewController.h"
#import <UIKit/UIKit.h>
#import "VialerSIPLib-iOS/VialerSIPLib.h"

@interface SIPCallingViewController : UIViewController <SipCallingButtonsViewControllerDelegate>

/**
 *  The end of call button.
 */
@property (weak, nonatomic) IBOutlet UIButton * _Nullable endCallButton;

/**
 *  The button for hiding the numberpad.
 */
@property (weak, nonatomic) IBOutlet UIButton * _Nullable hideButton;

/**
 *  This will setup a SIP call with the provided phonenumber.
 *
 *  @param phoneNumber the phonenumber to be displayed in the UI.
 */
- (void)handleOutgoingCallWithPhoneNumber:(NSString * _Nonnull)phoneNumber;

/**
 *  This will setup a incoming SIP call with the provided VSLCall object.
 *
 *  @param call VSLCall object.
 */
- (void)handleIncomingCallWithVSLCall:(VSLCall * _Nonnull)call;

/**
 *  This method will try to end the current active call.
 *
 *  @param sender UIButton instance
 */
- (IBAction)endCallButtonPressed:(UIButton * _Nonnull)sender;

/**
 *  This method will ask the embedded keypad to hide.
 *
 *  @param sender UIButton instance.
 */
- (IBAction)hideNumberpad:(UIButton * _Nullable)sender;

@end
