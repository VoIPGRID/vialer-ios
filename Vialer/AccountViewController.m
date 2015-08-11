//
//  AccountViewController.m
//  Vialer
//
//  Created by Harold on 18/06/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "AccountViewController.h"
#import "VoIPGRIDRequestOperationManager.h"
#import "AccountViewFooterView.h"
#import "EditNumberTableViewController.h"
#import "UIAlertView+Blocks.h"

#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"

@interface AccountViewController ()
@end

@implementation AccountViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:[NSStringFromClass([self class]) stringByReplacingOccurrencesOfString:@"ViewController" withString:@""]];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

#pragma mark - Table view data source

//To enable the logout button,
//- change number of sections to 3
//- change LOGOUT_BUTTON_SECTION to 1
//- change NUMBERS_SECTION to 2

#define VOIP_ACCOUNT_SECTION 0
#define SIP_ACCOUNT_ROW 0
#define SIP_PASSWORD_ROW 1

#define LOGOUT_BUTTON_SECTION 99 //unused should be 1
#define LOGOUT_BUTTON_ROW 0

#define NUMBERS_SECTION 1 //was 2
#define MY_NUMBER_ROW 0
#define OUTGOING_NUMBER_ROW 1

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2; //3 if you want to display the logout button
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == LOGOUT_BUTTON_SECTION)
        return 1;
    return 2;
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
        if (indexPath.row == SIP_ACCOUNT_ROW) {
            cell.textLabel.text = NSLocalizedString(@"SIP account", nil);
            cell.detailTextLabel.text = [VoIPGRIDRequestOperationManager sharedRequestOperationManager].sipAccount;
        } else if (indexPath.row == SIP_PASSWORD_ROW) {
            cell.textLabel.text = NSLocalizedString(@"Password", nil);
            cell.detailTextLabel.text = [VoIPGRIDRequestOperationManager sharedRequestOperationManager].sipPassword;
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
            cell.detailTextLabel.text = [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] outgoingNumber];
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
    if (section == VOIP_ACCOUNT_SECTION)
        return 35;
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == VOIP_ACCOUNT_SECTION)
        return NSLocalizedString(@"VoIP Account", nil);
    return @"";
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    //The footer will be added to the last displayed section
    if (section == NUMBERS_SECTION) {
        NSLog(@"Tableview size %@", NSStringFromCGRect(self.tableView.frame));
        CGRect frameOfLastRow = [tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:OUTGOING_NUMBER_ROW inSection:NUMBERS_SECTION]];
        NSLog(@"fame of last row: %@", NSStringFromCGRect(frameOfLastRow));
        
        //the empty space below the last cell is the complete height of the tableview minus
        //the y position of the last row + the last rows height.
        CGRect emptyFrameBelowLastRow = CGRectMake(0, 0, self.tableView.frame.size.width,
                   self.tableView.frame.size.height - (frameOfLastRow.origin.y + frameOfLastRow.size.height));
        
        NSLog(@"empty space: %@", NSStringFromCGRect(emptyFrameBelowLastRow));
        
        return [[AccountViewFooterView alloc] initWithFrame:emptyFrameBelowLastRow];
    }
    return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == LOGOUT_BUTTON_SECTION && indexPath.row == LOGOUT_BUTTON_ROW) {
        [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] logout];
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

@end
