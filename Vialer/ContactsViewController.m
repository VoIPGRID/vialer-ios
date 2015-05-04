//
//  ContactsViewController.m
//  Vialer
//
//  Created by Reinier Wieringa on 06/11/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "ContactsViewController.h"
#import "VoIPGRIDRequestOperationManager.h"
#import "AppDelegate.h"


#import "UIViewController+MMDrawerController.h"
#import "ContactHandler.h"


@interface ContactsViewController()
@property (nonatomic, retain) id<UISearchDisplayDelegate> oldSearchDisplayDelegate;
@property (nonatomic, strong) UIColor *tableTintColor;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) ABAddressBookRef addressBook;
@property (nonatomic, strong) NSArray *addressBookContacts;
@property (nonatomic, strong) NSMutableArray *addressBookContactsSorted;
@property (nonatomic, strong) UISearchBar *searchBar;

@end

@implementation ContactsViewController

- (id)init {
    self = [super init];
    if (self) {
        //self.delegate = self;
        //self.peoplePickerDelegate = self;
        self.title = NSLocalizedString(@"Contacts", nil);
        self.tabBarItem.image = [UIImage imageNamed:@"tab-contact"];
        self.tabBarItem.selectedImage = [UIImage imageNamed:@"tab-contact-active"];
        self.searchDisplayController.delegate = self;
        
        self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];
        
        // Add hamburger menu on navigation bar
        UIBarButtonItem *leftDrawerButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"] style:UIBarButtonItemStyleBordered target:self action:@selector(leftDrawerButtonPress:)];
        leftDrawerButton.tintColor = [UIColor colorWithRed:(145.f / 255.f) green:(145.f / 255.f) blue:(145.f / 255.f) alpha:1.f];
        self.navigationItem.leftBarButtonItem = leftDrawerButton;
        
        // This works for iOS7 and below
        //UIViewController *rootViewController = [self.viewControllers firstObject];
        //rootViewController.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];

        //[self setAllowsCancel:NO];

        NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"]];
        NSAssert(config != nil, @"Config.plist not found!");

        NSArray *tableTintColor = [[config objectForKey:@"Tint colors"] objectForKey:@"Table"];
        NSAssert(tableTintColor != nil && tableTintColor.count == 3, @"Tint colors - Table not found in Config.plist!");
        self.tableTintColor = [UIColor colorWithRed:[tableTintColor[0] intValue] / 255.f green:[tableTintColor[1] intValue] / 255.f blue:[tableTintColor[2] intValue] / 255.f alpha:1.f];
        
        self.addressBookContacts = @[];
        self.addressBookContactsSorted = [@[] mutableCopy];
        
        self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        [self.view addSubview:self.tableView];
        
        self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.tableView.frame), 40.0)];
        self.searchBar.delegate = self;
        self.searchBar.placeholder = @"Zoeken";
        self.searchBar.keyboardType = UIKeyboardTypeAlphabet;
        self.tableView.tableHeaderView = self.searchBar;
       
        //Set this or else the UISearchBar close animation looks buggy.
        [self setExtendedLayoutIncludesOpaqueBars:YES];
        
        
        self.automaticallyAdjustsScrollViewInsets =  YES;
        
        UIButton *addContactButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
        [addContactButton addTarget:self action:@selector(addContactButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:addContactButton];
        
    }
    return self;
}


- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [super viewDidAppear:animated];
    
    [self loadContacts];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)leftDrawerButtonPress:(id)sender{
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}


- (void)addContactButtonPressed:(id)sender {
    NSLog(@"%s sender: %@", __PRETTY_FUNCTION__, sender);
    [[ContactHandler sharedContactHandler] presentNewPersonViewControllerWithPerson:NULL presentingViewControllerDelegate:self completion:^(ABNewPersonViewController *newPersonView, ABRecordRef person) {
        NSLog(@"%s newPersonView: %@ person: %@", __PRETTY_FUNCTION__, newPersonView, person);
        [self.tableView reloadData];
    }];
}


