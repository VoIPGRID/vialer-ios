//
//  ContactsViewController.h
//  Vialer
//
//  Created by Reinier Wieringa on 06/11/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import <AddressBookUI/AddressBookUI.h>
#import "TrackedViewController.h"

@interface ContactsViewController : TrackedViewController <ABPersonViewControllerDelegate, UINavigationControllerDelegate, UISearchDisplayDelegate, UISearchBarDelegate, UISearchControllerDelegate, UITableViewDataSource, UITableViewDelegate>

@end
