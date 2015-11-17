//
//  ContactsViewController.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "ContactsViewController.h"

#import "AppDelegate.h"
#import "Configuration.h"
#import "ContactsUI/ContactsUI.h"
#import "ContactModel.h"
#import "ContactUtils.h"
#import "GAITracker.h"
#import "SystemUser.h"

#import "UIViewController+MMDrawerController.h"

static NSString *const ContactsViewControllerLogoImageName = @"logo";
static NSString *const ContactsViewControllerTabContactImageName = @"tab-contact";
static NSString *const ContactsViewControllerTabContactActiveImageName = @"tab-contact-active";


@interface ContactsViewController () <CNContactViewControllerDelegate, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, CNContactViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UILabel *warningMessageLabel;
@property (weak, nonatomic) IBOutlet UILabel *myPhoneNumberLabel;

@property (strong, nonatomic) NSString *warningMessage;
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
    [self checkContactsAccess];
    [self setupLayout];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [GAITracker trackScreenForControllerName:NSStringFromClass([self class])];
}

- (void)setupLayout {
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:ContactsViewControllerLogoImageName]];

    self.definesPresentationContext = YES;
    self.edgesForExtendedLayout = UIRectEdgeNone;

    self.tableView.sectionIndexColor = [Configuration tintColorForKey:ConfigurationContactsTableSectionIndexColor];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;

    self.searchBar.barTintColor = [Configuration tintColorForKey:ConfigurationContactSearchBarBarTintColor];
}

#pragma mark - properties

- (void)setMyPhoneNumberLabel:(UILabel *)myPhoneNumberLabel {
    _myPhoneNumberLabel = myPhoneNumberLabel;
    _myPhoneNumberLabel.text = [SystemUser currentUser].outgoingNumber;
}

- (void)setWarningMessage:(NSString *)warningMessage {
    if (warningMessage.length) {
        self.warningMessageLabel.hidden = NO;
        self.warningMessageLabel.text = warningMessage;
    } else {
        self.warningMessageLabel.hidden = YES;
    }
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
    CNContact *contact;

    if ([tableView isEqual:self.tableView]) {
        contact = [[ContactModel defaultContactModel] getContactsAtSection:indexPath.section andIndex:indexPath.row];
    } else {
        contact = [ContactModel defaultContactModel].searchResults[indexPath.row];
    }

    CNContactViewController *contactViewController = [CNContactViewController viewControllerForContact:contact];
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
        NSString *phoneNumber = [phoneNumberProperty stringValue];

        AppDelegate *appDelegate = ((AppDelegate *)[UIApplication sharedApplication].delegate);
        [appDelegate handlePhoneNumber:phoneNumber];
        return NO;
    }
    return YES;
}

- (void)contactViewController:(CNContactViewController *)viewController didCompleteWithContact:(CNContact *)contact {
    [self loadContacts];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - searchbar delegate

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
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), ^{
        if ([[ContactModel defaultContactModel] refreshAllContacts]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
    });
}

@end

