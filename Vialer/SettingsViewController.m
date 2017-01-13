//
//  SettingsViewController.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "SettingsViewController.h"

#import "ActivateSIPAccountViewController.h"
#import "EditNumberViewController.h"
#import "SIPUtils.h"
#import "SVProgressHUD.h"
#import "SystemUser.h"
#import "UIAlertController+Vialer.h"
#import "Vialer-Swift.h"
#import "VoIPGRIDRequestOperationManager.h"

static int const SettingsViewControllerVoIPAccountSection   = 0;
static int const SettingsViewControllerSipEnabledRow        = 0;
static int const SettingsViewControllerWifiNotificationRow  = 1;
static int const SettingsViewControllerSipAccountRow        = 2;
static int const SettingsViewControllerTCPRow               = 3;

static int const SettingsViewControllerNumbersSection       = 1;
static int const SettingsViewControllerMyNumberRow          = 0;
static int const SettingsViewControllerOutgoingNumberRow    = 1;
static int const SettingsViewControllerMyEmailRow           = 2;

static int const SettingsViewControllerUISwitchWidth            = 60;
static int const SettingsViewControllerUISwitchOriginOffsetX    = 35;
static int const SettingsViewControllerUISwitchOriginOffsetY    = 15;

static NSString * const SettingsViewControllerShowEditNumberSegue       = @"ShowEditNumberSegue";
static NSString * const SettingsViewControllerShowActivateSIPAccount = @"ShowActivateSIPAccount";

static NSString * const SettingsViewControllerUseTCPConnectionKey = @"UseTCPConnection";

@interface SettingsViewController() <EditNumberViewControllerDelegate>
@property (weak, nonatomic) SystemUser *currentUser;
@property (nonatomic) BOOL useTCP;
@end

@implementation SettingsViewController

#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outgoingNumberUpdated:) name:SystemUserOutgoingNumberUpdatedNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [VialerGAITracker trackScreenForControllerWithName:NSStringFromClass([self class])];

    if (self.showSIPAccountWebview) {
        [self performSegueWithIdentifier:SettingsViewControllerShowActivateSIPAccount sender:self];
    } else {
        [self.tableView reloadData];
    }
    [self.currentUser addObserver:self forKeyPath:NSStringFromSelector(@selector(sipEnabled)) options:0 context:NULL];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.currentUser removeObserver:self forKeyPath:NSStringFromSelector(@selector(sipEnabled))];
    [super viewWillDisappear:animated];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SystemUserOutgoingNumberUpdatedNotification object:nil];
}

#pragma mark - Properties

- (SystemUser *)currentUser {
    if (!_currentUser) {
        _currentUser = [SystemUser currentUser];
    }
    return _currentUser;
}

- (BOOL)useTCP {
    return [[NSUserDefaults standardUserDefaults] boolForKey:SettingsViewControllerUseTCPConnectionKey];
}

- (void)setUseTCP:(BOOL)useTCP {
    [[NSUserDefaults standardUserDefaults] setBool:useTCP forKey:SettingsViewControllerUseTCPConnectionKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case SettingsViewControllerVoIPAccountSection:
            if (self.currentUser.sipEnabled) {
                // Show the VoIP Switch and the account ID
                return 4;
            } else {
                // Only show VoIP Switch
                return 2;
            }
            break;

        case SettingsViewControllerNumbersSection:
            // Always 3
            // - My number
            // - Outgoing number
            // - Email address
            return 3;
            break;

        default:
            return 0;
            break;
    }
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
                       defaultVal:self.currentUser.sipEnabled];
        } else if (indexPath.row == SettingsViewControllerWifiNotificationRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:tableViewSettingsWithSwitchCell];
            [self createOnOffView:cell withTitle: NSLocalizedString(@"Enable WiFi notification", nil)
                          withTag:1002
                       defaultVal:!self.currentUser.noWiFiNotification];
        } else if (indexPath.row == SettingsViewControllerSipAccountRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:tableViewSettingsCell];
            cell.textLabel.text = NSLocalizedString(@"VoIP account ID", nil);
            cell.detailTextLabel.text = self.currentUser.sipAccount;
        } else if (indexPath.row == SettingsViewControllerTCPRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:tableViewSettingsWithSwitchCell];
            [self createOnOffView:cell withTitle: NSLocalizedString(@"Enable TCP connection", nil)
                          withTag:1003
                       defaultVal:self.useTCP];
        }
    } else if (indexPath.section == SettingsViewControllerNumbersSection) {
        if (indexPath.row == SettingsViewControllerMyNumberRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:tableViewSettingsWithAccessoryCell];
            cell.textLabel.text = NSLocalizedString(@"My number", nil);
            cell.detailTextLabel.text = self.currentUser.mobileNumber;

        } else if (indexPath.row == SettingsViewControllerOutgoingNumberRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:tableViewSettingsCell];
            cell.textLabel.text = NSLocalizedString(@"Outgoing number", nil);
            cell.detailTextLabel.text = self.currentUser.outgoingNumber;

        } else if (indexPath.row == SettingsViewControllerMyEmailRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:tableViewSettingsCell];
            cell.textLabel.text = NSLocalizedString(@"Email address", nil);
            cell.detailTextLabel.minimumScaleFactor = 0.8f;
            cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
            cell.detailTextLabel.text = self.currentUser.username;
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
        editNumberController.numberToEdit = self.currentUser.mobileNumber;
        editNumberController.delegate = self;
    } else if ([segue.identifier isEqualToString:SettingsViewControllerShowActivateSIPAccount]) {
        ActivateSIPAccountViewController *activateSIPAccountViewController = (ActivateSIPAccountViewController *)segue.destinationViewController;
        if (self.showSIPAccountWebview) {
            activateSIPAccountViewController.backButtonToRootViewController = YES;
            self.showSIPAccountWebview = NO;
        }
    }
}

