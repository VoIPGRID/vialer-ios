//
//  RecentsViewController.m
//  Vialer
//
//  Created by Bob Voorneveld on 16/11/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "RecentsViewController.h"

#import "Configuration.h"
#import "ContactModel.h"
#import "GAITracker.h"
#import "RecentCall.h"
#import "RecentCallManager.h"
#import "RecentTableViewCell.h"
#import "SIPCallingViewController.h"
#import "TwoStepCallingViewController.h"

#import "UIViewController+MMDrawerController.h"

#import "ContactsUI/ContactsUI.h"

static NSString * const RecentsViewControllerTabContactImageName = @"tab-recent";
static NSString * const RecentsViewControllerTabContactActiveImageName = @"tab-recent-active";
static NSString * const RecentsViewControllerLogoImageName = @"logo";
static NSString * const RecentsViewControllerPropertyPhoneNumbers = @"phoneNumbers";

static NSString * const RecentViewControllerRecentCallCell = @"RecentCallCell";
static NSString * const RecentViewControllerNoRecentCallCell = @"NoRecentCallsCell";
static NSString * const RecentViewControllerNoMissedRecentCallCell = @"NoMissedRecentCallsCell";

@interface RecentsViewController () <UITableViewDataSource, UITableViewDelegate, CNContactViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *filterControl;

@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) SIPCallingViewController *sipCallingViewController;
@property (strong, nonatomic) TwoStepCallingViewController *twoStepCallingViewController;

@end

@implementation RecentsViewController

#pragma mark - view lifecycle

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.title = NSLocalizedString(@"Recents", nil);
        self.tabBarItem.image = [UIImage imageNamed:RecentsViewControllerTabContactImageName];
        self.tabBarItem.selectedImage = [UIImage imageNamed:RecentsViewControllerTabContactActiveImageName];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupLayout];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [GAITracker trackScreenForControllerName:NSStringFromClass([self class])];
    [self.tableView reloadData];
    [self refreshRecents];
}

- (void)setupLayout {
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:RecentsViewControllerLogoImageName]];
}

#pragma mark - properties

- (void)setTableView:(UITableView *)tableView {
    _tableView = tableView;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [_tableView addSubview:self.refreshControl];
}

- (UIRefreshControl *)refreshControl {
    if (!_refreshControl) {
        _refreshControl = [[UIRefreshControl alloc] init];
        _refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Fetching the latstest recent calls from the server.", nil) attributes:nil];
        [_refreshControl addTarget:self action:@selector(refreshWithControl:) forControlEvents:UIControlEventValueChanged];
    }
    return _refreshControl;
}

- (void)setFilterControl:(UISegmentedControl *)filterControl {
    _filterControl = filterControl;
    _filterControl.tintColor = [Configuration tintColorForKey:ConfigurationRecentsFilterControlTintColor];
}

- (SIPCallingViewController *)sipCallingViewController {
    if (!_sipCallingViewController) {
        _sipCallingViewController = [[SIPCallingViewController alloc] init];
    }
    return _sipCallingViewController;
}

- (TwoStepCallingViewController *)twoStepCallingViewController {
    if (!_twoStepCallingViewController) {
        _twoStepCallingViewController = [[TwoStepCallingViewController alloc] init];
    }
    return _twoStepCallingViewController;
}

#pragma mark - actions

