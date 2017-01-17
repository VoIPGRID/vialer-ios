//
//  AvailabilityViewController.m
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "AvailabilityViewController.h"

#import "AvailabilityModel.h"
#import "Configuration.h"
#import "SVProgressHUD.h"
#import "UIAlertController+Vialer.h"
#import "Vialer-Swift.h"
#import "VialerWebViewController.h"
#import "VoIPGRIDRequestOperationManager.h"

@interface AvailabilityViewController()
@property (nonatomic, weak) NSIndexPath *lastSelected;
@property (nonatomic, strong) AvailabilityModel *availabilityModel;
@end

static NSString * const AvailabilityAddFixedDestinationSegue = @"AddFixedDestinationSegue";
static NSString * const AvailabilityViewControllerAddFixedDestinationPageURLWithVariableForClient = @"/client/%@/fixeddestination/add/";

@implementation AvailabilityViewController

- (void)awakeFromNib {
    [super awakeFromNib];
     self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString: NSLocalizedString(@"Loading availability options...", nil)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [VialerGAITracker trackScreenForControllerWithName:NSStringFromClass([self class])];

    [self.refreshControl beginRefreshing];
    [self.tableView setContentOffset:CGPointMake(0, -self.refreshControl.frame.size.height) animated:YES];
    [self loadUserDestinationsWithRefreshControl:self.refreshControl];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.tintColor = [[Configuration defaultConfiguration].colorConfiguration colorForKey:ConfigurationAvailabilityTableViewTintColor];
}

- (AvailabilityModel *)availabilityModel {
    if (_availabilityModel == nil) {
        _availabilityModel = [[AvailabilityModel alloc] init];
    }
    return _availabilityModel;
}

- (IBAction)loadUserDestinationsWithRefreshControl:(UIRefreshControl *)sender {
    [self.availabilityModel getUserDestinations:^(NSString *localizedErrorString) {
        if (localizedErrorString) {
            [self presentViewController:[UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                            message:localizedErrorString
                                                               andDefaultButtonText:NSLocalizedString(@"Ok", nil)]
                               animated:YES
                             completion:nil];
        }else{
            [self.tableView reloadData];
        }
        [self.refreshControl endRefreshing];
    }];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.availabilityModel.availabilityOptions count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *DefaultCellIdentifier = @"AvailabilityTableViewDefaultCell";
    NSDictionary *availabilityDict = self.availabilityModel.availabilityOptions[indexPath.row];

    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:DefaultCellIdentifier];
    if ([availabilityDict[AvailabilityModelPhoneNumberKey] isEqualToNumber:@0]){
        cell.textLabel.text = availabilityDict[AvailabilityModelDescription];
    } else {
        NSString *phoneNumber = [availabilityDict[AvailabilityModelPhoneNumberKey] stringValue];
        if (phoneNumber.length > 5) {
            phoneNumber = [@"+" stringByAppendingString:phoneNumber];
        }
        cell.textLabel.text = [NSString stringWithFormat:@"%@ / %@",  phoneNumber, availabilityDict[AvailabilityModelDescription]];
    }

    if ([availabilityDict[AvailabilityModelSelected] isEqualToNumber:[NSNumber numberWithBool:YES]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.lastSelected = indexPath;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView cellForRowAtIndexPath:self.lastSelected].accessoryType = UITableViewCellAccessoryNone;
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;

    if (indexPath.row >= [self.availabilityModel.availabilityOptions count]) {
        return;
    }
    self.lastSelected = indexPath;

    [SVProgressHUD showWithStatus:NSLocalizedString(@"Saving availability...", nil)];
    [self.availabilityModel saveUserDestination:self.lastSelected.row withCompletion:^(NSString *localizedErrorString) {
        [SVProgressHUD dismiss];
        if (localizedErrorString) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                           message:localizedErrorString
                                                              andDefaultButtonText:NSLocalizedString(@"Ok", nil)];
            [self presentViewController:alert
                               animated:YES
                             completion:nil];
        } else {
            [self.delegate availabilityViewController:self availabilityHasChanged:self.availabilityModel.availabilityOptions];
            [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
        }
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:AvailabilityAddFixedDestinationSegue]) {
        if ([segue.destinationViewController isKindOfClass:[VialerWebViewController class]]) {
            VialerWebViewController *webController = segue.destinationViewController;

            [VialerGAITracker trackScreenForControllerWithName:[VialerGAITracker GAAddFixedDestinationWebViewTrackingName]];
            webController.title = NSLocalizedString(@"Add destination", nil);
            NSString *nextURL = [NSString stringWithFormat:AvailabilityViewControllerAddFixedDestinationPageURLWithVariableForClient,
                                 [SystemUser currentUser].clientID];
            [webController nextUrl:nextURL];

        } else {
            VialerLogWarning(@"Could not segue, destinationViewController is not a \"VialerWebViewController\"");
        }
    }
}

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender {
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}
@end
