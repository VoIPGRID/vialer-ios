//
//  RecentsViewController.m
//  Vialer
//
//  Created by Reinier Wieringa on 06/11/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "RecentsViewController.h"

#import "AppDelegate.h"
#import "ContactsViewController.h"
#import "ContactModel.h"
#import "NSDate+RelativeDate.h"
#import "RecentCall.h"
#import "RecentTableViewCell.h"
#import "SelectRecentsFilterViewController.h"
#import "SystemUser.h"
#import "UIViewController+MMDrawerController.h"
#import "GAITracker.h"
#import "VoIPGRIDRequestOperationManager.h"

#import "SVProgressHUD.h"

static NSString *const RecentsViewControllerTabContactImageName = @"tab-recent";
static NSString *const RecentsViewControllerTabContactActiveImageName = @"tab-recent-active";
static NSString *const RecentsViewControllerLogoImageName = @"logo";
static NSString *const RecentsViewControllerMenuImageName = @"menu";
static NSString *const RecentsViewControllerOutbound = @"outbound";
static NSString *const RecentsViewControllerTransparentPixel = @"TransparentPixel";
static NSString *const RecentsViewControllerPropertyPhoneNumbers = @"phoneNumbers";

@interface RecentsViewController ()
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) UIBarButtonItem *leftDrawerButton;

@property (assign) BOOL reloading;
@property (assign) BOOL unauthorized;
@property (nonatomic, strong) NSArray *recents;
@property (nonatomic, strong) NSArray *missedRecents;
@property (nonatomic, strong) NSDate *previousSearchDateTime;
@property (nonatomic, assign) NSTimeInterval lastRecentsFailure;
@property (nonatomic, strong) RecentCall *recentCall;
@property (nonatomic, strong) ContactModel *contactModel;
@end

@implementation RecentsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Recents", nil);
        self.tabBarItem.image = [UIImage imageNamed:RecentsViewControllerTabContactImageName];
        self.tabBarItem.selectedImage = [UIImage imageNamed:RecentsViewControllerTabContactActiveImageName];
        self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:RecentsViewControllerLogoImageName]];
        // Add hamburger menu on navigation bar
        UIBarButtonItem *leftDrawerButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:RecentsViewControllerMenuImageName] style:UIBarButtonItemStylePlain target:self action:@selector(leftDrawerButtonPress:)];
        leftDrawerButton.tintColor = [Configuration tintColorForKey:ConfigurationLeftDrawerButtonTintColor];
        self.navigationItem.leftBarButtonItem = leftDrawerButton;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupLayout];
}

- (void)setupLayout {
    self.tableView.tintColor = [Configuration tintColorForKey:ConfigurationRecentsTableViewTintColor];

    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    [refresh addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refresh;

    [self.tableView addSubview:self.refreshControl];

    [self.filterSegmentedControl setTitle:NSLocalizedString(@"All", nil) forSegmentAtIndex:0];
    [self.filterSegmentedControl setTitle:NSLocalizedString(@"Missed", nil) forSegmentAtIndex:1];

    self.navigationItem.leftBarButtonItem = self.leftDrawerButton;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [GAITracker trackScreenForControllerName:NSStringFromClass([self class])];

    self.recents = [RecentCall cachedRecentCalls];
    self.missedRecents = [self filterMissedRecents:self.recents];
    
    self.filterSegmentedControl.tintColor = [Configuration tintColorForKey:ConfigurationRecentsSegmentedControlTintColor];

    // ExtendedNavBarView will draw its own hairline.
    [self.navigationController.navigationBar setShadowImage:[UIImage imageNamed:RecentsViewControllerTransparentPixel]];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //I do not know why this controller wants to be notified about these events, I've moved them from initWithNibName to here to avoid unececarry API calls.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recentsFilterUpdatedNotification:) name:RECENTS_FILTER_UPDATED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginFailedNotification:) name:LOGIN_FAILED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginSucceededNotification:) name:LOGIN_SUCCEEDED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [self refreshRecents];
}

- (void)viewDidDisappear:(BOOL)animated {    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RECENTS_FILTER_UPDATED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LOGIN_FAILED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LOGIN_SUCCEEDED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark - properties

- (UIBarButtonItem *)leftDrawerButton {
    if (!_leftDrawerButton) {
        _leftDrawerButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:RecentsViewControllerMenuImageName]
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(leftDrawerButtonPress:)];
        _leftDrawerButton.tintColor = [Configuration tintColorForKey: ConfigurationLeftDrawerButtonTintColor];
    }
    return _leftDrawerButton;
}

