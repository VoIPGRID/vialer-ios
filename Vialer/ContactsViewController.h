//
//  ContactsViewController.h
//  Vialer
//
//  Created by Reinier Wieringa on 06/11/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "ContactsUI/ContactsUI.h"

@interface ContactsViewController : UITableViewController <UINavigationControllerDelegate, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, CNContactViewControllerDelegate, UISearchResultsUpdating, UISearchControllerDelegate>

@end
