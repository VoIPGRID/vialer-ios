//
//  SettingsViewController.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UITableViewController

/**
 *  If set to YES this will segue directly to the SIP Account activation view.
 *  This is used in the LoginViewController.
 */
@property (nonatomic) BOOL showSIPAccountWebview;

- (void)didChangeSwitch:(UISwitch *)sender;

/**
 *  This is an unwind action. This can be used to unwind to this viewcontroller.
 *
 *  @param sender UIStoryboard segue that initiated the transformation.
 */
- (IBAction)unwindToSettingsViewController:(UIStoryboardSegue *)sender;

@end
