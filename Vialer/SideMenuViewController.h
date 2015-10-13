//
//  SideMenuViewController.h
//  Vialer
//
//  Created by Reinier Wieringa on 4/16/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SideMenuViewController : UITableViewController

@end

@interface SideMenuItem : NSObject
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) UIImage *icon;
+ (instancetype)sideMenuItemWithTitle:(NSString *)title andIcon:(UIImage *)icon;
@end