- (ContactModel *)contactModel {
    if (!_contactModel) {
        _contactModel = [[ContactModel alloc] init];
    }
    return _contactModel;
}

- (RecentCall *)recentCall {
    if (!_recentCall) {
        _recentCall = [[RecentCall alloc] init];
    }
    return _recentCall;
}

- (void)clearRecents {
    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager].operationQueue cancelAllOperations];
    [RecentCall clearCachedRecentCalls];
    self.previousSearchDateTime = nil;
    @synchronized(self.recents) {
        self.recents = @[];
        self.missedRecents = @[];
    }
    [self.tableView reloadData];
}

- (void)refresh {
    if (![SystemUser currentUser].isLoggedIn) {
        return;
    }

    if (self.reloading) {
        return;
    }

    // Retrieve recent calls from last month
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    [offsetComponents setMonth:-1];
    NSDate *lastMonth = [[NSCalendar currentCalendar] dateByAddingComponents:offsetComponents toDate:[NSDate date] options:0];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0ul), ^{
        NSString *sourceNumber = nil;
        RecentsFilter filter = RecentsFilterNone;
        if (filter == RecentsFilterSelf) {
            sourceNumber = [SystemUser currentUser].outgoingNumber;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            self.reloading = YES;
            [self.refreshControl beginRefreshing];
            [self.tableView setContentOffset:CGPointMake(0, -CGRectGetHeight(self.refreshControl.frame)) animated:YES];
        });

        [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] cdrRecordWithLimit:50 offset:0 sourceNumber:sourceNumber callDateGte:lastMonth success:^(AFHTTPRequestOperation *operation, id responseObject) {
            dispatch_async(dispatch_get_main_queue(), ^{
                // Register the time when we had a succesfull retrieval
                self.lastRecentsFailure = 0;
                self.previousSearchDateTime = [NSDate date];
                self.unauthorized = NO;
                self.reloading = NO;
                [self.tableView setContentOffset:CGPointZero animated:YES];
                [self.refreshControl endRefreshing];

                if ([SystemUser currentUser].isLoggedIn) {
                    @synchronized(self.recents) {
                        self.recents = [RecentCall recentCallsFromDictionary:responseObject];
                        self.missedRecents = [self filterMissedRecents:self.recents];
                    }
                }
                [self.tableView reloadData];
            });
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.reloading = NO;
                [self.tableView setContentOffset:CGPointZero animated:YES];
                [self.refreshControl endRefreshing];

                if ([operation.response statusCode] == VoIPGRIDHttpErrorsUnauthorized) {
                    // No permissions
                    self.unauthorized = YES;
                    [self.tableView reloadData];
                } else if (error.code != -999) {
                    // Check if we last shown this warning more than 30 minutes ago.
                    if ([NSDate timeIntervalSinceReferenceDate] - self.lastRecentsFailure > 1800) {
                        // Register this new time
                        self.lastRecentsFailure = [NSDate timeIntervalSinceReferenceDate];
                        // Show a warning to the user
                        NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(@"Failed to fetch your recent calls.", nil)];
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry!", nil) message:errorMessage delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
                        [alert show];
                    }
                    [self.tableView reloadData];
                    // Let's retry automatically in 5 minutes.
                    [self performSelector:@selector(refreshRecents) withObject:nil afterDelay:300];
                }
            });
        }];
    });
}

