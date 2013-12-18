//
//  SettingsViewController.m
//  Vialer
//
//  Created by Reinier Wieringa on 11/12/13.
//  Copyright (c) 2013 Voys. All rights reserved.
//

#import "SettingsViewController.h"
#import "VoysRequestOperationManager.h"
#import "InfoViewController.h"

#define PHONE_NUMBER_ALERT_TAG 100
#define LOG_OUT_ALERT_TAG 101

#define COST_INFO_IDX    0
#define PHONE_NUMBER_IDX 1
#define LOG_OUT_IDX      2

@interface SettingsViewController ()
@property (nonatomic, strong) NSArray *sectionTitles;
@end

@implementation SettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Settings", nil);
        self.tabBarItem.image = [UIImage imageNamed:@"settings"];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]]];
        
        self.sectionTitles = @[NSLocalizedString(@"Information", nil), NSLocalizedString(@"Call back", nil), NSLocalizedString(@"Log out", nil)];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sectionTitles[section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"SettingsTableViewCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    if (indexPath.section == COST_INFO_IDX) {
        cell.textLabel.text = NSLocalizedString(@"Information about this app", nil);
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f) {
            [cell setAccessoryType:UITableViewCellAccessoryDetailButton];
        } else {
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        }
    } else if (indexPath.section == PHONE_NUMBER_IDX) {
        NSString *phoneNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"MobileNumber"];
        cell.textLabel.text = [phoneNumber length] ? phoneNumber : NSLocalizedString(@"Provide your mobile number", nil);
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    } else if (indexPath.section == LOG_OUT_IDX) {
        cell.textLabel.text = NSLocalizedString(@"Log out from this app", nil);
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    [self tableView:tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == COST_INFO_IDX) {
        InfoViewController *infoViewController = [[InfoViewController alloc] initWithNibName:@"InfoViewController" bundle:[NSBundle mainBundle]];
        [self.navigationController pushViewController:infoViewController animated:YES];
    } else if (indexPath.section == PHONE_NUMBER_IDX) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Mobile number", nil) message:NSLocalizedString(@"Please provide your mobile number.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
        alert.tag = PHONE_NUMBER_ALERT_TAG;
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alert textFieldAtIndex:0].text = [[NSUserDefaults standardUserDefaults] objectForKey:@"MobileNumber"];
        [alert textFieldAtIndex:0].keyboardType = UIKeyboardTypePhonePad;
        [alert show];
    } else if (indexPath.section == LOG_OUT_IDX) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Log out", nil) message:NSLocalizedString(@"Are you sure you want to log out?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"No", nil) otherButtonTitles:NSLocalizedString(@"Yes", nil), nil];
        [alert show];
        alert.tag = LOG_OUT_ALERT_TAG;
    }
}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == PHONE_NUMBER_ALERT_TAG) {
        if (buttonIndex == 1) {
            UITextField *mobileNumberTextField = [alertView textFieldAtIndex:0];
            if ([mobileNumberTextField.text length]) {
                [[NSUserDefaults standardUserDefaults] setObject:mobileNumberTextField.text forKey:@"MobileNumber"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                [self.tableView reloadData];
            }
        }
    } else if (alertView.tag == LOG_OUT_ALERT_TAG) {
        if (buttonIndex == 1) {
            [[VoysRequestOperationManager sharedRequestOperationManager] logout];
        }
    }
}

@end
