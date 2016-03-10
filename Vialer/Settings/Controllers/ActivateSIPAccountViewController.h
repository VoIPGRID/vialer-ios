//
//  ActivateSIPAccountViewController.h
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ActivateSIPAccountViewController : UIViewController

/**
 *  Segue back to root view controller is being set from the login view controller.
 */
@property (nonatomic) BOOL backButtonToRootViewController;

/**
 *  This method will be called by the back button and will pop this viewcontroller.
 *
 *  @param sender UIBarButtonItem instance that is pressed.
 */
- (IBAction)backButtonPressed:(id)sender;

@end