- (void)refreshRecents {
    if (self.reloading) {
        // Don't reload twice
        return;
    }

    if (!self.previousSearchDateTime || [[NSDate date] timeIntervalSinceDate:self.previousSearchDateTime] > 60) {
        [self refresh];
    }
}

- (NSArray *)filterMissedRecents:(NSArray *)recents {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(atime == 0) AND (callDirection == 0)"];
    return [recents filteredArrayUsingPredicate:predicate];
}

- (void)leftDrawerButtonPress:(id)sender{
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *recents = self.filterSegmentedControl.selectedSegmentIndex == 0 ? self.recents : self.missedRecents;
    if (recents.count == 0) {
        return 1;
    }
    return recents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *recents = self.filterSegmentedControl.selectedSegmentIndex == 0 ? self.recents : self.missedRecents;
    if (recents.count == 0) {
        static NSString *CellIdentifier = @"LoadingTableViewCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.font = [UIFont systemFontOfSize:17.f];
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.text = (self.unauthorized ? NSLocalizedString(@"No access to the recent calls", nil) :
                               (self.reloading ? NSLocalizedString(@"Loading...", nil) :
                                (self.lastRecentsFailure != 0 ? NSLocalizedString(@"Failed to fetch your recent calls.\nPull down to refresh", nil) :
                                NSLocalizedString(@"No recent calls", nil))));
        return cell;
    }

    static NSString *CellIdentifier = @"RecentTableViewCell";

    RecentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[RecentTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }

    RecentCall *recent = [recents objectAtIndex:indexPath.row];
    if (recent.callDirection == CallDirectionOutbound) {
        cell.iconImageView.image = [UIImage imageNamed:RecentsViewControllerOutbound];
    } else {
        cell.iconImageView.image = nil;
    }
    cell.nameLabel.text = recent.callerName;
    cell.descriptionLabel.text = recent.callerPhoneType;
    if (recent.callDate) {
        cell.dateTimeLabel.text = [[NSDate dateFromString:recent.callDate] relativeDayTimeString];
    }

    // Check if call was answered or not
    if (recent.atime == 0 && recent.callDirection == CallDirectionInbound) {
        cell.nameLabel.textColor = [UIColor colorWithRed:0xff / 255.f green:0x3b / 255.f blue:0x30 / 255.f alpha:1.f];
    } else {
        cell.nameLabel.textColor = [UIColor blackColor];
    }

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f) {
        [cell setAccessoryType:UITableViewCellAccessoryDetailButton];
    } else {
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    }

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.row >= self.recents.count) {
        return;
    }

    RecentCall *recent = [self.recents objectAtIndex:indexPath.row];

    AppDelegate *appDelegate = ((AppDelegate *)[UIApplication sharedApplication].delegate);
    [appDelegate handlePhoneNumber:recent.callerPhoneNumber];

}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {

    RecentCall *recent = [self.recents objectAtIndex:indexPath.row];

    CNContact *contact = [self.contactModel getSelectedContactOnIdentifier:recent.contactIdentifier];
    CNContactViewController *contactViewController;
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

    contactViewController.contactStore = [self.contactModel getContactStore];
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

        AppDelegate *appDelegate = ((AppDelegate *)[UIApplication sharedApplication].delegate);
        [appDelegate handlePhoneNumber:phoneNumber];

        return YES;
    }
    return NO;
}

#pragma mark - Notifications

- (void)didBecomeActiveNotification:(NSNotification *)notification {
    self.previousSearchDateTime = nil;
    [self refreshRecents];
}

- (void)loginSucceededNotification:(NSNotification *)notification {
    self.previousSearchDateTime = nil;
    [self refreshRecents];
}

- (void)loginFailedNotification:(NSNotification *)notification {
    [self clearRecents];
    [self refreshRecents];
}

- (void)recentsFilterUpdatedNotification:(NSNotification *)notification {
    [self clearRecents];
    [self refreshRecents];
}

- (void)dealloc {
    // Remove self as observer
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)segmentedControlValueChanged:(UISegmentedControl *)sender {
    [self.tableView reloadData];
}

@end
