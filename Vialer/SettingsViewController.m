//
//  SettingsViewController.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "SettingsViewController.h"

#import "EditNumberViewController.h"
#import "GAITracker.h"
#import "SIPUtils.h"
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

static int const SettingsViewControllerUISwitchWidth = 60;
static int const SettingsViewControllerUISwitchOriginOffsetX = 35;
static int const SettingsViewControllerUISwitchOriginOffsetY = 15;

static NSString * const SettingsViewControllerShowEditNumberSegue = @"ShowEditNumberSegue";

@interface SettingsViewController() <EditNumberViewControllerDelegate>
@property (weak, nonatomic) SystemUser *systemUser;
@end

@implementation SettingsViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [GAITracker trackScreenForControllerName:NSStringFromClass([self class])];
}

#pragma mark - Properties

- (SystemUser *)systemUser {
    if (!_systemUser) {
        _systemUser = [SystemUser currentUser];
    }
    return _systemUser;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case SettingsViewControllerVoIPAccountSection: {
            // Are we allowed to show anything?
            if (self.systemUser.sipAllowed && self.systemUser.sipAccount) {
                // Do we show all fields?
                if (self.systemUser.sipEnabled) {
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
    static NSString *tableViewSettingsWithSwitchCell = @"SettingsWithSwitchCell";

    UITableViewCell *cell;

    // Specific config according to cell function.
    if (indexPath.section == SettingsViewControllerVoIPAccountSection) {
        if (indexPath.row == SettingsViewControllerSipEnabledRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:tableViewSettingsWithSwitchCell];
            [self createOnOffView:cell withTitle: NSLocalizedString(@"Enable VoIP", nil)
                          withTag:1001
                       defaultVal:self.systemUser.sipEnabled];
        } else if (indexPath.row == SettingsViewControllerSipAccountRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:tableViewSettingsCell];
            cell.textLabel.text = NSLocalizedString(@"VoIP account ID", nil);
            cell.detailTextLabel.text = self.systemUser.sipAccount;
        }
    } else if (indexPath.section == SettingsViewControllerNumbersSection) {
        if (indexPath.row == SettingsViewControllerMyNumberRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:tableViewSettingsWithAccessoryCell];
            cell.textLabel.text = NSLocalizedString(@"My number", nil);
            cell.detailTextLabel.text = self.systemUser.mobileNumber;

        } else if (indexPath.row == SettingsViewControllerOutgoingNumberRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:tableViewSettingsCell];
            cell.textLabel.text = NSLocalizedString(@"Outgoing number", nil);
            cell.detailTextLabel.text = self.systemUser.outgoingNumber;

        } else if (indexPath.row == SettingsViewControllerMyEmailRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:tableViewSettingsCell];
            cell.textLabel.text = NSLocalizedString(@"Email", nil);
            cell.detailTextLabel.minimumScaleFactor = 0.8f;
            cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
            cell.detailTextLabel.text = self.systemUser.username;
        }
    }
    return cell;
}

#pragma mark - actions

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender {
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:SettingsViewControllerShowEditNumberSegue]) {
        EditNumberViewController *editNumberController = (EditNumberViewController *)segue.destinationViewController;
        editNumberController.numberToEdit = self.systemUser.mobileNumber;
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
    // Update the tableView Cell.
    NSIndexPath *rowAtIndexPath = [NSIndexPath indexPathForRow:SettingsViewControllerMyNumberRow
                                                     inSection:SettingsViewControllerNumbersSection];
    UITableViewCell *myNumberCell = [self.tableView cellForRowAtIndexPath:rowAtIndexPath];
    myNumberCell.detailTextLabel.text = self.systemUser.mobileNumber;
}

#pragma mark - Enable VoIP switch handler

- (void)didChangeSwitch:(UISwitch *)switchview {
    if (switchview.tag == 1001) {
        self.systemUser.sipEnabled = switchview.on;
        if (switchview.on) {
            [SIPUtils setupSIPEndpoint];
        }
        NSIndexSet *indexSetWithIndex = [NSIndexSet indexSetWithIndex:SettingsViewControllerVoIPAccountSection];
        [self.tableView reloadSections:indexSetWithIndex withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - Helper function for switches in table

- (void)createOnOffView:(UITableViewCell*)cell withTitle:(NSString*)title withTag:(int)tag defaultVal:(BOOL)defaultVal {
    cell.textLabel.text = title;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    CGRect rect;
    rect = cell.contentView.frame;
    rect.origin.x = rect.size.width / 2 + SettingsViewControllerUISwitchOriginOffsetX;
    rect.origin.y = rect.size.height / 2 - SettingsViewControllerUISwitchOriginOffsetY;
    rect.size.width = SettingsViewControllerUISwitchWidth;

    UISwitch *switchView = [[UISwitch alloc] initWithFrame:rect];
    [switchView addTarget:self action:@selector(didChangeSwitch:) forControlEvents:UIControlEventValueChanged];
    switchView.tag = tag;
    [switchView setOn:defaultVal];

    cell.accessoryView = switchView;
}

@end
