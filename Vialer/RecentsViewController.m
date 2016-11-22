//
//  RecentsViewController.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "RecentsViewController.h"

#import "AppDelegate.h"
#import "Configuration.h"
#import "ContactsUI/ContactsUI.h"
#import "ReachabilityBarViewController.h"
#import "RecentCall.h"
#import "RecentCallManager.h"
#import "RecentTableViewCell.h"
#import "SystemUser.h"
#import "TwoStepCallingViewController.h"
#import "UIAlertController+Vialer.h"
#import "UIViewController+MMDrawerController.h"
#import "Vialer-Swift.h"

static NSString * const RecentsViewControllerTabContactImageName = @"tab-recent";
static NSString * const RecentsViewControllerTabContactActiveImageName = @"tab-recent-active";
static NSString * const RecentsViewControllerLogoImageName = @"logo";
static NSString * const RecentsViewControllerPropertyPhoneNumbers = @"phoneNumbers";

static NSString * const RecentViewControllerRecentCallCell = @"RecentCallCell";
static NSString * const RecentViewControllerCellWithErrorText = @"CellWithErrorText";
static NSString * const RecentViewControllerTwoStepCallingSegue = @"TwoStepCallingSegue";
static NSString * const RecentViewControllerSIPCallingSegue = @"SIPCallingSegue";

static CGFloat const RecentsViewControllerReachabilityBarHeight = 30.0;
static NSTimeInterval const RecentsViewControllerReachabilityBarAnimationDuration = 0.3;

@interface RecentsViewController () <UITableViewDataSource, UITableViewDelegate, CNContactViewControllerDelegate, NSFetchedResultsControllerDelegate, ReachabilityBarViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *filterControl;

@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) NSString *phoneNumberToCall;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultController;
@property (strong, nonatomic) RecentCallManager *callManager;
@property (nonatomic) ReachabilityManagerStatusType reachabilityStatus;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *reachabilityBarHeigthConstraint;
@property (weak, nonatomic) ContactModel *contactModel;
@property (weak, nonatomic) Configuration *defaultConfiguration;
@property (nonatomic) BOOL showTitleImage;
@end

@implementation RecentsViewController

#pragma mark - view lifecycle

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.title = NSLocalizedString(@"Recents", nil);
        self.tabBarItem.image = [UIImage imageNamed:RecentsViewControllerTabContactImageName];
        self.tabBarItem.selectedImage = [UIImage imageNamed:RecentsViewControllerTabContactActiveImageName];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextSaved:) name:NSManagedObjectContextDidSaveNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.showTitleImage = YES;
    [self setupLayout];

    NSError *error;
    if(![self.fetchedResultController performFetch:&error]) {
        DDLogError(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [VialerGAITracker trackScreenForControllerWithName:NSStringFromClass([self class])];
    [self.tableView reloadData];
    [self refreshRecents];
}

- (void)setupLayout {
    if (self.showTitleImage) {
        self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:RecentsViewControllerLogoImageName]];
    } else {
        self.showTitleImage = YES;
    }
    self.navigationController.view.backgroundColor = [self.defaultConfiguration.colorConfiguration colorForKey:ConfigurationNavigationBarBarTintColor];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:nil];
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
        _refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Fetching the latest recent calls from the server.", nil) attributes:nil];
        [_refreshControl addTarget:self action:@selector(refreshWithControl:) forControlEvents:UIControlEventValueChanged];
    }
    return _refreshControl;
}

- (void)setFilterControl:(UISegmentedControl *)filterControl {
    _filterControl = filterControl;
    _filterControl.tintColor = [self.defaultConfiguration.colorConfiguration colorForKey:ConfigurationRecentsFilterControlTintColor];
}

- (RecentCallManager *)callManager {
    if (!_callManager) {
        _callManager = [[RecentCallManager alloc] init];
        _callManager.mainManagedObjectContext = self.managedObjectContext;
    }
    return _callManager;
}

- (NSManagedObjectContext *)managedObjectContext {
    if (!_managedObjectContext) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _managedObjectContext.parentContext = ((AppDelegate *)[UIApplication sharedApplication].delegate).managedObjectContext;
    }
    return _managedObjectContext;
}

-(NSFetchedResultsController *)fetchedResultController {
    if (!_fetchedResultController) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"RecentCall" inManagedObjectContext:self.managedObjectContext];
        fetchRequest.entity = entity;

        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"callDate" ascending:NO];
        fetchRequest.sortDescriptors = @[sort];

        fetchRequest.fetchBatchSize = 20;

        _fetchedResultController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        _fetchedResultController.delegate = self;
    }
    return _fetchedResultController;
}

