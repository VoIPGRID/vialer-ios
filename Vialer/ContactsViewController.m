//
//  ContactsViewController.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "ContactsViewController.h"

#import "Configuration.h"
#import "ContactsUI/ContactsUI.h"
#import "ReachabilityBarViewController.h"
#import "SystemUser.h"
#import "TwoStepCallingViewController.h"
#import "UIAlertController+Vialer.h"
#import "UIViewController+MMDrawerController.h"
#import "Vialer-Swift.h"

static NSString * const ContactsViewControllerLogoImageName = @"logo";
static NSString * const ContactsViewControllerTabContactImageName = @"tab-contact";
static NSString * const ContactsViewControllerTabContactActiveImageName = @"tab-contact-active";
static NSString * const ContactsViewControllerTwoStepCallingSegue = @"TwoStepCallingSegue";
static NSString * const ContactsViewControllerSIPCallingSegue = @"SIPCallingSegue";

static NSString * const ContactsTableViewMyNumberCell = @"ContactsTableViewMyNumberCell";
static NSString * const ContactsTableViewCell = @"ContactsTableViewCell";

static CGFloat const ContactsViewControllerReachabilityBarHeight = 30.0;
static NSTimeInterval const ContactsViewControllerReachabilityBarAnimationDuration = 0.3;

@interface ContactsViewController () <CNContactViewControllerDelegate, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, CNContactViewControllerDelegate, ReachabilityBarViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UILabel *warningMessageLabel;
@property (weak, nonatomic) IBOutlet UILabel *myPhoneNumberLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *reachabilityBarHeigthConstraint;
@property (weak, nonatomic) ReachabilityBarViewController *reachabilityBar;

@property (strong, nonatomic) NSString *warningMessage;
@property (strong, nonatomic) NSString *phoneNumberToCall;

@property (strong, nonatomic) SystemUser *currentUser;
@property (nonatomic) ReachabilityManagerStatusType reachabilityStatus;
@property (strong, nonatomic) CNContact *selectedContact;

@property (weak, nonatomic) ContactModel *contactModel;
@property (weak, nonatomic) Configuration *defaultConfiguration;

@property (nonatomic) BOOL showTitleImage;

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

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outgoingNumberUpdated:) name:SystemUserOutgoingNumberUpdatedNotification object:nil];
    self.showTitleImage = YES;
    [self setupLayout];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self showReachabilityBar];
    [VialerGAITracker trackScreenForControllerWithName:NSStringFromClass([self class])];
    
    if (self.showTitleImage) {
        self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:ContactsViewControllerLogoImageName]];
    } else {
        self.showTitleImage = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:ContactsViewControllerLogoImageName]];
    [self checkContactsAccess];

    [[NSNotificationCenter defaultCenter] addObserverForName:@"ContactModel.ContactsUpdated" object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ContactModel.ContactsUpdated" object:nil];
    [super viewWillDisappear:animated];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SystemUserOutgoingNumberUpdatedNotification object:nil];
}

# pragma mark - setup

- (void)setupLayout {
    self.definesPresentationContext = YES;
    self.edgesForExtendedLayout = UIRectEdgeNone;

    self.tableView.sectionIndexColor = [self.defaultConfiguration.colorConfiguration colorForKey:ConfigurationContactsTableSectionIndexColor];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;

    self.searchBar.barTintColor = [self.defaultConfiguration.colorConfiguration colorForKey:ConfigurationContactSearchBarBarTintColor];
    self.myPhoneNumberLabel.text = self.currentUser.outgoingNumber;

    self.navigationController.view.backgroundColor = [self.defaultConfiguration.colorConfiguration colorForKey:ConfigurationNavigationBarBarTintColor];
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
}

- (SystemUser *)currentUser {
    if (!_currentUser) {
        _currentUser = [SystemUser currentUser];
    }
    return _currentUser;
}

- (ContactModel *)contactModel {
    if (!_contactModel) {
        _contactModel = [ContactModel defaultModel];
    }
    return _contactModel;
}

- (Configuration *)defaultConfiguration {
    if (!_defaultConfiguration) {
        _defaultConfiguration = [Configuration defaultConfiguration];
    }
    return _defaultConfiguration;
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
    nav.view.backgroundColor = [self.defaultConfiguration.colorConfiguration colorForKey:ConfigurationNavigationBarBarTintColor];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[TwoStepCallingViewController class]]) {
        TwoStepCallingViewController *tscvc = (TwoStepCallingViewController *)segue.destinationViewController;
        [tscvc handlePhoneNumber:self.phoneNumberToCall];
    } else if ([segue.destinationViewController isKindOfClass:[SIPCallingViewController class]]) {
        SIPCallingViewController *sipCallingVC = (SIPCallingViewController *)segue.destinationViewController;
        [sipCallingVC handleOutgoingCallWithPhoneNumber:self.phoneNumberToCall contact:self.selectedContact];
    } else if ([segue.destinationViewController isKindOfClass:[ReachabilityBarViewController class]]) {
        self.reachabilityBar = (ReachabilityBarViewController *)segue.destinationViewController;
        self.reachabilityBar.delegate = self;
    }
}

