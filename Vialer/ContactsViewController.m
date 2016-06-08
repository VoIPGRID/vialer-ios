//
//  ContactsViewController.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "ContactsViewController.h"

#import "Configuration.h"
#import "ContactsUI/ContactsUI.h"
#import "ContactModel.h"
#import "ContactUtils.h"
#import "GAITracker.h"
#import "ReachabilityBarViewController.h"
#import "SIPCallingViewController.h"
#import "SystemUser.h"
#import "TwoStepCallingViewController.h"
#import "UIAlertController+Vialer.h"
#import "UIViewController+MMDrawerController.h"

static NSString * const ContactsViewControllerLogoImageName = @"logo";
static NSString * const ContactsViewControllerTabContactImageName = @"tab-contact";
static NSString * const ContactsViewControllerTabContactActiveImageName = @"tab-contact-active";
static NSString * const ContactsViewControllerTwoStepCallingSegue = @"TwoStepCallingSegue";
static NSString * const ContactsViewControllerSIPCallingSegue = @"SIPCallingSegue";

static CGFloat const ContactsViewControllerReachabilityBarHeight = 30.0;
static NSTimeInterval const ContactsViewControllerReachabilityBarAnimationDuration = 0.3;

@interface ContactsViewController () <CNContactViewControllerDelegate, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, CNContactViewControllerDelegate, ReachabilityBarViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UILabel *warningMessageLabel;
@property (weak, nonatomic) IBOutlet UILabel *myPhoneNumberLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *reachabilityBarHeigthConstraint;
@property (weak, nonatomic) ReachabilityBarViewController *reachabilityBar;

@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) NSString *warningMessage;
@property (strong, nonatomic) NSString *phoneNumberToCall;

@property (strong, nonatomic) SystemUser *currentUser;
@property (nonatomic) ReachabilityManagerStatusType reachabilityStatus;
@property (strong, nonatomic) CNContact *selectedContact;
@end

@implementation ContactsViewController

#pragma mark - view lifecycle

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.title = NSLocalizedString(@"Contacts", nil);
        self.tabBarItem.image = [UIImage imageNamed:ContactsViewControllerTabContactImageName];
        self.tabBarItem.selectedImage = [UIImage imageNamed:ContactsViewControllerTabContactActiveImageName];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self checkContactsAccess];
    [self setupLayout];
    [self showReachabilityBar];
    [GAITracker trackScreenForControllerName:NSStringFromClass([self class])];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outgoingNumberUpdated:) name:SystemUserOutgoingNumberUpdatedNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SystemUserOutgoingNumberUpdatedNotification object:nil];
}

# pragma mark - setup

- (void)setupLayout {
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:ContactsViewControllerLogoImageName]];

    self.definesPresentationContext = YES;
    self.edgesForExtendedLayout = UIRectEdgeNone;

    Configuration *defaultConfiguration = [Configuration defaultConfiguration];

    self.tableView.sectionIndexColor = [defaultConfiguration tintColorForKey:ConfigurationContactsTableSectionIndexColor];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;

    self.searchBar.barTintColor = [defaultConfiguration tintColorForKey:ConfigurationContactSearchBarBarTintColor];
    self.myPhoneNumberLabel.text = self.currentUser.outgoingNumber;
}

#pragma mark - properties

- (void)setWarningMessage:(NSString *)warningMessage {
    if (warningMessage.length) {
        self.warningMessageLabel.hidden = NO;
        self.warningMessageLabel.text = warningMessage;
    } else {
        self.warningMessageLabel.hidden = YES;
    }
}

- (void)setTableView:(UITableView *)tableView {
    _tableView = tableView;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [_tableView addSubview:self.refreshControl];
}

- (UIRefreshControl *)refreshControl {
    if (!_refreshControl) {
        _refreshControl = [[UIRefreshControl alloc] init];
        _refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Syncing addressbook.", nil) attributes:nil];
        [_refreshControl addTarget:self action:@selector(loadContacts) forControlEvents:UIControlEventValueChanged];
    }
    return _refreshControl;
}