- (IBAction)leftDrawerButtonPressed:(UIBarButtonItem *)sender {
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (IBAction)filterControlTapped:(UISegmentedControl *)sender {
    [self.tableView reloadData];
}

- (void)refreshWithControl:(UIRefreshControl *)control {
    [self refreshRecents];
}

- (void)refreshRecents {
    if ([RecentCallManager defaultManager].reloading) {
        [self.refreshControl endRefreshing];
        return;
    }
    [self.refreshControl beginRefreshing];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        [[RecentCallManager defaultManager] getLatestRecentCallsWithCompletion:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.refreshControl endRefreshing];
                [self.tableView reloadData];
                if (error) {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Recent Fetch error", nil) message:NSLocalizedString(@"Unable to fetch you recent call list.", nil) preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", nil) style:UIAlertActionStyleDefault handler:nil];
                    [alert addAction:defaultAction];
                    [self presentViewController:alert animated:YES completion:nil];
                }
            });
        }];
    });
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.filterControl.selectedSegmentIndex == 0) {
        return MAX([[RecentCallManager defaultManager].recentCalls count], 1);
    } else {
        return MAX([[RecentCallManager defaultManager].missedRecentCalls count], 1);
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    // Select correct recents
    NSArray *recents;
    if (self.filterControl.selectedSegmentIndex == 0) {
        recents = [RecentCallManager defaultManager].recentCalls;
        // No recents, show other cell
        if ([recents count] == 0) {
            return [self.tableView dequeueReusableCellWithIdentifier:RecentViewControllerNoRecentCallCell];
        }
    } else {
        // No recents, show other cell
        recents = [RecentCallManager defaultManager].missedRecentCalls;
        if ([recents count] == 0) {
            return [self.tableView dequeueReusableCellWithIdentifier:RecentViewControllerNoMissedRecentCallCell];
        }
    }
    RecentTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:RecentViewControllerRecentCallCell];
    RecentCall *recent = [recents objectAtIndex:indexPath.row];
    cell.callDirection = recent.callDirection;
    cell.name = recent.callerName;
    cell.subtitle = recent.callerPhoneType;
    cell.date = recent.callDate;
    cell.answered = !(recent.atime == 0 && recent.callDirection == CallDirectionInbound);

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    RecentCall *recent;
    if (self.filterControl.selectedSegmentIndex == 0) {
        // If there are no recent calls, do nothing
        if ([[RecentCallManager defaultManager].recentCalls count] == 0) {
            return;
        }
        recent = [RecentCallManager defaultManager].recentCalls[indexPath.row];
    } else {
        // If there are no missed recent calls, do nothing
        if ([[RecentCallManager defaultManager].missedRecentCalls count] == 0) {
            return;
        }
        recent = [RecentCallManager defaultManager].missedRecentCalls[indexPath.row];
    }

    [self callPhoneNumber:recent.callerPhoneNumber];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {

    RecentCall *recent;
    if (self.filterControl.selectedSegmentIndex == 0) {
        recent = [RecentCallManager defaultManager].recentCalls[indexPath.row];
    } else {
        recent = [RecentCallManager defaultManager].missedRecentCalls[indexPath.row];
    }

    CNContactViewController *contactViewController;
    CNContact *contact = [[ContactModel defaultContactModel] getSelectedContactOnIdentifier:recent.contactIdentifier];
    if (contact) {
        contactViewController = [CNContactViewController viewControllerForContact:contact];
        contactViewController.title = [CNContactFormatter stringFromContact:contact style:CNContactFormatterStyleFullName];
    } else {
        CNPhoneNumber *phoneNumber = [[CNPhoneNumber alloc] initWithStringValue:recent.callerPhoneNumber];
        CNLabeledValue *phoneNumbers = [[CNLabeledValue alloc] initWithLabel:CNLabelPhoneNumberMain value: phoneNumber];
        CNMutableContact *unknownContact = [[CNMutableContact alloc] init];
        unknownContact.phoneNumbers = @[phoneNumbers];
        unknownContact.givenName = recent.callerId;

        contactViewController = [CNContactViewController viewControllerForUnknownContact:unknownContact];
        contactViewController.title = recent.callerPhoneNumber;
    }

    contactViewController.contactStore = [[ContactModel defaultContactModel] getContactStore];
    contactViewController.allowsActions = NO;
    contactViewController.allowsEditing = YES;
    contactViewController.delegate = self;

    [self.navigationController pushViewController:contactViewController animated:YES];
}

#pragma mark - CNContactsViewControllerDelegate

- (BOOL)contactViewController:(CNContactViewController *)viewController shouldPerformDefaultActionForContactProperty:(CNContactProperty *)property {
    if ([property.key isEqualToString:RecentsViewControllerPropertyPhoneNumbers]) {
        CNPhoneNumber *phoneNumberProperty = property.value;
        NSString *phoneNumber = [phoneNumberProperty stringValue];
        [self callPhoneNumber:phoneNumber];
        return NO;
    }
    return YES;
}

#pragma mark - CNContactViewControllerDelegate

- (void)contactViewController:(CNContactViewController *)viewController didCompleteWithContact:(CNContact *)contact {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self refreshRecents];
}

#pragma mark - utils

- (void)callPhoneNumber:(NSString *)phoneNumber {
    // TODO: implement 4g calling
    if (false) {
        [GAITracker setupOutgoingSIPCallEvent];
        [self presentViewController:self.sipCallingViewController animated:YES completion:nil];
        [self.sipCallingViewController handlePhoneNumber:phoneNumber forContact:nil];
    } else {
        [GAITracker setupOutgoingConnectABCallEvent];
        [self presentViewController:self.twoStepCallingViewController animated:YES completion:nil];
        [self.twoStepCallingViewController handlePhoneNumber:phoneNumber];
    }
}

@end