#pragma mark - tableview datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([tableView isEqual:self.tableView]) {
        return self.contactModel.sectionTitles.count + 1;
    }
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([tableView isEqual:self.tableView]) {
        if (section == 0) {
            return @"";
        }
        return self.contactModel.sectionTitles[section - 1];
    } else {
        if (self.contactModel.searchResult.count) {
            return NSLocalizedString(@"Top name matches", nil);
        }
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([tableView isEqual:self.tableView]) {
        if (section == 0) {
            return 1;
        }
        return [self.contactModel contactsAtSection:section - 1].count;
    }

    return self.contactModel.searchResult.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && [tableView isEqual:self.tableView]) {
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:ContactsTableViewMyNumberCell];
        NSString *myNumber = NSLocalizedString(@"My Number: ", nil);
        myNumber = [myNumber stringByAppendingString:self.currentUser.outgoingNumber];
        cell.textLabel.text = myNumber;
        return cell;
    }

    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:ContactsTableViewCell];

    CNContact *contact;

    if ([tableView isEqual:self.tableView]) {
        contact = [self.contactModel contactAtSection:indexPath.section - 1 index:indexPath.row];
    } else {
        contact = self.contactModel.searchResult[indexPath.row];
    }

    cell.textLabel.attributedText = [self.contactModel attributedStringFor:contact];
    return cell;
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if ([tableView isEqual:self.tableView]) {
        return self.contactModel.sectionTitles;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0 && [tableView isEqual:self.tableView]) {
        return 1.0f;
    }
    return 32.0f;
}

#pragma mark - tableview delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([tableView isEqual:self.tableView]) {
        if (indexPath.section == 0) {
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
            return;
        }
        self.selectedContact = [self.contactModel contactAtSection:indexPath.section - 1 index:indexPath.row];
    } else {
        self.selectedContact = self.contactModel.searchResult[indexPath.row];
    }

    CNContactViewController *contactViewController = [CNContactViewController viewControllerForContact:self.selectedContact];
    contactViewController.title = [CNContactFormatter stringFromContact:self.selectedContact style:CNContactFormatterStyleFullName];
    contactViewController.contactStore = self.contactModel.contactStore;
    contactViewController.allowsActions = NO;
    contactViewController.delegate = self;

    self.navigationItem.titleView = nil;
    self.showTitleImage = NO;
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
                    [VialerGAITracker setupOutgoingSIPCallEvent];
                    [self performSegueWithIdentifier:ContactsViewControllerSIPCallingSegue sender:self];
                } else if (self.reachabilityStatus == ReachabilityManagerStatusOffline) {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"No internet connection", nil)
                                                                                   message:NSLocalizedString(@"It's not possible to setup a call. Make sure you have an internet connection.", nil)
                                                                      andDefaultButtonText:NSLocalizedString(@"Ok", nil)];
                    [self presentViewController:alert animated:YES completion:nil];
                } else {
                    [VialerGAITracker setupOutgoingConnectABCallEvent];
                    [self performSegueWithIdentifier:ContactsViewControllerTwoStepCallingSegue sender:self];
                }
            });
        });
        return NO;
    }
    return YES;
}

- (void)contactViewController:(CNContactViewController *)viewController didCompleteWithContact:(CNContact *)contact {
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
    [self.contactModel searchContactsFor:searchText];
}

#pragma mark - utils

- (void)checkContactsAccess {
    if (![self.contactModel hasContactAccess]) {
        [self.contactModel requestContactAccess];
    }

    switch (self.contactModel.authorizationStatus) {
        case CNAuthorizationStatusAuthorized:
            break;
        case CNAuthorizationStatusNotDetermined:
        case CNAuthorizationStatusRestricted: {
            self.warningMessage = NSLocalizedString(@"Application not authorized to access 'Contacts'", nil);
        }
        case CNAuthorizationStatusDenied: {
            self.warningMessage = NSLocalizedString(@"Application denied access to 'Contacts'", nil);
            break;
        }
    }
}

#pragma mark - Notifications

- (void)outgoingNumberUpdated:(NSNotification *)notification {
    [self.tableView reloadData];
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