- (SystemUser *)currentUser {
    if (!_currentUser) {
        _currentUser = [SystemUser currentUser];
    }
    return _currentUser;
}

#pragma mark - actions

- (IBAction)leftDrawerButtonPressed:(UIBarButtonItem *)sender {
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (IBAction)addContactButtonPressed:(UIBarButtonItem *)sender {
    [self checkContactsAccess];
    CNContact *contact;
    CNContactViewController *contactViewController = [CNContactViewController viewControllerForNewContact:contact];
    contactViewController.allowsActions = NO;
    contactViewController.delegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:contactViewController];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[TwoStepCallingViewController class]]) {
        TwoStepCallingViewController *tscvc = (TwoStepCallingViewController *)segue.destinationViewController;
        [tscvc handlePhoneNumber:self.phoneNumberToCall];
    } else if ([segue.destinationViewController isKindOfClass:[SIPCallingViewController class]]) {
        SIPCallingViewController *sipCallingViewController = (SIPCallingViewController *)segue.destinationViewController;
        [sipCallingViewController handleOutgoingCallWithPhoneNumber:self.phoneNumberToCall withContact:self.selectedContact];
    } else if ([segue.destinationViewController isKindOfClass:[ReachabilityBarViewController class]]) {
        self.reachabilityBar = (ReachabilityBarViewController *)segue.destinationViewController;
        self.reachabilityBar.delegate = self;
    }
}

#pragma mark - tableview datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([tableView isEqual:self.tableView]) {
        return [[ContactModel defaultContactModel].sectionTitles count];
    }
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([tableView isEqual:self.tableView]) {
        return [ContactModel defaultContactModel].sectionTitles[section];
    } else {
        if ([[ContactModel defaultContactModel].searchResults count]) {
            return NSLocalizedString(@"Top name matches", nil);
        }
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([tableView isEqual:self.tableView]) {
        return [[[ContactModel defaultContactModel] getContactsAtSection:section] count];
    }

    return [[ContactModel defaultContactModel].searchResults count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ContactsTableViewCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    CNContact *contact;

    if ([tableView isEqual:self.tableView]) {
        contact = [[ContactModel defaultContactModel] getContactsAtSection:indexPath.section andIndex:indexPath.row];
    } else {
        contact = [ContactModel defaultContactModel].searchResults[indexPath.row];
    }

    cell.textLabel.attributedText = [ContactUtils getFormattedStyledContact:contact];

    return cell;
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if ([tableView isEqual:self.tableView]) {
        return [ContactModel defaultContactModel].sectionTitles;
    }
    return nil;
}

#pragma mark - tableview delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([tableView isEqual:self.tableView]) {
        self.selectedContact = [[ContactModel defaultContactModel] getContactsAtSection:indexPath.section andIndex:indexPath.row];
    } else {
        self.selectedContact = [ContactModel defaultContactModel].searchResults[indexPath.row];
    }

    CNContactViewController *contactViewController = [CNContactViewController viewControllerForContact:self.selectedContact];
    contactViewController.contactStore = [[ContactModel defaultContactModel] getContactStore];
    contactViewController.allowsActions = NO;
    contactViewController.delegate = self;

    [self.navigationController pushViewController:contactViewController animated:YES];

    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - CNContactViewController delegate

