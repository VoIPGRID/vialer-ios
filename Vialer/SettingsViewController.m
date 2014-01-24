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
#import "SelectRecentsFilterViewController.h"
#import "NSString+Mobile.h"

#define PHONE_NUMBER_ALERT_TAG 100
#define LOG_OUT_ALERT_TAG 101

#define COST_INFO_IDX    0
#define PHONE_NUMBER_IDX 1
#define SHOW_RECENTS_IDX -1 // Disabled for now
#define LOG_OUT_IDX      2

@interface SettingsViewController ()
@property (nonatomic, strong) NSArray *sectionTitles;
@property (nonatomic, strong) NSString *mobileCC;
@end

@implementation SettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Settings", nil);
        self.tabBarItem.image = [UIImage imageNamed:@"settings"];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]]];
        
        self.sectionTitles = @[NSLocalizedString(@"Information", nil), NSLocalizedString(@"Your number", nil), /*NSLocalizedString(@"Recents", nil), */ NSLocalizedString(@"Log out", nil)];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    self.mobileCC = [NSString systemCallingCode];
    if ([self.mobileCC isEqualToString:@"+31"]) {
        self.mobileCC = @"+316";
    }
}

- (void)viewWillAppear:(BOOL)animated  {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Textfield delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (newString.length != [[newString componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"+0123456789 ()"] invertedSet]] componentsJoinedByString:@""].length) {
        return NO;
    }

    if (![self.mobileCC length] || [newString hasPrefix:self.mobileCC]) {
        return YES;
    }
    return NO;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sectionTitles.count;
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
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    
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
    } else if (indexPath.section == SHOW_RECENTS_IDX) {
        RecentsFilter recentsFilter = [[[NSUserDefaults standardUserDefaults] objectForKey:@"RecentsFilter"] integerValue];
        cell.userInteractionEnabled = NO; //0 < [[[NSUserDefaults standardUserDefaults] objectForKey:@"MobileNumber"] length];
        cell.alpha = cell.userInteractionEnabled ? 1.0f : 0.5f;
        cell.textLabel.text = (recentsFilter == RecentsFilterNone || !cell.userInteractionEnabled) ? NSLocalizedString(@"Show all recent calls", nil) : NSLocalizedString(@"Show your recent calls", nil);
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
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Mobile number", nil) message:NSLocalizedString(@"Please provide your mobile number starting with your country code.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
        alert.tag = PHONE_NUMBER_ALERT_TAG;
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        
        NSString *mobileNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"MobileNumber"];
        if (![mobileNumber length]) {
            mobileNumber = self.mobileCC;
        }
        [alert textFieldAtIndex:0].delegate = self;
        [alert textFieldAtIndex:0].text = mobileNumber;
        [alert textFieldAtIndex:0].keyboardType = UIKeyboardTypePhonePad;
        [alert show];
    } else if (indexPath.section == SHOW_RECENTS_IDX) {
        SelectRecentsFilterViewController *selectRecentsFilterViewController = [[SelectRecentsFilterViewController alloc] initWithNibName:@"SelectRecentsFilterViewController" bundle:[NSBundle mainBundle]];
        selectRecentsFilterViewController.recentsFilter = [[[NSUserDefaults standardUserDefaults] objectForKey:@"RecentsFilter"] integerValue];
        selectRecentsFilterViewController.delegate = self;

        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:selectRecentsFilterViewController];
        navigationController.navigationBar.barStyle = UIStatusBarStyleLightContent;
        [self presentViewController:navigationController animated:YES completion:^{}];
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
            NSString *mobileNumber = [mobileNumberTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if ([mobileNumber length] && ![mobileNumber isEqualToString:self.mobileCC]) {
                [[NSUserDefaults standardUserDefaults] setObject:mobileNumber forKey:@"MobileNumber"];
                [[NSUserDefaults standardUserDefaults] synchronize];

                [self.tableView reloadData];
                [[NSNotificationCenter defaultCenter] postNotificationName:RECENTS_FILTER_UPDATED_NOTIFICATION object:nil];
            }
        }
    } else if (alertView.tag == LOG_OUT_ALERT_TAG) {
        if (buttonIndex == 1) {
            [[VoysRequestOperationManager sharedRequestOperationManager] logout];
        }
    }
}

#pragma mark - Select recents view controller delegate

- (void)selectRecentsFilterViewController:(SelectRecentsFilterViewController *)selectRecentsFilterViewController didFinishWithRecentsFilter:(RecentsFilter)recentsFilter {
    [[NSUserDefaults standardUserDefaults] setObject:@(recentsFilter) forKey:@"RecentsFilter"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.tableView reloadData];
    [[NSNotificationCenter defaultCenter] postNotificationName:RECENTS_FILTER_UPDATED_NOTIFICATION object:nil];
}

@end
