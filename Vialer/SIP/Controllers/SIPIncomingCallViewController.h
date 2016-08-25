//
//  SIPIncomingCallViewController.h
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <VialerSIPLib/VialerSIPLib.h>

@interface SIPIncomingCallViewController : UIViewController

/**
 *  The VSLCall object that is coming in with the push notification.
 */
@property (strong, nonatomic) VSLCall * _Nonnull call;

/**
 *  This method will be called by the decline button and will pop this viewcontroller.
 *
 *  @param sender UIButton instance that is pressed.
 */
- (IBAction)declineCallButtonPressed:(UIButton * _Nonnull)sender;

/**
 *  This method will be called by the accept button and will segue to the sip calling storyboard.
 *
 *  @param sender UIButton instance that is pressed.
 */
- (IBAction)acceptCallButtonPressed:(UIButton * _Nonnull)sender;
@end
