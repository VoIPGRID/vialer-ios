//
//  AvailabilityViewController.m
//  Vialer
//
//  Created by Redmer Loen on 15-09-15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "AvailabilityViewController.h"

#import "AvailabilityModel.h"
#import "GAITracker.h"
#import "VoIPGRIDRequestOperationManager.h"

#import "SVProgressHUD.h"

@interface AvailabilityViewController()
@property (nonatomic, weak) NSIndexPath *lastSelected;
@property (nonatomic, strong) AvailabilityModel *availabilityModel;
@end

@implementation AvailabilityViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [GAITracker trackScreenForControllerName:NSStringFromClass([self class])];
    [self loadUserDestinations];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.tintColor = [Configuration tintColorForKey:ConfigurationAvailabilityTableViewTintColor];
    self.navigationItem.title = NSLocalizedString(@"Availability", nil);
}

- (UIRefreshControl *)refreshControl {
    UIRefreshControl *refreshControl = [super refreshControl];
    if (!refreshControl) {
        self.refreshControl = [[UIRefreshControl alloc] init];
        self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString: NSLocalizedString(@"Loading availability options...", nil)];
        [self.refreshControl addTarget:self action:@selector(loadUserDestinations) forControlEvents:UIControlEventValueChanged];
    }
    return [super refreshControl];
}

- (AvailabilityModel *)availabilityModel {
    if (_availabilityModel == nil) {
        _availabilityModel = [[AvailabilityModel alloc] init];
    }
    return _availabilityModel;
}

- (void)loadUserDestinations {
    [self.refreshControl beginRefreshing];

    [self.availabilityModel getUserDestinations:^(NSString *localizedErrorString) {
        [self.refreshControl endRefreshing];
        if (localizedErrorString) {
            [self presentAlertControllerWithErrorString:localizedErrorString];
        }else{
            [self.tableView reloadData];
        }
    }];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.availabilityModel countAvailabilityOptions];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *DefaultCellIdentifier = @"AvailabilityTableViewDefaultCell";
    static NSString *SubtitleCellIdentifier = @"AvailabilityTableViewSubtitleCell";
    NSDictionary *availabilityDict = [self.availabilityModel getAvailabilityAtIndex:indexPath.row];

    UITableViewCell *cell;
    if ([[availabilityDict objectForKey:kAvailabilityPhoneNumber] isEqualToNumber:@0]){
        cell = [self.tableView dequeueReusableCellWithIdentifier:DefaultCellIdentifier];
        cell.textLabel.text = [availabilityDict objectForKey:kAvailabilityDescription];
    } else {
        cell = [self.tableView dequeueReusableCellWithIdentifier:SubtitleCellIdentifier];
        cell.textLabel.text = [availabilityDict objectForKey:kAvailabilityDescription];
        cell.detailTextLabel.text = [[availabilityDict objectForKey:kAvailabilityPhoneNumber] stringValue];
    }

    if ([[availabilityDict objectForKey:kAvailabilitySelected] isEqualToNumber:@1]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.lastSelected = indexPath;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView cellForRowAtIndexPath:self.lastSelected].accessoryType = UITableViewCellAccessoryNone;
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;

    if (indexPath.row >= [self.availabilityModel countAvailabilityOptions]) {
        return;
    }
    self.lastSelected = indexPath;

    [SVProgressHUD showWithStatus:NSLocalizedString(@"SAVING_AVAILABILITY...", nil) maskType:SVProgressHUDMaskTypeGradient];
    [self.availabilityModel saveUserDestination:self.lastSelected.row withCompletion:^(NSString *localizedErrorString) {
        [SVProgressHUD dismiss];
        if (localizedErrorString) {
            [self presentAlertControllerWithErrorString:localizedErrorString];
        } else {
            [self.delegate availabilityHasChanged];
            [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
        }
    }];
}

- (void)presentAlertControllerWithErrorString:(NSString *)errorString {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:errorString preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", nil) style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender {
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}
@end
