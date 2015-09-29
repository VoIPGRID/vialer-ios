//
//  AvailabilityViewController.m
//  Vialer
//
//  Created by Redmer Loen on 15-09-15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"
#import "SVProgressHUD.h"

#import "AvailabilityViewController.h"
#import "AvailabilityModel.h"
#import "VoIPGRIDRequestOperationManager.h"

@interface AvailabilityViewController()
@property (nonatomic, weak) NSIndexPath *lastSelected;
@property (nonatomic, strong) AvailabilityModel *availabilityModel;
@end

@implementation AvailabilityViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:[NSStringFromClass([self class]) stringByReplacingOccurrencesOfString:@"ViewController" withString:@""]];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];

    [self loadUserDestinations];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.tintColor = [Configuration tintColorForKey:kTintColorTable];

    self.navigationItem.title = NSLocalizedString(@"Availability", nil);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed)];
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
        if (localizedErrorString != nil) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                            message:localizedErrorString
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                                  otherButtonTitles:nil];
            [alert show];
        }else{
            [self.refreshControl endRefreshing];
            [self.tableView reloadData];
        }
    }];
}

- (void)saveButtonPressed {
    [SVProgressHUD showWithStatus:NSLocalizedString(@"SAVING_AVAILABILITY...", nil) maskType:SVProgressHUDMaskTypeGradient];
    [self.availabilityModel saveUserDestination:self.lastSelected.row withCompletion:^(NSString *localizedErrorString) {
        if (localizedErrorString != nil) {
            [SVProgressHUD dismiss];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                            message:localizedErrorString
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                                  otherButtonTitles:nil];
            [alert show];
        } else {
            [self.delegate availabilityHasChanged];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.availabilityModel countAvailabilityOptions];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"AvailabilityTableViewCell";
    NSDictionary *availabilityDict = [self.availabilityModel getAvailabilityAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }

    if ([[availabilityDict objectForKey:kAvailabilityPhoneNumber] isEqualToNumber:@0]){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.textLabel.text = [availabilityDict objectForKey:kAvailabilityDescription];
    } else {
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
}

@end
