//
//  SettingsViewController.m
//  Vialer
//
//  Created by Harold on 18/06/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "SettingsViewController.h"
#import "SystemUser.h"
#import "SettingsViewFooterView.h"
#import "EditNumberTableViewController.h"
#import "UIAlertView+Blocks.h"

#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"

@interface SettingsViewController ()

@property (nonatomic, weak) SystemUser *currentUser;

@end

@implementation SettingsViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:[NSStringFromClass([self class]) stringByReplacingOccurrencesOfString:@"ViewController" withString:@""]];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

// Override to get the SystemUser instance only once
- (SystemUser *)currentUser {
    // Only retrieve the currentUser once
    if (_currentUser == nil) {
        _currentUser = [SystemUser currentUser];
    }
    return _currentUser;
}

#pragma mark - Table view data source

//To enable the logout button,
//- change number of sections to 3
//- change LOGOUT_BUTTON_SECTION to 1
//- change NUMBERS_SECTION to 2

#define VOIP_ACCOUNT_SECTION 0
#define SIP_ENABLED_ROW 0
#define SIP_ACCOUNT_ROW 1
#define SIP_PASSWORD_ROW 2

#define LOGOUT_BUTTON_SECTION 99 //unused should be 1
#define LOGOUT_BUTTON_ROW 0

#define NUMBERS_SECTION 1 //was 2
#define MY_NUMBER_ROW 0
#define OUTGOING_NUMBER_ROW 1

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2; //3 if you want to display the logout button
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case VOIP_ACCOUNT_SECTION:
            // Are we allowed to show anything?
            if (self.currentUser.isAllowedToSip) {
                // Do we show all fields?
                if (self.currentUser.sipEnabled) {
                    // Sip is enabled, show all fields
                    return 3;
                }
                // Only show the enable switch
                return 1;
            }
            // Not allowed to sip, hide the content
            return 0;
        case LOGOUT_BUTTON_SECTION:
            return 1;
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
    static NSString *tableViewCellStyleDefault = @"UITableViewCellStyleDefault";
    
    UITableViewCell *cell;

    //Specific config according to cell function
    if (indexPath.section == VOIP_ACCOUNT_SECTION) {
        if (!(cell = [tableView dequeueReusableCellWithIdentifier:tableViewCellStyleValue1Identifier]))
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:tableViewCellStyleValue1Identifier];
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
        } else if (indexPath.row == SIP_PASSWORD_ROW) {
            cell.textLabel.text = NSLocalizedString(@"Password", nil);
            cell.detailTextLabel.text = [SystemUser currentUser].sipPassword;
            cell.accessoryView = nil;
        }
        
    } else if (indexPath.section == NUMBERS_SECTION) {
        if (!(cell = [tableView dequeueReusableCellWithIdentifier:tableViewCellStyleValue1Identifier]))
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:tableViewCellStyleValue1Identifier];
        if (indexPath.row == MY_NUMBER_ROW) {
            cell.textLabel.text = NSLocalizedString(@"My number", nil);
            cell.detailTextLabel.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"MobileNumber"];
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];

        } else if (indexPath.row == OUTGOING_NUMBER_ROW) {
            cell.textLabel.text = NSLocalizedString(@"Outgoing number", nil);
            cell.detailTextLabel.text = [SystemUser currentUser].outgoingNumber;
            cell.accessoryView = nil;
        }
        
    }  else if (indexPath.section == LOGOUT_BUTTON_SECTION) {
        if (!(cell = [tableView dequeueReusableCellWithIdentifier:tableViewCellStyleDefault]))
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableViewCellStyleDefault];
        cell.textLabel.text = NSLocalizedString(@"Logout", nil);
        cell.textLabel.textColor = [UIColor redColor];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
    }
    
    //Common properties for all cells
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.font = [UIFont systemFontOfSize:15];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:15];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    //Only the VOIP_ACCOUNT_SECTION has gets a header.
    if (section == VOIP_ACCOUNT_SECTION
        && self.currentUser.isAllowedToSip) {
        return 35;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == VOIP_ACCOUNT_SECTION) {
        if (self.currentUser.isAllowedToSip) {
            return NSLocalizedString(@"VoIP Account", nil);
        }
        return nil;
    }
    return @"";
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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == LOGOUT_BUTTON_SECTION && indexPath.row == LOGOUT_BUTTON_ROW) {
        [[SystemUser currentUser] logout];
        [self.tableView reloadData];
    } else if (indexPath.section == NUMBERS_SECTION && indexPath.row == MY_NUMBER_ROW){
        
        EditNumberTableViewController *editNumberController = [[EditNumberTableViewController alloc] initWithNibName:@"EditNumberTableViewController" bundle:[NSBundle mainBundle]];
        editNumberController.numberToEdit = [[NSUserDefaults standardUserDefaults] objectForKey:@"MobileNumber"];
        editNumberController.delegate = self;
        [self.navigationController pushViewController:editNumberController animated:YES];
    }
}

#pragma mark - Editnumber delegate

- (void)numberHasChanged:(NSString *)newNumber {
    //Update the tableView Cell
    UITableViewCell *myNumberCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:MY_NUMBER_ROW inSection:NUMBERS_SECTION]];
    myNumberCell.detailTextLabel.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"MobileNumber"];
}

#pragma mark - SIP Enabled switch handler

- (void)switchChanged:(UISwitch *)switchview {
    self.currentUser.sipEnabled = switchview.on;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:VOIP_ACCOUNT_SECTION]
                  withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
