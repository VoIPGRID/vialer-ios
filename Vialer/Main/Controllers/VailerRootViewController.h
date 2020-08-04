//
//  VailerRootViewController.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "LogInViewController.h"

#import <UIKit/UIKit.h>

@interface VailerRootViewController : UIViewController

@property (strong, nonatomic) LogInViewController *loginViewController;

- (UIViewController *)topViewController:(UIViewController *)rootViewController;

@end
