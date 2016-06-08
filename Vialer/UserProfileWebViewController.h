//
//  UserProfileWebViewController.h
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "VialerWebViewController.h"

/**
 *  Controller that will do some extra logic when the user wants to exit the controller.
 *
 *  When the controller will be dismissed, there is a check if the user has an SIP account set.
 *  If so, the view will exit to the settings view, if not, the previous view will be loaded.
 */
@interface UserProfileWebViewController : VialerWebViewController

/**
 *  Segue back to root view controller is being set from the login view controller.
 */
@property (nonatomic) BOOL backButtonToRootViewController;

@end