- (ContactModel *)contactModel {
    if(!_contactModel) {
        _contactModel = [ContactModel defaultModel];
    }
    return _contactModel;
}

- (Configuration *)defaultConfiguration {
    if(!_defaultConfiguration) {
        _defaultConfiguration = [Configuration defaultConfiguration];
    }
    return _defaultConfiguration;
}

#pragma mark - actions

- (IBAction)leftDrawerButtonPressed:(UIBarButtonItem *)sender {
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (IBAction)filterControlTapped:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 1) {
        self.fetchedResultController.fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K == %@ AND %K == YES", @"duration", @(0), @"inbound"];
    } else {
        self.fetchedResultController.fetchRequest.predicate = nil;
    }
    NSError *error;
    [self.fetchedResultController performFetch:&error];
    if (error) {
        DDLogError(@"Error: %@", error);
    }
    [self.tableView reloadData];
}

- (void)refreshWithControl:(UIRefreshControl *)control {
    [self refreshRecents];
}

- (void)refreshRecents {
    if (self.callManager.reloading) {
        [self.refreshControl endRefreshing];
        return;
    }
    [self.refreshControl beginRefreshing];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self.callManager getLatestRecentCallsWithCompletion:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.refreshControl endRefreshing];
                if (error && self.callManager.recentsFetchErrorCode == RecentCallManagerFetchingUserNotAllowed) {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Not allowed", nil)
                                                                                   message:[error localizedDescription]
                                                                      andDefaultButtonText:NSLocalizedString(@"Ok", nil)];
                    [self presentViewController:alert animated:YES completion:nil];
                }
            });
        }];
    });
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[TwoStepCallingViewController class]]) {
        TwoStepCallingViewController *tscvc = (TwoStepCallingViewController *)segue.destinationViewController;
        [tscvc handlePhoneNumber:self.phoneNumberToCall];
    } else if ([segue.destinationViewController isKindOfClass:[SIPCallingViewController class]]) {
        SIPCallingViewController *sipCallingVC = (SIPCallingViewController *)segue.destinationViewController;
        [sipCallingVC handleOutgoingCallWithPhoneNumber:self.phoneNumberToCall contact:nil];
    } else if ([segue.destinationViewController isKindOfClass:[ReachabilityBarViewController class]]) {
        ReachabilityBarViewController *rbvc = (ReachabilityBarViewController *)segue.destinationViewController;
        rbvc.delegate = self;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MAX([self.fetchedResultController.sections[section] numberOfObjects], 1);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Select correct recents
    if (self.callManager.recentsFetchFailed) {
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:RecentViewControllerCellWithErrorText];
        switch (self.callManager.recentsFetchErrorCode) {
            case RecentCallManagerFetchingUserNotAllowed:
                cell.textLabel.text = NSLocalizedString(@"You are not allowed to view recent calls", nil);
                break;
            default:
                cell.textLabel.text = NSLocalizedString(@"Could not load your recent calls", nil);
                break;
        }
        return cell;
    }

    if (self.fetchedResultController.fetchedObjects.count == 0) {
        NSString *noRecents;
        if (self.filterControl.selectedSegmentIndex == 0) {
            noRecents = NSLocalizedString(@"No recent calls", nil);
        } else {
            noRecents = NSLocalizedString(@"No missed calls", nil);
        }
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:RecentViewControllerCellWithErrorText];
        cell.textLabel.text = noRecents;
        return cell;
    }

    RecentTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:RecentViewControllerRecentCallCell];

    return [self configureCell:cell atIndexPath:indexPath];

}

