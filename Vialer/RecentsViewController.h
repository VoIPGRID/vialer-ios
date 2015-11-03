//
//  RecentsViewController.h
//  Vialer
//
//  Created by Reinier Wieringa on 06/11/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "ContactsUI/ContactsUI.h"

@interface RecentsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, CNContactViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *filterSegmentedControl;

- (IBAction)segmentedControlValueChanged:(UISegmentedControl *)sender;
@end
