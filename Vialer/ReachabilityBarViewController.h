//
//  ReachabilityBarViewController.h
//  Vialer
//
//  Created by Bob Voorneveld on 10/11/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ReachabilityManager.h"

@interface ReachabilityBarViewController : UIViewController

// Update this property to change visibility of elements
@property (nonatomic) ReachabilityManagerStatusType status;

@end
