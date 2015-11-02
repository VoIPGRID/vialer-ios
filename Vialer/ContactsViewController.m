//
//  ContactsViewController.m
//  Vialer
//
//  Created by Reinier Wieringa on 06/11/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "ContactsViewController.h"

#import "AppDelegate.h"
#import "ContactModel.h"
#import "ContactUtils.h"
#import "GAITracker.h"
#import "SystemUser.h" 

#import "HTCopyableLabel.h"
#import "UIViewController+MMDrawerController.h"

static NSString *const ContactsViewControllerTabContactImageName = @"tab-contact";
static NSString *const ContactsViewControllerTabContactActiveImageName = @"tab-contact-active";
static NSString *const ContactsViewControllerLogoImageName = @"logo";
static NSString *const ContactsViewControllerMenuImageName = @"menu";
static NSString *const ContactsViewControllerPropertyPhoneNumbers = @"phoneNumbers";
static CGFloat const ContactsViewControllerTableHeaderHeight = 30.0f;
static CGFloat const ContactsViewControllerTableCellHeight = 44.0f;
static CGFloat const ContactsViewControllerCustomCellLabelLeftOffset = 15.0f;
static CGFloat const ContactsViewControllerEdgeOffsetSearchTable = 20.0f;

@interface ContactsViewController()
@property (nonatomic, strong) ContactModel *contactModel;
@property (nonatomic, strong) UITableViewController *searchTableViewController;
@property (nonatomic, strong) UITableView *searchResultsTableView;
@property (nonatomic, strong) NSArray *contactsSectionTitles;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) UIBarButtonItem *leftDrawerButton;
@property (nonatomic, strong) UIButton *addContactButton;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIView *noMatchesView;
@property (nonatomic, strong) UILabel *noMatchesLabel;
@end

@implementation ContactsViewController

- (instancetype)init {
    self = [super init];

    if (self) {
        self.title = NSLocalizedString(@"Contacts", nil);
        self.tabBarItem.image = [UIImage imageNamed:ContactsViewControllerTabContactImageName];
        self.tabBarItem.selectedImage = [UIImage imageNamed:ContactsViewControllerTabContactActiveImageName];
        self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:ContactsViewControllerLogoImageName]];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [GAITracker trackScreenForControllerName:NSStringFromClass([self class])];
    [self setupLayout];
    [self checkContactsAccess];
}

- (void)setupLayout {
    // Add hamburger menu on navigation bar
    self.navigationItem.leftBarButtonItem = self.leftDrawerButton;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.addContactButton];
    self.definesPresentationContext = YES;
    self.edgesForExtendedLayout = UIRectEdgeNone;

    self.tableView.tableHeaderView = self.headerView;
    self.tableView.sectionIndexColor = [Configuration tintColorForKey:kTintColorNavigationBar];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
}

# pragma mark - Lazy loading properties
- (ContactModel *)contactModel {
    if (!_contactModel) {
        _contactModel = [[ContactModel alloc] init];
    }
    return _contactModel;
}

- (NSArray *)contactsSectionTitles {
    if (!_contactsSectionTitles) {
        _contactsSectionTitles = @[@"A", @"B", @"C", @"D", @"E", @"F", @"G",
                                   @"H", @"I", @"J", @"K", @"L", @"M", @"N",
                                   @"O", @"P", @"Q", @"R", @"S", @"T", @"U",
                                   @"V", @"W", @"X", @"Y", @"Z", @"#"];
    }
    return _contactsSectionTitles;
}

- (UITableViewController *)searchTableViewController {
    if (!_searchTableViewController) {
        _searchTableViewController = [[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        _searchTableViewController.tableView = self.searchResultsTableView;
    }
    return _searchTableViewController;
}

- (UIBarButtonItem *)leftDrawerButton {
    if (!_leftDrawerButton) {
        _leftDrawerButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:ContactsViewControllerMenuImageName]
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(leftDrawerButtonPress:)];
        _leftDrawerButton.tintColor = [Configuration tintColorForKey: kTintColorLeftDrawerButton];
    }
    return _leftDrawerButton;
}

- (UITableView *)searchResultsTableView {
    if (!_searchResultsTableView) {
        _searchResultsTableView = [[UITableView alloc] initWithFrame:self.tableView.frame];
        _searchResultsTableView.dataSource = self;
        _searchResultsTableView.delegate = self;
        [_searchResultsTableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"ContactsTableViewCell"];
    }
    return _searchResultsTableView;
}

