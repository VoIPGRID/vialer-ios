//
//  RecentsViewController.m
//  Vialer
//
//  Created by Reinier Wieringa on 06/11/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "RecentsViewController.h"
#import "VoIPGRIDRequestOperationManager.h"
#import "RecentCall.h"
#import "RecentTableViewCell.h"
#import "NSDate+RelativeDate.h"
#import "AppDelegate.h"
#import "ContactsViewController.h"
#import "SettingsViewController.h"
#import "SelectRecentsFilterViewController.h"

#import "SVProgressHUD.h"

#import <AddressBookUI/AddressBookUI.h>

@interface RecentsViewController ()
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (assign) BOOL reloading;
@property (assign) BOOL unauthorized;
@property (nonatomic, strong) NSArray *recents;
@property (nonatomic, strong) NSDate *previousSearchDateTime;
@end

@implementation RecentsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Recents", nil);
        self.tabBarItem.image = [UIImage imageNamed:@"recents"];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]]];

        self.recents = [RecentCall cachedRecentCalls];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recentsFilterUpdatedNotification:) name:RECENTS_FILTER_UPDATED_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginFailedNotification:) name:LOGIN_FAILED_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginSucceededNotification:) name:LOGIN_SUCCEEDED_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f) {
        NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"]];
        NSAssert(config != nil, @"Config.plist not found!");

        NSArray *tableTintColor = [[config objectForKey:@"Tint colors"] objectForKey:@"Table"];
        NSAssert(tableTintColor != nil && tableTintColor.count == 3, @"Tint colors - Table not found in Config.plist!");
        self.tableView.tintColor = [UIColor colorWithRed:[tableTintColor[0] intValue] / 255.f green:[tableTintColor[1] intValue] / 255.f blue:[tableTintColor[2] intValue] / 255.f alpha:1.f];
    }

    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    [refresh addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refresh;

    [self.tableView addSubview:self.refreshControl];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self refreshRecents];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)clearRecents {
    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager].operationQueue cancelAllOperations];
    [RecentCall clearCachedRecentCalls];
    self.previousSearchDateTime = nil;
    @synchronized(self.recents) {
        self.recents = @[];
    }
    [self.tableView reloadData];
}

- (void)refresh {
    if (![VoIPGRIDRequestOperationManager isLoggedIn]) {
        return;
    }

    if (self.reloading) {
        return;
    }

    self.previousSearchDateTime = [NSDate date];

    // Retrieve recent calls from last month
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    [offsetComponents setMonth:-1];
    NSDate *lastMonth = [[NSCalendar currentCalendar] dateByAddingComponents:offsetComponents toDate:[NSDate date] options:0];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0ul), ^{
        NSString *sourceNumber = nil;
        RecentsFilter filter = RecentsFilterNone;//[[[NSUserDefaults standardUserDefaults] objectForKey:@"RecentsFilter"] integerValue];
        if (filter == RecentsFilterSelf) {
            sourceNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"MobileNumber"];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            self.reloading = YES;
            [self.refreshControl beginRefreshing];
        });

        [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] cdrRecordWithLimit:50 offset:0 sourceNumber:sourceNumber callDateGte:lastMonth success:^(AFHTTPRequestOperation *operation, id responseObject) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.unauthorized = NO;
                self.reloading = NO;
                [self.refreshControl endRefreshing];

                if ([VoIPGRIDRequestOperationManager isLoggedIn]) {
                    @synchronized(self.recents) {
                        self.recents = [RecentCall recentCallsFromDictionary:responseObject];
                    }
                }
                [self.tableView reloadData];
            });
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.reloading = NO;
                [self.refreshControl endRefreshing];

                if ([operation.response statusCode] == kVoIPGRIDHTTPBadCredentials) {
                    // No permissions
                    self.unauthorized = YES;
                    [self.tableView reloadData];
                } else if (error.code != -999) {
                    NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(@"Failed to fetch your recent calls.", nil)];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry!", nil) message:errorMessage delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
                    [alert show];
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

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.recents.count == 0) {
        return 1;
    }
    return self.recents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.recents.count == 0) {
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
                                NSLocalizedString(@"No recent calls", nil)));
        return cell;
    }

    static NSString *CellIdentifier = @"RecentTableViewCell";

    RecentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[RecentTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }

    RecentCall *recent = [self.recents objectAtIndex:indexPath.row];
    if (recent.callDirection == CallDirectionOutbound) {
        cell.iconImageView.image = [UIImage imageNamed:@"outbound"];
    } else {
        cell.iconImageView.image = nil;
    }
    cell.nameLabel.text = recent.callerName;
    cell.descriptionLabel.text = recent.callerPhoneType;
    cell.dateTimeLabel.text = [recent.callDate relativeDayTimeString];

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

    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    ABRecordRef person = nil;
    if (recent.callerRecordId >= 0) {
        person = ABAddressBookGetPersonWithRecordID(addressBook, recent.callerRecordId);
    }

    if (person) {
        ABPersonViewController *personViewController = [[ABPersonViewController alloc] init];
        personViewController.personViewDelegate = self;
        personViewController.displayedPerson = person;
        personViewController.addressBook = addressBook;
        personViewController.allowsEditing = NO;
        [self.navigationController pushViewController:personViewController animated:YES];
    } else if (recent.callerPhoneNumber.length) {
        person = ABPersonCreate();

        CFErrorRef error = nil;
        ABMutableMultiValueRef phoneNumberMultiValue = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        ABMultiValueAddValueAndLabel(phoneNumberMultiValue, (__bridge CFTypeRef)(recent.callerPhoneNumber), kABPersonPhoneMainLabel, NULL);
        ABRecordSetValue(person, kABPersonPhoneProperty, phoneNumberMultiValue, &error);

        ABUnknownPersonViewController *unknownPersonViewController = [[ABUnknownPersonViewController alloc] init];
        unknownPersonViewController.unknownPersonViewDelegate = self;
        unknownPersonViewController.displayedPerson = person;
        unknownPersonViewController.addressBook = addressBook;
        [self.navigationController pushViewController:unknownPersonViewController animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    [self tableView:tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath];
}

#pragma mark - Person view controller delegate

- (BOOL)personViewController:(ABPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    // Delegate to the contacts view controller handler
    AppDelegate *appDelegate = ((AppDelegate *)[UIApplication sharedApplication].delegate);
    return [appDelegate handlePerson:person property:property identifier:identifier];
}

#pragma mark - Unknown person view controller delegate

- (BOOL)unknownPersonViewController:(ABUnknownPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    return [self personViewController:nil shouldPerformDefaultActionForPerson:person property:property identifier:identifier];
}

- (void)unknownPersonViewController:(ABUnknownPersonViewController *)personViewController didResolveToPerson:(ABRecordRef)person {
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

@end