- (RecentTableViewCell *)configureCell:(RecentTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    RecentCall *recent = (RecentCall *)[self.fetchedResultController objectAtIndexPath:indexPath];

    cell.inbound = [recent.inbound boolValue];
    cell.name = recent.displayName;
    cell.subtitle = recent.phoneType;
    cell.date = recent.callDate;
    cell.answered = !([recent.duration isEqual:@(0)] && [recent.inbound boolValue]);

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (self.fetchedResultController.fetchedObjects.count == 0) {
        return;
    }

    RecentCall *recent = [self.fetchedResultController objectAtIndexPath:indexPath];
    if ([recent suppressed]) {
        return;
    } else if ([recent.inbound boolValue]) {
        [self callPhoneNumber:recent.sourceNumber];
    } else {
        [self callPhoneNumber:recent.destinationNumber];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {

    if (self.fetchedResultController.fetchedObjects.count == 0) {
        return;
    }

    RecentCall *recent = [self.fetchedResultController objectAtIndexPath:indexPath];

    CNContactViewController *contactViewController;
    CNContact *contact;
    if ([recent suppressed]) {
        CNMutableContact *unknownContact = [[CNMutableContact alloc] init];
        unknownContact.givenName = [recent displayName];
        contactViewController = [CNContactViewController viewControllerForContact:unknownContact];
        contactViewController.allowsEditing = NO;

    } else if (recent.callerRecordID) {
        contact = [self.contactModel getContactFor:recent.callerRecordID];
        contactViewController = [CNContactViewController viewControllerForContact:contact];
        contactViewController.title = [CNContactFormatter stringFromContact:contact style:CNContactFormatterStyleFullName];
    } else {
        NSString *newPhoneNumber = [recent.inbound boolValue] ? recent.sourceNumber : recent.destinationNumber;
        CNPhoneNumber *phoneNumber = [[CNPhoneNumber alloc] initWithStringValue:newPhoneNumber];
        CNLabeledValue *phoneNumbers = [[CNLabeledValue alloc] initWithLabel:CNLabelPhoneNumberMain value: phoneNumber];
        CNMutableContact *unknownContact = [[CNMutableContact alloc] init];
        unknownContact.phoneNumbers = @[phoneNumbers];
        unknownContact.givenName = recent.callerName;

        contactViewController = [CNContactViewController viewControllerForUnknownContact:unknownContact];
        contactViewController.title = newPhoneNumber;
    }

    contactViewController.contactStore = self.contactModel.contactStore;
    contactViewController.allowsActions = NO;
    contactViewController.delegate = self;
    self.showTitleImage = NO;
    [self.navigationController pushViewController:contactViewController animated:YES];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.tableView reloadData];
}

#pragma mark - CNContactsViewControllerDelegate

- (BOOL)contactViewController:(CNContactViewController *)viewController shouldPerformDefaultActionForContactProperty:(CNContactProperty *)property {
    if ([property.key isEqualToString:RecentsViewControllerPropertyPhoneNumbers]) {
        CNPhoneNumber *phoneNumberProperty = property.value;
        NSString *phoneNumber = [phoneNumberProperty stringValue];

        /**
         *  We need to return asap to prevent default action (calling with native dialer).
         *  As a workaround, we put the presenting of the new viewcontroller via a separate queue,
         *  which will immediately go back to the main thread.
         */
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self callPhoneNumber:phoneNumber];
            });
        });
        return NO;
    }
    return YES;
}

#pragma mark - CNContactViewControllerDelegate

- (void)contactViewController:(CNContactViewController *)viewController didCompleteWithContact:(CNContact *)contact {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self refreshRecents];
}

#pragma mark - ReachabilityBarViewControllerDelegate

- (void)reachabilityBar:(ReachabilityBarViewController *)reachabilityBar statusChanged:(ReachabilityManagerStatusType)status {
    self.reachabilityStatus = status;
}

- (void)reachabilityBar:(ReachabilityBarViewController *)reachabilityBar shouldBeVisible:(BOOL)visible {
    [self.view layoutIfNeeded];
    self.reachabilityBarHeigthConstraint.constant = visible ? RecentsViewControllerReachabilityBarHeight : 0.0;
    [UIView animateWithDuration:RecentsViewControllerReachabilityBarAnimationDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - utils

- (void)callPhoneNumber:(NSString *)phoneNumber {
    self.phoneNumberToCall = phoneNumber;
    if (self.reachabilityStatus == ReachabilityManagerStatusHighSpeed && [SystemUser currentUser].sipEnabled) {
        [VialerGAITracker setupOutgoingSIPCallEvent];
        [self performSegueWithIdentifier:RecentViewControllerSIPCallingSegue sender:self];
    } else if (self.reachabilityStatus == ReachabilityManagerStatusOffline) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"No internet connection", nil)
                                                                       message:NSLocalizedString(@"It's not possible to setup a call. Make sure you have an internet connection.", nil)
                                                          andDefaultButtonText:NSLocalizedString(@"Ok", nil)];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        [VialerGAITracker setupOutgoingConnectABCallEvent];
        [self performSegueWithIdentifier:RecentViewControllerTwoStepCallingSegue sender:self];
    }
}

#pragma mark - Notifications

- (void)managedObjectContextSaved:(NSNotification *)notification {
    [self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
}

@end