- (void)unwindToSettingsViewController:(UIStoryboardSegue *)sender {}

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
    myNumberCell.detailTextLabel.text = self.currentUser.mobileNumber;
}

#pragma mark - Enable VoIP switch handler

- (void)didChangeSwitch:(UISwitch *)sender {
    if (sender.tag == 1001) {
        if (sender.isOn) {
            [self tryToEnableSIPWithSwitch:sender];
        } else {
            [SVProgressHUD showWithStatus:NSLocalizedString(@"Disabling VoIP...", nil)];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                self.currentUser.sipEnabled = NO;
            });
        }
    } else if (sender.tag == 1002) {
        self.currentUser.noWiFiNotification = !sender.isOn;
    } else if (sender.tag == 1003) {
        self.useTCP = sender.isOn;
        // Remove and initiate the endpoint again to make sure the new transport is loaded.
        DDLogVerbose(@"Remove Endpoint for new connection configurations.");
        [SIPUtils removeSIPEndpoint];
        DDLogVerbose(@"Removed Endpoint, restarting.");
        [SIPUtils setupSIPEndpoint];
        DDLogVerbose(@"Endpoint restarted.");
    }
}


- (void)tryToEnableSIPWithSwitch:(UISwitch *)sender {
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Loading VoIP settings...", nil)];
    [self.currentUser getAndActivateSIPAccountWithCompletion:^(BOOL success, NSError *error) {
        [SVProgressHUD dismiss];
        if (error) {
            // Fetching account failed.
            [self presentViewController:[UIAlertController alertControllerWithTitle:NSLocalizedString(@"Failed to load VoIP settings.", nil)
                                                                            message:NSLocalizedString(@"Unable to load your VoIP settings. Please try again.", nil)
                                                               andDefaultButtonText:NSLocalizedString(@"Ok", nil)]
                               animated:YES
                             completion:nil];
            sender.on = NO;
        } else if (!success) {
            // There is no account, show info page.
            sender.on = NO;
            [self performSegueWithIdentifier:SettingsViewControllerShowActivateSIPAccount sender:self];
        } else {
            // Account was retrieved, show VoIP Acount row.
            NSIndexSet *indexSetWithIndex = [NSIndexSet indexSetWithIndex:SettingsViewControllerVoIPAccountSection];
            [self.tableView reloadSections:indexSetWithIndex withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }];
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

#pragma mark - Notifications / KVO

- (void)outgoingNumberUpdated:(NSNotification *)noticiation {
    NSIndexPath *rowAtIndexPath = [NSIndexPath indexPathForRow:SettingsViewControllerOutgoingNumberRow
                                                     inSection:SettingsViewControllerNumbersSection];
    UITableViewCell *myNumberCell = [self.tableView cellForRowAtIndexPath:rowAtIndexPath];
    myNumberCell.detailTextLabel.text = self.currentUser.outgoingNumber;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    // React to changes on the SipAllowed property of the SystemUser.
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(sipEnabled))] ) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [SVProgressHUD dismiss];
        });
    }
}

@end