- (BOOL)contactViewController:(CNContactViewController *)viewController shouldPerformDefaultActionForContactProperty:(CNContactProperty *)property {
    if ([property.key isEqualToString:CNContactPhoneNumbersKey]) {
        CNPhoneNumber *phoneNumberProperty = property.value;
        self.phoneNumberToCall = [phoneNumberProperty stringValue];
        /**
         *  We need to return asap to prevent default action (calling with native dialer).
         *  As a workaround, we put the presenting of the new viewcontroller via a separate queue,
         *  which will immediately go back to the main thread.
         */
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.reachabilityStatus == ReachabilityManagerStatusHighSpeed && self.currentUser.sipEnabled) {
                    [GAITracker setupOutgoingSIPCallEvent];
                    [self performSegueWithIdentifier:ContactsViewControllerSIPCallingSegue sender:self];
                } else if (self.reachabilityStatus == ReachabilityManagerStatusLowSpeed) {
                    [GAITracker setupOutgoingConnectABCallEvent];
                    [self performSegueWithIdentifier:ContactsViewControllerTwoStepCallingSegue sender:self];
                } else {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"No internet connection", nil)
                                                                                   message:NSLocalizedString(@"It's not possible to setup a call. Make sure you have an internet connection.", nil)
                                                                      andDefaultButtonText:NSLocalizedString(@"Ok", nil)];
                    [self presentViewController:alert animated:YES completion:nil];
                }
            });
        });
        return NO;
    }
    return YES;
}

- (void)contactViewController:(CNContactViewController *)viewController didCompleteWithContact:(CNContact *)contact {
    [self loadContacts];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - searchbar delegate
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    [self hideReachabilityBar];
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    [self showReachabilityBar];
    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [[ContactModel defaultContactModel] searchContacts:searchText];
}

#pragma mark - utils

- (void)checkContactsAccess {
    CNAuthorizationStatus authorizationStatus = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];

    switch (authorizationStatus) {
        case CNAuthorizationStatusAuthorized: {
            [self loadContacts];
            break;
        }
        case CNAuthorizationStatusNotDetermined: {
            CNContactStore *contactStore = [[CNContactStore alloc] init];
            [contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
                if (granted == YES) {
                    [self loadContacts];
                } else {
                    self.warningMessage = NSLocalizedString(@"Application denied access to 'Contacts'", nil);
                }
            }];
            break;
        }
        case CNAuthorizationStatusDenied: {
            self.warningMessage = NSLocalizedString(@"Application denied access to 'Contacts'", nil);
            break;
        }
        case CNAuthorizationStatusRestricted: {
            self.warningMessage = NSLocalizedString(@"Application not authorized to access 'Contacts'", nil);
        }
    }
}

- (void)loadContacts {
    [self.refreshControl beginRefreshing];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([[ContactModel defaultContactModel] refreshAllContacts]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.refreshControl endRefreshing];
                [self.tableView reloadData];
            });
        }
    });
}

#pragma mark - Notifications

- (void)outgoingNumberUpdated:(NSNotification *)notification {
    self.myPhoneNumberLabel.text = self.currentUser.outgoingNumber;
}

#pragma mark - ReachabilityBarViewControllerDelegate
- (void)hideReachabilityBar {
    self.reachabilityBarHeigthConstraint.constant = 0.0;
    self.reachabilityBar.view.hidden = YES;
    [self.view layoutIfNeeded];
}

- (void)showReachabilityBar {
    if (self.reachabilityBar.shouldBeVisible) {
        self.reachabilityBarHeigthConstraint.constant = ContactsViewControllerReachabilityBarHeight;
        self.reachabilityBar.view.hidden = NO;
        [self.view layoutIfNeeded];
    }
}

- (void)reachabilityBar:(ReachabilityBarViewController *)reachabilityBar statusChanged:(ReachabilityManagerStatusType)status {
    self.reachabilityStatus = status;
}

- (void)reachabilityBar:(ReachabilityBarViewController *)reachabilityBar shouldBeVisible:(BOOL)visible {
    [self.view layoutIfNeeded];
    self.reachabilityBarHeigthConstraint.constant = visible ? ContactsViewControllerReachabilityBarHeight : 0.0;
    [UIView animateWithDuration:ContactsViewControllerReachabilityBarAnimationDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}

@end

