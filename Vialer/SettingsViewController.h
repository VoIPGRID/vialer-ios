//
//  SettingsViewController.h
//  Vialer
//
//  Created by Harold on 18/06/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EditNumberTableViewController.h"
#import "AvailabilityViewController.h"

@interface SettingsViewController : UITableViewController <EditNumberDelegate, AvailabilityViewControllerDelegate>

@end
