//
//  RecentsViewController.m
//  Vialer
//
//  Created by Reinier Wieringa on 06/11/13.
//  Copyright (c) 2013 Voys. All rights reserved.
//

#import "RecentsViewController.h"
#import "VoysRequestOperationManager.h"
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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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
    [[VoysRequestOperationManager sharedRequestOperationManager].operationQueue cancelAllOperations];
    [RecentCall clearCachedRecentCalls];
    self.previousSearchDateTime = nil;
    self.recents = @[];
    [self.tableView reloadData];
}

- (void)refreshRecents {
    if (![[VoysRequestOperationManager sharedRequestOperationManager] isLoggedIn]) {
        return;
    }

    if (!self.previousSearchDateTime || [[NSDate date] timeIntervalSinceDate:self.previousSearchDateTime] > 60) {
        self.previousSearchDateTime = [NSDate date];
        
        // Retrieve recent calls from last month
        NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
        [offsetComponents setMonth:-1];
        NSDate *lastMonth = [[NSCalendar currentCalendar] dateByAddingComponents:offsetComponents toDate:[NSDate date] options:0];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0ul), ^{
            NSString *sourceNumber = nil;
            RecentsFilter filter = [[[NSUserDefaults standardUserDefaults] objectForKey:@"RecentsFilter"] integerValue];
            if (filter == RecentsFilterSelf) {
                sourceNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"MobileNumber"];
            }
            [[VoysRequestOperationManager sharedRequestOperationManager] cdrRecordWithLimit:50 offset:0 sourceNumber:sourceNumber callDateGte:lastMonth success:^(AFHTTPRequestOperation *operation, id responseObject) {
                if ([[VoysRequestOperationManager sharedRequestOperationManager] isLoggedIn]) {
                    self.recents = [RecentCall recentCallsFromDictionary:responseObject];
                }
                [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                if (error.code != -999 && [operation.response statusCode] != kVoysHTTPBadCredentials) {
                    NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(@"Failed to fetch your recent calls.\n%@", nil), [error localizedDescription]];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry!", nil) message:errorMessage delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
                    [alert show];
                }
            }];
        });
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
        cell.textLabel.text = NSLocalizedString(@"Loading...", nil);
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
    }
    cell.nameLabel.text = recent.callerName;
    cell.descriptionLabel.text = recent.callerPhoneType;
    cell.dateTimeLabel.text = [recent.callDate relativeDayTimeString];
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

@end
