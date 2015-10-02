//
//  ContactsViewController.m
//  Vialer
//
//  Created by Reinier Wieringa on 06/11/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "ContactsViewController.h"
#import "SystemUser.h"
#import "AppDelegate.h"

#import "ContactsSearchTableViewController.h"
#import "ContactTableViewCell.h"
#import "UIViewController+MMDrawerController.h"
#import "ContactHandler.h"
#import "HTCopyableLabel.h"

@interface ContactsViewController()
@property (nonatomic, strong) UIColor *tableTintColor;
@property (nonatomic, strong) UISearchDisplayController *searchController;
@property (nonatomic, strong) ContactsSearchTableViewController *searchTableViewController;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) ABAddressBookRef addressBook;
@property (nonatomic, strong) NSArray *addressBookContacts;
@property (nonatomic, strong) NSMutableArray *addressBookContactsSorted;
@property (nonatomic, strong) NSMutableDictionary *addressBookSectionsSorted;
@property (nonatomic, strong) NSArray *addressBookSectionTitles;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSArray *searchResults;
@end

@implementation ContactsViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Contacts", nil);
        self.tabBarItem.image = [UIImage imageNamed:@"tab-contact"];
        self.tabBarItem.selectedImage = [UIImage imageNamed:@"tab-contact-active"];
        self.searchDisplayController.delegate = self;
        
        self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];
        
        // Add hamburger menu on navigation bar
        UIBarButtonItem *leftDrawerButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"] style:UIBarButtonItemStylePlain target:self action:@selector(leftDrawerButtonPress:)];
        leftDrawerButton.tintColor = [UIColor colorWithRed:(145.f / 255.f) green:(145.f / 255.f) blue:(145.f / 255.f) alpha:1.f];
        self.navigationItem.leftBarButtonItem = leftDrawerButton;
        
        // Load the configuration to access the tint colors
        Configuration *config = [Configuration new];
        self.tableTintColor = [config tintColorForKey:kTintColorTable];
        
        self.addressBookContacts = @[];
        self.addressBookContactsSorted = [@[] mutableCopy];
        
        // Set this to fix view behind navigation bar
        [self setEdgesForExtendedLayout:UIRectEdgeNone];
        
        self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), 44.0)];
        self.searchBar.delegate = self;
        self.searchBar.placeholder = @"Search";
        self.searchBar.keyboardType = UIKeyboardTypeAlphabet;
        self.searchBar.barTintColor = [config tintColorForKey:kBarTintColorSearchBar];
        self.searchBar.tintColor = [config tintColorForKey:kTintColorSearchBar];
        [self.view addSubview:self.searchBar];
        
        self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.f, CGRectGetMaxY(self.searchBar.frame), CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - CGRectGetHeight(self.searchBar.frame))];
        self.tableView.sectionIndexColor = self.tableTintColor;
        self.tableView.delegate = self;
        self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        self.tableView.dataSource = self;
        self.tableView.tableHeaderView = [self headerView];
        [self.view addSubview:self.tableView];
        
        _searchTableViewController = [[ContactsSearchTableViewController alloc] initWithStyle:UITableViewStylePlain];
        //NSLog(@"%s: self = %@", __PRETTY_FUNCTION__, NSStringFromCGRect(self.view.frame));
        //NSLog(@"%s: search = %@", __PRETTY_FUNCTION__, NSStringFromCGRect(_searchTableViewController.view.frame));
        
        _searchController = [[UISearchDisplayController alloc] initWithSearchBar:_searchBar contentsController:self];
        _searchController.delegate = self;
        _searchController.searchResultsDataSource = _searchTableViewController;
        _searchController.searchResultsDelegate = self;
        
        //Set this or else the UISearchBar close animation looks buggy.
        //[self setExtendedLayoutIncludesOpaqueBars:YES];
        
        UIButton *addContactButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
        [addContactButton addTarget:self action:@selector(addContactButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:addContactButton];
        
    }
    return self;
}

- (UIView*)headerView {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 47.f)];
    
    UILabel *numberTitle = [[UILabel alloc] initWithFrame:CGRectMake(15.f, 0, 0, 0)];;
    [numberTitle setText:[NSString stringWithFormat:@"%@: ", NSLocalizedString(@"My number", nil)]];
    [numberTitle setBackgroundColor:[UIColor whiteColor]];
    [numberTitle sizeToFit];
    [numberTitle setCenter:CGPointMake(numberTitle.center.x, headerView.center.y)];
    [headerView addSubview:numberTitle];
    
    HTCopyableLabel *numberValue = [HTCopyableLabel new];
    [numberValue setText:[SystemUser currentUser].localizedOutgoingNumber];
    [numberValue setFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0]];
    [numberValue sizeToFit];
    [numberValue setFrame:CGRectMake(CGRectGetMaxX(numberTitle.frame), 0, CGRectGetWidth(numberValue.frame), CGRectGetHeight(numberValue.frame))];
    [numberValue setCenter:CGPointMake(numberValue.center.x, headerView.center.y)];
    [headerView addSubview:numberValue];
    
    return headerView;
}

