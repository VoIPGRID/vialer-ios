//
//  SettingsViewController.h
//  Vialer
//
//  Created by Reinier Wieringa on 11/12/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SelectRecentsFilterViewController.h"

@interface SettingsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, SelectRecentsFilterViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end
