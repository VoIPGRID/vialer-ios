//
//  SettingsViewController.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "SettingsViewController.h"

#import "AvailabilityModel.h"
#import "AvailabilityViewController.h"
#import "EditNumberViewController.h"
#import "GAITracker.h"
#import "SettingsViewFooterView.h"
#import "SystemUser.h"
#import "VoIPGRIDRequestOperationManager.h"

#import "SVProgressHUD.h"

static int const SettingsViewControllerVoIPAccountSection = 0;
static int const SettingsViewControllerSipEnabledRow = 0;
static int const SettingsViewControllerSipAccountRow = 1;

static int const SettingsViewControllerNumbersSection = 1;
static int const SettingsViewControllerMyNumberRow = 0;
static int const SettingsViewControllerOutgoingNumberRow = 1;
static int const SettingsViewControllerMyEmailRow = 2;

static NSString * const SettingsViewControllerShowEditNumberSegue = @"ShowEditNumberSegue";

@interface SettingsViewController() <EditNumberViewControllerDelegate>
@end

@implementation SettingsViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [GAITracker trackScreenForControllerName:NSStringFromClass([self class])];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case SettingsViewControllerVoIPAccountSection: {
            // Are we allowed to show anything?
            if ([SystemUser currentUser].isAllowedToSip) {
                // Do we show all fields?
                if ([SystemUser currentUser].sipEnabled) {
                    // Sip is enabled, show all fields
                    return 2;
                }
                // Only show the enable switch
                return 1;
            }
            // Not allowed to sip, hide the content
            return 0;
        }
        case SettingsViewControllerNumbersSection:
            return 3;
        default:
            break;
    }
    // Unknown section, no items there
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *tableViewSettingsCell = @"SettingsCell";
    static NSString *tableViewSettingsWithAccessoryCell = @"SettingsWithAccessoryCell";

    UITableViewCell *cell;

    //Specific config according to cell function
    if (indexPath.section == SettingsViewControllerVoIPAccountSection) {
        if (indexPath.row == SettingsViewControllerSipEnabledRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:tableViewSettingsCell];
            cell.textLabel.text = NSLocalizedString(@"EnabledVOIPCalls", nil);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = switchView;
            [switchView setOn:[SystemUser currentUser].sipEnabled animated:NO];
            [switchView addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];

        } else if (indexPath.row == SettingsViewControllerSipAccountRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:tableViewSettingsCell];
            cell.textLabel.text = NSLocalizedString(@"SIP account", nil);
            cell.detailTextLabel.text = [SystemUser currentUser].sipAccount;
        }
    } else if (indexPath.section == SettingsViewControllerNumbersSection) {
        if (indexPath.row == SettingsViewControllerMyNumberRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:tableViewSettingsWithAccessoryCell];
            cell.textLabel.text = NSLocalizedString(@"My number", nil);
            cell.detailTextLabel.text = [SystemUser currentUser].mobileNumber;

        } else if (indexPath.row == SettingsViewControllerOutgoingNumberRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:tableViewSettingsCell];
            cell.textLabel.text = NSLocalizedString(@"Outgoing number", nil);
            cell.detailTextLabel.text = [SystemUser currentUser].outgoingNumber;

        } else if (indexPath.row == SettingsViewControllerMyEmailRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:tableViewSettingsCell];
            cell.textLabel.text = NSLocalizedString(@"Email", nil);
            cell.detailTextLabel.minimumScaleFactor = 0.8f;
            cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
            cell.detailTextLabel.text = [SystemUser currentUser].user;
        }
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    //Only the SettingsViewControllerVoIPAccountSection has gets a header.
    if (section == SettingsViewControllerVoIPAccountSection) {
        if ([SystemUser currentUser].isAllowedToSip) {
            return 35;
        }
        // Returning 0 results in the default value (10), returning 1 to minimal
        return 1;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == SettingsViewControllerVoIPAccountSection) {
        if ([SystemUser currentUser].isAllowedToSip) {
            return NSLocalizedString(@"VoIP Account", nil);
        }
        return nil;
    }
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    //The footer will be added to the last displayed section
    if (section == SettingsViewControllerNumbersSection) {
        CGRect frameOfLastRow = [tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:SettingsViewControllerOutgoingNumberRow inSection:SettingsViewControllerNumbersSection]];

        //the empty space below the last cell is the complete height of the tableview minus
        //the y position of the last row + the last rows height.
        CGRect emptyFrameBelowLastRow = CGRectMake(0, 0, self.tableView.frame.size.width,
                                                   self.tableView.frame.size.height - (frameOfLastRow.origin.y + frameOfLastRow.size.height));

        return [[SettingsViewFooterView alloc] initWithFrame:emptyFrameBelowLastRow];
    }
    return nil;
}

#pragma mark - actions

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender {
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:SettingsViewControllerShowEditNumberSegue]) {
        EditNumberViewController *editNumberController = (EditNumberViewController *)segue.destinationViewController;
        editNumberController.numberToEdit = [SystemUser currentUser].mobileNumber;
        editNumberController.delegate = self;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SettingsViewControllerNumbersSection && indexPath.row == SettingsViewControllerMyNumberRow) {
        [self performSegueWithIdentifier:SettingsViewControllerShowEditNumberSegue sender:self];
    }
}

#pragma mark - EditNumberViewControllerDelegate delegate

- (void)numberHasChanged:(NSString *)newNumber {
    //Update the tableView Cell
    UITableViewCell *myNumberCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:SettingsViewControllerMyNumberRow inSection:SettingsViewControllerNumbersSection]];
    myNumberCell.detailTextLabel.text = [SystemUser currentUser].mobileNumber;
}


#pragma mark - SIP Enabled switch handler

- (void)switchChanged:(UISwitch *)switchview {
    [SystemUser currentUser].sipEnabled = switchview.on;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SettingsViewControllerVoIPAccountSection]
                  withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
