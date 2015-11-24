//
//  SettingsViewController.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "SettingsViewController.h"

#import "AvailabilityModel.h"
#import "AvailabilityViewController.h"
#import "EditNumberTableViewController.h"
#import "GAITracker.h"
#import "SettingsViewFooterView.h"
#import "SystemUser.h"
#import "VoIPGRIDRequestOperationManager.h"

#import "SVProgressHUD.h"

#define AVAILABILITY_SECTION 0
#define AVAILABILITY_ROW 0

#define VOIP_ACCOUNT_SECTION 1
#define SIP_ENABLED_ROW 0
#define SIP_ACCOUNT_ROW 1

#define NUMBERS_SECTION 2
#define MY_NUMBER_ROW 0
#define OUTGOING_NUMBER_ROW 1

@interface SettingsViewController() <EditNumberDelegate>
@end

@implementation SettingsViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [GAITracker trackScreenForControllerName:NSStringFromClass([self class])];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case VOIP_ACCOUNT_SECTION:
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
        case NUMBERS_SECTION:
            return 2;
        default:
            break;
    }
    // Unknown section, no items there
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //2 types of cells are used by this tableView
    static NSString *tableViewCellStyleValue1Identifier = @"UITableViewCellStyleValue1";

    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:tableViewCellStyleValue1Identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:tableViewCellStyleValue1Identifier];
    }

    //Specific config according to cell function
    if (indexPath.section == VOIP_ACCOUNT_SECTION) {
        if (indexPath.row == SIP_ENABLED_ROW) {
            cell.textLabel.text = NSLocalizedString(@"EnabledVOIPCalls", nil);
            cell.detailTextLabel.text = nil;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = switchView;
            [switchView setOn:[SystemUser currentUser].sipEnabled animated:NO];
            [switchView addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        }
        if (indexPath.row == SIP_ACCOUNT_ROW) {
            cell.textLabel.text = NSLocalizedString(@"SIP account", nil);
            cell.detailTextLabel.text = [SystemUser currentUser].sipAccount;
            cell.accessoryView = nil;
        }
    } else if (indexPath.section == NUMBERS_SECTION) {
        if (indexPath.row == MY_NUMBER_ROW) {
            cell.textLabel.text = NSLocalizedString(@"My number", nil);
            cell.detailTextLabel.text = [SystemUser currentUser].mobileNumber;
            cell.accessoryView = nil;
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];

        } else if (indexPath.row == OUTGOING_NUMBER_ROW) {
            cell.textLabel.text = NSLocalizedString(@"Outgoing number", nil);
            cell.detailTextLabel.text = [SystemUser currentUser].outgoingNumber;
            cell.accessoryView = nil;
        }
    }

    //Common properties for all cells
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.font = [UIFont systemFontOfSize:15];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:15];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    //Only the VOIP_ACCOUNT_SECTION has gets a header.
    if (section == VOIP_ACCOUNT_SECTION) {
        if ([SystemUser currentUser].isAllowedToSip) {
            return 35;
        }
        // Returning 0 results in the default value (10), returning 1 to minimal
        return 1;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == VOIP_ACCOUNT_SECTION) {
        if ([SystemUser currentUser].isAllowedToSip) {
            return NSLocalizedString(@"VoIP Account", nil);
        }
        return nil;
    }
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    //The footer will be added to the last displayed section
    if (section == NUMBERS_SECTION) {
        CGRect frameOfLastRow = [tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:OUTGOING_NUMBER_ROW inSection:NUMBERS_SECTION]];

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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == NUMBERS_SECTION && indexPath.row == MY_NUMBER_ROW) {

        EditNumberTableViewController *editNumberController = [[EditNumberTableViewController alloc] initWithNibName:@"EditNumberTableViewController" bundle:[NSBundle mainBundle]];
        editNumberController.numberToEdit = [SystemUser currentUser].mobileNumber;
        editNumberController.delegate = self;
        [self.navigationController pushViewController:editNumberController animated:YES];
    }
}

#pragma mark - Editnumber delegate

- (void)numberHasChanged:(NSString *)newNumber {
    //Update the tableView Cell
    UITableViewCell *myNumberCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:MY_NUMBER_ROW inSection:NUMBERS_SECTION]];
    myNumberCell.detailTextLabel.text = [SystemUser currentUser].mobileNumber;
}


#pragma mark - SIP Enabled switch handler

- (void)switchChanged:(UISwitch *)switchview {
    [SystemUser currentUser].sipEnabled = switchview.on;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:VOIP_ACCOUNT_SECTION]
                  withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