#pragma mark - ABAddressBook

- (void)loadContacts {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self checkAddressBookAccess];
}

- (void) checkAddressBookAccess {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    // Request authorization to Address Book
    self.addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef error) {
            if (granted) {
                // First time access has been granted
                NSLog(@"%s First time access has been granted", __PRETTY_FUNCTION__);
                [self loadContactsFromAddressBook:self.addressBook];
            } else {
                // User denied access
                NSLog(@"%s User denied access", __PRETTY_FUNCTION__);
            }
        });
    }
    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        // The user has previously given access
        NSLog(@"%s The user has previously given access", __PRETTY_FUNCTION__);
        [self loadContactsFromAddressBook:self.addressBook];
    }
    else {
        // The user has previously denied access
        NSLog(@"%s The user has previously denied access", __PRETTY_FUNCTION__);
    }
    
}

- (void)loadContactsFromAddressBook:(ABAddressBookRef)addressBookRef {
    NSLog(@"%s", __PRETTY_FUNCTION__);
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
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES];
    self.addressBookContactsSorted = [NSMutableArray arrayWithArray:[self.addressBookContactsSorted sortedArrayUsingDescriptors:@[sortDescriptor]]];
    
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.addressBookContactsSorted.count > 0) {
        return self.addressBookContactsSorted.count;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
   
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddressBookContactCellIdentifier"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"AddressBookContactCellIdentifier"];
    }

    if (self.addressBookContactsSorted.count > 0) {
        NSDictionary *contact = [self.addressBookContactsSorted objectAtIndex:indexPath.row];
        NSString *fullName = [NSString stringWithFormat:@"%@ %@", contact[@"firstName"], contact[@"lastName"]];
        fullName = [fullName stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
        if (fullName.length == 0) {
            fullName = contact[@"companyName"];
        }
        cell.textLabel.text = fullName;
    } else {
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.font = [UIFont systemFontOfSize:17.f];
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.text = NSLocalizedString(@"NO_CONTACTS_LABEL", nil);
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self.searchBar resignFirstResponder];
    
    NSDictionary *contact = [self.addressBookContactsSorted objectAtIndex:indexPath.row];
    if (contact) {
        ABRecordRef person = (__bridge ABRecordRef)contact[@"ContactABRecordRef"];
        if (person != NULL) {
            ABPersonViewController *personViewController = [[ABPersonViewController alloc] init];
            personViewController.personViewDelegate = self;
            personViewController.addressBook = self.addressBook;
            personViewController.displayedPerson = person;
            personViewController.allowsEditing = YES;
            [self.navigationController pushViewController:personViewController animated:YES];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 47.0;
}
/*
#pragma mark - Navigation controller delegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (viewController.searchDisplayController) {
        if (viewController.searchDisplayController.delegate != self) {
            self.oldSearchDisplayDelegate = viewController.searchDisplayController.delegate;
            viewController.searchDisplayController.delegate = self;
        }
    }

    if ([navigationController.viewControllers indexOfObject:viewController] == 0) {
        viewController.navigationItem.leftBarButtonItem = nil;
        viewController.navigationItem.rightBarButtonItem = nil;
        
        if ([viewController isKindOfClass:[UITableViewController class]]) {
            UITableViewController *tableViewController = (UITableViewController *)viewController;
            tableViewController.tableView.sectionIndexColor = self.tableTintColor;
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f) {
                tableViewController.tableView.tintColor = self.tableTintColor;
            }
        }
    } else {
        viewController.navigationItem.rightBarButtonItem = nil;
    }
}

#pragma mark - Search controller delegate

- (void) searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    if ([self.oldSearchDisplayDelegate respondsToSelector:@selector(searchDisplayControllerWillBeginSearch:)]) {
        [self.oldSearchDisplayDelegate searchDisplayControllerWillBeginSearch:controller];
    }
}

- (void) searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller {
    if ([self.oldSearchDisplayDelegate respondsToSelector:@selector(searchDisplayControllerDidBeginSearch:)]) {
        [self.oldSearchDisplayDelegate searchDisplayControllerDidBeginSearch:controller];
    }
}

- (void) searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
    if ([self.oldSearchDisplayDelegate respondsToSelector:@selector(searchDisplayControllerWillEndSearch:)]) {
        [self.oldSearchDisplayDelegate searchDisplayControllerWillEndSearch:controller];
    }
    
    if (controller.searchContentsController && controller.searchContentsController.navigationController && controller.searchContentsController.navigationController.viewControllers.count) {
        UIViewController *viewController = [controller.searchContentsController.navigationController.viewControllers objectAtIndex:0];
        if (!viewController) {
            return;
        }
        
        viewController.navigationItem.leftBarButtonItem = nil;
        viewController.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
    if ([self.oldSearchDisplayDelegate respondsToSelector:@selector(searchDisplayControllerDidEndSearch:)]) {
        [self.oldSearchDisplayDelegate searchDisplayControllerDidEndSearch:controller];
    }
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView {
    if ([self.oldSearchDisplayDelegate respondsToSelector:@selector(searchDisplayController:didLoadSearchResultsTableView:)]) {
        [self.oldSearchDisplayDelegate searchDisplayController:controller didLoadSearchResultsTableView:tableView];
    }
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView {
    if ([self.oldSearchDisplayDelegate respondsToSelector:@selector(searchDisplayController:willUnloadSearchResultsTableView:)]) {
        [self.oldSearchDisplayDelegate searchDisplayController:controller willUnloadSearchResultsTableView:tableView];
    }
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView {
    if ([self.oldSearchDisplayDelegate respondsToSelector:@selector(searchDisplayController:willShowSearchResultsTableView:)]) {
        [self.oldSearchDisplayDelegate searchDisplayController:controller willShowSearchResultsTableView:tableView];
    }
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didShowSearchResultsTableView:(UITableView *)tableView {
    if ([self.oldSearchDisplayDelegate respondsToSelector:@selector(searchDisplayController:didShowSearchResultsTableView:)]) {
        [self.oldSearchDisplayDelegate searchDisplayController:controller didShowSearchResultsTableView:tableView];
    }
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView {
    if ([self.oldSearchDisplayDelegate respondsToSelector:@selector(searchDisplayController:willHideSearchResultsTableView:)]) {
        [self.oldSearchDisplayDelegate searchDisplayController:controller willHideSearchResultsTableView:tableView];
    }
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView {
    if ([self.oldSearchDisplayDelegate respondsToSelector:@selector(searchDisplayController:didHideSearchResultsTableView:)]) {
        [self.oldSearchDisplayDelegate searchDisplayController:controller didHideSearchResultsTableView:tableView];
    }
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    if ([self.oldSearchDisplayDelegate respondsToSelector:@selector(searchDisplayController:shouldReloadTableForSearchString:)]) {
        return [self.oldSearchDisplayDelegate searchDisplayController:controller shouldReloadTableForSearchString:searchString];
    }
    return NO;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    if ([self.oldSearchDisplayDelegate respondsToSelector:@selector(searchDisplayController:shouldReloadTableForSearchScope:)]) {
        return [self.oldSearchDisplayDelegate searchDisplayController:controller shouldReloadTableForSearchScope:searchOption];
    }
    return NO;
}

#pragma mark - People picker delegaate

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    return YES;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {

    AppDelegate *appDelegate = ((AppDelegate *)[UIApplication sharedApplication].delegate);
    return [appDelegate handlePerson:person property:property identifier:identifier];
}

- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController*)peoplePicker didSelectPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    AppDelegate *appDelegate = ((AppDelegate *)[UIApplication sharedApplication].delegate);
    [appDelegate handlePerson:person property:property identifier:identifier];
}
*/
@end