- (void)viewDidAppear:(BOOL)animated {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    [super viewDidAppear:animated];
    
    [self loadContacts];
}

- (void)leftDrawerButtonPress:(id)sender{
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (void)addContactButtonPressed:(id)sender {
    //NSLog(@"%s sender: %@", __PRETTY_FUNCTION__, sender);
    [[ContactHandler sharedContactHandler] presentNewPersonViewControllerWithPerson:NULL presentingViewControllerDelegate:self completion:^(ABNewPersonViewController *newPersonView, ABRecordRef person) {
        //NSLog(@"%s newPersonView: %@ person: %@", __PRETTY_FUNCTION__, newPersonView, person);
        [self.tableView reloadData];
    }];
}


#pragma mark - ABAddressBook

- (void)loadContacts {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    [self checkAddressBookAccess];
}

- (void) checkAddressBookAccess {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    // Request authorization to Address Book
    self.addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef error) {
            if (granted) {
                // First time access has been granted
                //NSLog(@"%s First time access has been granted", __PRETTY_FUNCTION__);
                [self loadContactsFromAddressBook:self.addressBook];
            } else {
                // User denied access
                NSLog(@"%s User denied access", __PRETTY_FUNCTION__);
            }
        });
    }
    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        // The user has previously given access
        //NSLog(@"%s The user has previously given access", __PRETTY_FUNCTION__);
        [self loadContactsFromAddressBook:self.addressBook];
    }
    else {
        // The user has previously denied access
        NSLog(@"%s The user has previously denied access", __PRETTY_FUNCTION__);
    }
    
}

- (void)loadContactsFromAddressBook:(ABAddressBookRef)addressBookRef {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.addressBookContactsSorted removeAllObjects];
    self.addressBookContacts = (NSArray *)CFBridgingRelease(ABAddressBookCopyArrayOfAllPeople(addressBookRef));
    for (int i = 0; i < [self.addressBookContacts count]; i++) {
        
        ABRecordRef person = (__bridge ABRecordRef)[self.addressBookContacts objectAtIndex:i];
        
        CFStringRef firstName, lastName, companyName;
        firstName = ABRecordCopyValue(person, kABPersonFirstNameProperty);
        lastName  = ABRecordCopyValue(person, kABPersonLastNameProperty);
        companyName = ABRecordCopyValue(person, kABPersonOrganizationProperty);
        NSString *nsFirstname = @"";
        if (firstName != nil) nsFirstname = (__bridge NSString*)firstName;
        NSString *nsLastName = @"";
        if (lastName != nil) nsLastName = (__bridge NSString*)lastName;
        NSString *nsCompanyName = @"";
        if (companyName != nil) nsCompanyName = (__bridge NSString*)companyName;
        
        [self.addressBookContactsSorted addObject:@{@"ContactABRecordRef": (__bridge id)(person),
                                                    @"firstName": nsFirstname,
                                                    @"lastName": nsLastName,
                                                    @"companyName": nsCompanyName}];
    }
    
    NSSortDescriptor *firstNameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES];
    NSSortDescriptor *lastNameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES];
    NSSortDescriptor *companyNameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"companyName" ascending:YES];
    self.addressBookContactsSorted = [NSMutableArray arrayWithArray:[self.addressBookContactsSorted sortedArrayUsingDescriptors:@[firstNameSortDescriptor, lastNameSortDescriptor, companyNameSortDescriptor]]];
    self.addressBookSectionsSorted = [NSMutableDictionary dictionary];
    
    for (NSDictionary *contact in self.addressBookContactsSorted) {
        NSString *firstName = contact[@"firstName"];
        NSString *lastName = contact[@"lastName"];
        NSString *companyName = contact[@"companyName"];
        
        if(firstName.length > 0 || lastName.length > 0 || companyName.length > 0) {
            NSString *firstCharCap = @"";
            if (firstName.length > 0) {
                firstCharCap = [[firstName substringToIndex:1] capitalizedString];
            } else if(lastName.length > 0) {
                firstCharCap = [[lastName substringToIndex:1] capitalizedString];
            } else if(companyName.length > 0) {
                firstCharCap = [[companyName   substringToIndex:1] capitalizedString];
            }
            
            // Check if starts with no letter than key is #
            NSRange first = [firstCharCap rangeOfComposedCharacterSequenceAtIndex:0];
            NSRange match = [firstCharCap rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet] options:0 range:first];
            if (match.location == NSNotFound) {
                // Check if key already exist
                firstCharCap = @"#";
            }
            
            if (![self.addressBookSectionsSorted objectForKey:firstCharCap]) {
                [self.addressBookSectionsSorted setObject:[NSMutableArray array] forKey:firstCharCap];
            }
            
            NSMutableArray *contacts = [self.addressBookSectionsSorted objectForKey:firstCharCap];
            [contacts addObject:contact];
            
            [self.addressBookSectionsSorted setObject:contacts forKey:firstCharCap];
        }
        
    }
    
    self.addressBookSectionTitles = @[@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z", @"#"];
    
    [self.tableView reloadData];
}

