//
//  VialerWebViewController.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "Configuration.h"
#import <PBWebViewController/PBWebViewController.h>
#import "SystemUser.h"


@class SystemUser;

@interface VialerWebViewController : PBWebViewController

/**
 *  The url where the user should be redirected to after login.
 */
@property (strong, nonatomic) NSString *nextUrl;

/**
 *  The currently loaded configuration.
 */
@property (strong, nonatomic) Configuration *configuration;

/**
 *  The currently logged in user.
 */
@property (strong, nonatomic) SystemUser *currentUser;

/**
 *  This method will be called by the back button and will pop this viewcontroller.
 *
 *  @param sender UIBarButtonItem instance that is pressed.
 */
- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender;

@end
