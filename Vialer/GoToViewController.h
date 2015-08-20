//
//  GoToViewController.h
//  Vialer
//
//  Created by Reinier Wieringa on 13/08/14.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TrackedViewController.h"

@interface GoToViewController : TrackedViewController<UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@end