#pragma mark - Person view controller delegate

- (BOOL)personViewController:(ABPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    // Delegate to the contacts view controller handler
    AppDelegate *appDelegate = ((AppDelegate *)[UIApplication sharedApplication].delegate);
    return [appDelegate handlePerson:person property:property identifier:identifier];
}

#pragma mark - Tableview delegate & datasource


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.addressBookSectionTitles.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self.addressBookSectionTitles objectAtIndex:section];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return [self.addressBookSectionTitles indexOfObject:title];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    // If search enabled show no headers
    if(_searchResults.count || _searchBar.text.length) {
        return 0.0f;
    }
    
    NSString *sectionTitle = [self.addressBookSectionTitles objectAtIndex:section];
    NSArray *contacts = [self.addressBookSectionsSorted objectForKey:sectionTitle];
    if (contacts.count == 0) {
        return 0.0f;
    }
    
    return 47.f; // Default height
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.addressBookSectionTitles;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSString *sectionTitle = [self.addressBookSectionTitles objectAtIndex:section];
    NSArray *contacts = [self.addressBookSectionsSorted objectForKey:sectionTitle];
    
    if(contacts.count > 0) {
        tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
    
    return contacts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ContactTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddressBookContactCellIdentifier"];
    if (cell == nil) {
        cell = [[ContactTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"AddressBookContactCellIdentifier"];
    }
    
    NSString *sectionTitle = [self.addressBookSectionTitles objectAtIndex:indexPath.section];
    NSArray *contacts = [self.addressBookSectionsSorted objectForKey:sectionTitle];
    NSDictionary *contact = [contacts objectAtIndex:indexPath.row];
    
    [cell populateBasedOnContactDict:contact];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.searchBar resignFirstResponder];
    
    NSString *sectionTitle = [self.addressBookSectionTitles objectAtIndex:indexPath.section];
    NSArray *contacts = [self.addressBookSectionsSorted objectForKey:sectionTitle];
    NSDictionary *contact = [contacts objectAtIndex:indexPath.row];
    
    // If search enabled use different data source
    if(_searchResults.count || _searchBar.text.length) {
        contact = [_searchResults objectAtIndex:indexPath.row];
    }
    
    if (contact) {
        ABRecordRef person = (__bridge ABRecordRef)contact[@"ContactABRecordRef"];
        if (person != NULL) {
            ABPersonViewController *personViewController = [[ABPersonViewController alloc] init];
            personViewController.personViewDelegate = self;
            personViewController.addressBook = self.addressBook;
            personViewController.displayedPerson = person;
            personViewController.allowsEditing = YES;
            personViewController.allowsActions = NO;
            [self.navigationController pushViewController:personViewController animated:YES];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 47.0;
}

#pragma mark - UISearchBarDelegate methods
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"firstName CONTAINS[cd] %@ OR lastName CONTAINS[cd] %@ OR companyName CONTAINS[cd] %@", searchText, searchText, searchText];
    _searchResults = [self.addressBookContactsSorted filteredArrayUsingPredicate:pred];
    _searchTableViewController.searchResults = _searchResults;

    // Reload the searchResultsTableView
    [_searchController.searchResultsTableView reloadData];
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    _searchResults = [NSArray array];
    [self.tableView reloadData];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView {
    [self.tableView reloadData];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didShowSearchResultsTableView:(UITableView *)tableView {
    // Changing the frame of the searchResultTableView only works in this delegate method!
    [_searchController.searchResultsTableView setFrame:CGRectMake(0.f, 0.f, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - 44.f)];
    // Furthermore the searchResultTableview has a bottom inset (and bottom scrollIndicator inset) of 177px to perfectly fit the results.
    // Its a magic number for which I (Karsten W) do not have an explanation!
    UIEdgeInsets contentInset = UIEdgeInsetsMake(0.f, 0.f, 177.f, 0.f);
    [_searchController.searchResultsTableView setContentInset:contentInset];
    [_searchController.searchResultsTableView setScrollIndicatorInsets:contentInset];
}

@end