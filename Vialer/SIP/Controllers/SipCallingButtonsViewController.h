//
//  SipCallingButtonsViewController.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "NumberPadViewController.h"
#import <UIKit/UIKit.h>

@class SipCallingButton;
@class VSLCall;

@protocol SipCallingButtonsViewControllerDelegate <NSObject>

/**
 *  This method will be called when the hide button needs to be shown or hidden.
 *
 *  @param visible BOOL if true, the Hide button must be shown.
 */
- (void)keypadChangedVisibility:(BOOL)visible;

/**
 *  This method will be called when a DTMF character is sent to the call.
 *
 *  @param character NSString with the character that is sent.
 */
- (void)DTMFSend:(NSString *)character;

@end

@interface SipCallingButtonsViewController : UIViewController  <NumberPadViewControllerDelegate>

/**
 *  Delegate that will conform to the SIPCallingButtonsViewControllerDelegate.
 */
@property (weak, nonatomic) id<SipCallingButtonsViewControllerDelegate> delegate;

/**
 *  The currently active call.
 */
@property (strong, nonatomic) VSLCall *call;

/**
 *  Button that can be pressed to toggle hold.
 */
@property (weak, nonatomic) IBOutlet SipCallingButton *holdButton;

/**
 *  Button that can be pressed to toggle mute.
 */
@property (weak, nonatomic) IBOutlet SipCallingButton *muteButton;

/**
 *  Button that can be pressed to toggle speaker mode.
 */
@property (weak, nonatomic) IBOutlet SipCallingButton *speakerButton;

/**
 *  Button that can be pressed to show or hide the keypad.
 */
@property (weak, nonatomic) IBOutlet SipCallingButton *keypadButton;

/**
 *  This method will toggle hold on the call.
 *
 *  @param sender SipCallingButton instance that is pressed.
 */
- (IBAction)holdButtonPressed:(SipCallingButton *)sender;

/**
 *  This method will toggle mute on the call.
 *
 *  @param sender SipCallingButton instance that is pressed.
 */
- (IBAction)muteButtonPressed:(SipCallingButton *)sender;

/**
 *  This method will toggle speaker mode on the call.
 *
 *  @param sender SipCallingButton instance that is pressed.
 */
- (IBAction)speakerButtonPressed:(SipCallingButton *)sender;

/**
 *  This method will hide the numberpad.
 */
- (void)hideNumberpad;

@end