- (UIButton *)addContactButton {
    if (!_addContactButton) {
        _addContactButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
        [_addContactButton addTarget:self action:@selector(addContactButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }

    return _addContactButton;
}

- (UISearchController *)searchController {
    if (!_searchController) {
        _searchController = [[UISearchController alloc] initWithSearchResultsController:self.searchTableViewController];
        _searchController.searchResultsUpdater = self;
        _searchController.searchBar.delegate = self;
        _searchController.searchBar.keyboardType = UIKeyboardTypeAlphabet;
        _searchController.searchBar.barTintColor = [Configuration tintColorForKey:kTintColorSearchBar];
        _searchController.searchBar.tintColor = [UIColor whiteColor];
        _searchController.searchBar.layer.borderWidth = 1;
        _searchController.searchBar.layer.borderColor = [[Configuration tintColorForKey:kTintColorSearchBar] CGColor];
        [_searchController.searchBar sizeToFit];
    }
    return _searchController;
}

- (UIView *)noMatchesView {
    if (!_noMatchesView) {
        _noMatchesView = [[UIView alloc] initWithFrame:self.searchResultsTableView.frame];
        _noMatchesView.hidden = YES;
        [_noMatchesView addSubview: self.noMatchesLabel];
        [self.searchResultsTableView insertSubview:_noMatchesView belowSubview:self.searchResultsTableView];
    }
    return _noMatchesView;
}

- (UILabel *)noMatchesLabel {
    if (!_noMatchesLabel) {
        _noMatchesLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))];
        _noMatchesLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0];
        _noMatchesLabel.shadowColor = [UIColor lightTextColor];
        _noMatchesLabel.textColor = [UIColor grayColor];
        _noMatchesLabel.shadowOffset = CGSizeMake(0, 1);
        _noMatchesLabel.backgroundColor = [UIColor clearColor];
        _noMatchesLabel.textAlignment = NSTextAlignmentCenter;
        _noMatchesLabel.text = NSLocalizedString(@"No Results", nil);
    }
    return _noMatchesLabel;
}

- (UIView *)headerView {
    if (!_headerView) {
        _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), ContactsViewControllerTableCellHeight * 2)];

        UIView *searchBarHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(_headerView.frame), ContactsViewControllerTableCellHeight)];
        [searchBarHeaderView addSubview:self.searchController.searchBar];

        UIView *meContactView = [[UIView alloc] initWithFrame: CGRectMake(0, ContactsViewControllerTableCellHeight / 2, CGRectGetWidth(_headerView.frame), ContactsViewControllerTableCellHeight)];

        UILabel *numberTitle = [[UILabel alloc] initWithFrame:CGRectMake(ContactsViewControllerCustomCellLabelLeftOffset, 0, 0, 0)];;
        [numberTitle setText:[NSString stringWithFormat:@"%@: ", NSLocalizedString(@"My number", nil)]];
        [numberTitle setBackgroundColor:[UIColor whiteColor]];
        [numberTitle sizeToFit];
        [numberTitle setCenter:CGPointMake(numberTitle.center.x, meContactView.center.y)];
        [meContactView addSubview:numberTitle];

        HTCopyableLabel *numberValue = [HTCopyableLabel new];
        [numberValue setText:[SystemUser currentUser].localizedOutgoingNumber];
        [numberValue setFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0]];
        [numberValue sizeToFit];
        [numberValue setFrame:CGRectMake(CGRectGetMaxX(numberTitle.frame),
                                         0,
                                         CGRectGetWidth(numberValue.frame),
                                         CGRectGetHeight(numberValue.frame))];
        [numberValue setCenter:CGPointMake(numberValue.center.x, meContactView.center.y)];
        [meContactView addSubview:numberValue];

        [_headerView addSubview:searchBarHeaderView];
        [_headerView addSubview:meContactView];

    }
    return _headerView;
}

- (void)leftDrawerButtonPress:(id)sender{
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (void)addContactButtonPressed:(id)sender {
    CNContact *contact;
    CNContactViewController *contactViewController = [CNContactViewController viewControllerForNewContact:contact];
    contactViewController.allowsActions = NO;
    contactViewController.delegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:contactViewController];
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - Contacts permission
- (void)checkContactsAccess {
    CNAuthorizationStatus authorizationStatus = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];

    if (authorizationStatus == CNAuthorizationStatusAuthorized) {
        [self loadContacts];
    } else if (authorizationStatus == CNAuthorizationStatusNotDetermined) {
        CNContactStore *contactStore = [[CNContactStore alloc] init];
        [contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (granted == YES) {
                [self loadContacts];
            } else {
                [self contactStoreAuthorizationMessage:[NSString stringWithFormat:@"%@", NSLocalizedString(@"Application denied access to 'Contacts'", nil)]];
                NSLog(@"%s The user has denied access", __PRETTY_FUNCTION__);
            }
        }];
    } else if (authorizationStatus == CNAuthorizationStatusDenied) {
        NSLog(@"%s The user has previously denied access", __PRETTY_FUNCTION__);
        [self contactStoreAuthorizationMessage:[NSString stringWithFormat:@"%@", NSLocalizedString(@"Application denied access to 'Contacts'", nil)]];
    } else if (authorizationStatus == CNAuthorizationStatusRestricted) {
        NSLog(@"%s The application is not authorized to access contact data.", __PRETTY_FUNCTION__);
        [self contactStoreAuthorizationMessage:[NSString stringWithFormat:@"%@", NSLocalizedString(@"Application not authorized to access 'Contacts'", nil)]];
    }
}

