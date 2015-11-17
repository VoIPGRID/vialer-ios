//
//  RootViewController.h
//  Vialer
//
//  Created by Bob Voorneveld on 06/10/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "MMDrawerController.h"

@class GSCall;

@interface RootViewController : MMDrawerController

- (void)handleSipCall:(GSCall *)sipCall;

@end
