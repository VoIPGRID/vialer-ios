//
//  ContactsViewController.h
//  Vialer
//
//  Created by Reinier Wieringa on 06/11/13.
//  Copyright (c) 2013 Voys. All rights reserved.
//

#import <AddressBookUI/AddressBookUI.h>

@interface ContactsViewController : ABPeoplePickerNavigationController<ABPeoplePickerNavigationControllerDelegate, UINavigationControllerDelegate, UISearchDisplayDelegate>

@end