- (void)contactStoreAuthorizationMessage:(NSString *)message {
    UILabel *authorizationLabel = [[UILabel alloc] initWithFrame:CGRectMake(ContactsViewControllerCustomCellLabelLeftOffset, 0, 0, 0)];
    [authorizationLabel setText: message];
    [authorizationLabel setBackgroundColor:[UIColor whiteColor]];
    [authorizationLabel sizeToFit];
    [authorizationLabel setCenter:CGPointMake(authorizationLabel.center.x, self.headerView.center.y)];

    [self.headerView addSubview:authorizationLabel];
}

- (void)loadContacts {
    [self.contactModel getContacts:^{
        [self.tableView reloadData];
    }];
}

#pragma mark - Tableview delegate & datasource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([tableView isEqual:self.searchResultsTableView]) {
        return 1;
    }
    return self.contactsSectionTitles.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([tableView isEqual:self.searchResultsTableView]) {
        if ([self.contactModel countSearchContacts]) {
            return NSLocalizedString(@"Top name matches", nil);
        }
        return nil;
    }
    return [self.contactsSectionTitles objectAtIndex:section];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    if ([tableView isEqual:self.searchResultsTableView]) {
        return 0;
    }
    return [self.contactsSectionTitles indexOfObject:title];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ([tableView isEqual:self.searchResultsTableView]) {
        return ContactsViewControllerTableHeaderHeight;
    }

    NSString *sectionTitle = [self.contactsSectionTitles objectAtIndex:section];
    NSInteger contactsCount = [self.contactModel countContactSection:sectionTitle];

    if (!contactsCount) {
        return 0.0f;
    }
    return ContactsViewControllerTableHeaderHeight;
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if ([tableView isEqual:self.searchResultsTableView]) {
        return nil;
    }
    return self.contactsSectionTitles;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([tableView isEqual:self.searchResultsTableView]) {
        NSInteger numberOfSearchResults = [self.contactModel countSearchContacts];
        self.noMatchesView.hidden = numberOfSearchResults ? YES : NO;

        return numberOfSearchResults;
    }

    NSString *sectionTitle = [self.contactsSectionTitles objectAtIndex:section];
    NSInteger contactsCount = [self.contactModel countContactSection:sectionTitle];

    if (contactsCount > 0) {
        tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
    return contactsCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ContactsTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    CNContact *contact;

    if ([tableView isEqual:self.searchResultsTableView]) {
        contact = [self.contactModel getSearchContactAtIndex:indexPath.row];
    } else {
        NSString *sectionTitle = [self.contactsSectionTitles objectAtIndex:indexPath.section];
        contact = [self.contactModel getContactsAtSectionAndIndex:sectionTitle andIndex:indexPath.row];
    }

    cell.textLabel.attributedText = [ContactUtils getFormattedStyledContact:contact];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CNContact *contact;
    NSString *sectionTitle = [self.contactsSectionTitles objectAtIndex:indexPath.section];

    if ([tableView isEqual:self.searchResultsTableView]) {
        contact = [self.contactModel getSearchContactAtIndex:indexPath.row];
    } else {
        contact = [self.contactModel getContactsAtSectionAndIndex:sectionTitle andIndex:indexPath.row];
    }

    CNContactViewController *contactViewController = [CNContactViewController viewControllerForContact:contact];
    contactViewController.contactStore = [self.contactModel getContactStore];
    contactViewController.allowsActions = NO;
    contactViewController.delegate = self;

    [self.navigationController pushViewController:contactViewController animated:YES];

    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return ContactsViewControllerTableCellHeight;
}

- (BOOL)contactViewController:(CNContactViewController *)viewController shouldPerformDefaultActionForContactProperty:(CNContactProperty *)property {
    if ([property.key isEqualToString:ContactsViewControllerPropertyPhoneNumbers]) {
        CNPhoneNumber *phoneNumberProperty = property.value;
        NSString *phoneNumber = [phoneNumberProperty stringValue];

        AppDelegate *appDelegate = ((AppDelegate *)[UIApplication sharedApplication].delegate);
        [appDelegate handlePhoneNumber:phoneNumber];

        return YES;
    }
    return NO;
}

- (void)contactViewController:(CNContactViewController *)viewController didCompleteWithContact:(CNContact *)contact {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    UISearchBar *searchBar = searchController.searchBar;
    NSString *searchText = searchBar.text;

    [self.searchTableViewController.tableView setFrame:CGRectMake(0.f, ContactsViewControllerTableCellHeight, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - ContactsViewControllerTableCellHeight)];
    // Furthermore the searchResultTableview has a bottom inset (and bottom scrollIndicator inset) of 177px to perfectly fit the results.
    // Its a magic number for which I (Karsten W) do not have an explanation!
    UIEdgeInsets contentInset = UIEdgeInsetsMake(ContactsViewControllerEdgeOffsetSearchTable, 0.f, 0.f, 0.f);
    [self.searchTableViewController.tableView setContentInset:contentInset];
    [self.searchTableViewController.tableView setScrollIndicatorInsets:contentInset];

    [self.contactModel searchContacts:searchText withCompletion:^() {
        [self.searchTableViewController.tableView reloadData];
    }];
}

@end