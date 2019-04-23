//
//  SideMenuTableViewController.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "SideMenuViewController.h"
#import "SystemUser.h"
#import "VialerWebViewController.h"
#import "Vialer-Swift.h"

static NSString * const SideMenuTableViewControllerLogoImageName = @"logo";
static NSString * const SideMenuViewControllerStatisticsPageURL = @"/stats/dashboard/";
static NSString * const SideMenuViewControllerDialplanPageURL = @"/dialplan/";

@interface SideMenuViewController() <AvailabilityViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *outgoingNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *buildVersionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *availabilityIcon;
@property (weak, nonatomic) IBOutlet UIImageView *statisticsIcon;
@property (weak, nonatomic) IBOutlet UIImageView *informationIcon;
@property (weak, nonatomic) IBOutlet UIImageView *settingsIcon;
@property (weak, nonatomic) IBOutlet UIImageView *dialplanIcon;
@property (weak, nonatomic) IBOutlet UIImageView *logoutIcon;
@property (weak, nonatomic) IBOutlet UILabel *availabilityDetailLabel;

@property (strong, nonatomic) NSString *appVersionBuildString;
@property (strong, nonatomic) UIColor *tintColor;
@property (strong, nonatomic) AvailabilityModel *availabilityModel;
@property (weak, nonatomic) ColorsConfiguration *colorsConfiguration;
@end

@implementation SideMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.headerView.backgroundColor = [self.colorsConfiguration colorForKey:ColorsSideMenuHeaderBackground];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.usernameLabel.text = [SystemUser currentUser].displayName;
    self.outgoingNumberLabel.text = [SystemUser currentUser].outgoingNumber;
    [self loadAvailability];
}

#pragma mark - properties

- (ColorsConfiguration *)colorsConfiguration {
    if (!_colorsConfiguration) {
        _colorsConfiguration = [ColorsConfiguration shared];
    }
    return _colorsConfiguration;
}

- (void)setUsernameLabel:(UILabel *)usernameLabel {
    _usernameLabel = usernameLabel;
    _usernameLabel.textColor = [self.colorsConfiguration colorForKey:ColorsSideMenuTint];
}

- (void)setOutgoingNumberLabel:(UILabel *)outgoingNumberLabel {
    _outgoingNumberLabel = outgoingNumberLabel;
    _outgoingNumberLabel.textColor = [self.colorsConfiguration colorForKey:ColorsSideMenuTint];
}

- (void)setBuildVersionLabel:(UILabel *)buildVersionLabel {
    _buildVersionLabel = buildVersionLabel;
    _buildVersionLabel.text = self.appVersionBuildString;

    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (appDelegate.isScreenshotRun) {
        _buildVersionLabel.text = nil;
    }
}

- (UIColor *)tintColor {
    return [self.colorsConfiguration colorForKey:ColorsSideMenuTint];
}

- (void)setAvailabilityIcon:(UIImageView *)availabilityIcon {
    _availabilityIcon = availabilityIcon;
    _availabilityIcon.image = [self coloredImageWithImage:_availabilityIcon.image color:self.tintColor];
}

- (void)setStatisticsIcon:(UIImageView *)statisticsIcon {
    _statisticsIcon = statisticsIcon;
    _statisticsIcon.image = [self coloredImageWithImage:_statisticsIcon.image color:self.tintColor];
}

- (void)setInformationIcon:(UIImageView *)informationIcon {
    _informationIcon = informationIcon;
    _informationIcon.image = [self coloredImageWithImage:_informationIcon.image color:self.tintColor];
}

- (void)setSettingsIcon:(UIImageView *)settingsIcon {
    _settingsIcon = settingsIcon;
    _settingsIcon.image = [self coloredImageWithImage:_settingsIcon.image color:self.tintColor];
}

- (void)setDialplanIcon:(UIImageView *)dialplanIcon {
    _dialplanIcon = dialplanIcon;
    _dialplanIcon.image = [self coloredImageWithImage:_dialplanIcon.image color:self.tintColor];
}

- (void)setLogoutIcon:(UIImageView *)logoutIcon {
    _logoutIcon = logoutIcon;
    _logoutIcon.image = [self coloredImageWithImage:_logoutIcon.image color:self.tintColor];
}

- (AvailabilityModel *)availabilityModel {
    if (!_availabilityModel) {
        _availabilityModel = [[AvailabilityModel alloc] init];
    }
    return _availabilityModel;
}

#pragma mark - actions

- (IBAction)logout:(UIButton *)sender {
    NSMutableString *message = [NSMutableString stringWithFormat:NSLocalizedString(@"%@\nis currently logged in.", nil),
                                [SystemUser currentUser].displayName];

    [message appendFormat:@"\n%@", NSLocalizedString(@"Are you sure you want to log out?", nil)];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Log out", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[SystemUser currentUser] logout];
    }];
    [alert addAction:defaultAction];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", nil) style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:SideMenuViewControllerShowStatisticsSegue]) {
        UINavigationController *navController = (UINavigationController *)segue.destinationViewController;
        VialerWebViewController *webController = navController.viewControllers[0];

        [VialerGAITracker trackScreenForControllerWithName:[VialerGAITracker GAStatisticsWebViewTrackingName]];
        webController.title = NSLocalizedString(@"Statistics", nil);
        [webController nextUrl:SideMenuViewControllerStatisticsPageURL];

    } else if ([segue.identifier isEqualToString:SideMenuViewControllerShowInformationSegue]) {
        [VialerGAITracker trackScreenForControllerWithName:[VialerGAITracker GAInformationWebViewTrackingName]];
        UINavigationController *navController = (UINavigationController *)segue.destinationViewController;
        VialerWebViewController *webController = navController.viewControllers[0];
        webController.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:SideMenuTableViewControllerLogoImageName]];

        OnboardingLanguage onboardingLanuage = OnboardingLanguageEn;
        if ([[[NSBundle mainBundle] preferredLocalizations][0] isEqualToString:@"nl"]) {
            onboardingLanuage = OnboardingLanguageNl;
        }

        NSString *onboardingUrl = [[UrlsConfiguration shared] onboardingUrlWithLanguage: onboardingLanuage];

        webController.title = NSLocalizedString(@"Information", nil);
        webController.URL = [NSURL URLWithString:onboardingUrl];
        webController.showsNavigationToolbar = NO;

    } else if ([segue.identifier isEqualToString:SideMenuViewControllerShowDialPlanSegue]) {
        UINavigationController *navController = (UINavigationController *)segue.destinationViewController;
        VialerWebViewController *webController = navController.viewControllers[0];

        [VialerGAITracker trackScreenForControllerWithName:[VialerGAITracker GADialplanWebViewTrackingName]];
        webController.title = NSLocalizedString(@"Dial plan", nil);
        [webController nextUrl:SideMenuViewControllerDialplanPageURL];

    } else if ([segue.identifier isEqualToString:SideMenuViewControllerShowAvailabilitySegue]) {
        UINavigationController *navController = (UINavigationController *)segue.destinationViewController;
        AvailabilityViewController *availabilityVC = navController.viewControllers[0];
        availabilityVC.delegate = self;
    }
}

#pragma mark - utils

- (NSString *)appVersionBuildString {
    if (!_appVersionBuildString) {
        _appVersionBuildString = [AppInfo currentAppVersion];
    }
    return _appVersionBuildString;
}

#pragma mark - AvailabilityViewControllerDelegate

- (void)availabilityViewController:(AvailabilityViewController *)controller availabilityHasChanged:(NSArray *)availabilityOptions {
    [self loadAvailability];
}

#pragma mark - utils

- (UIImage *)coloredImageWithImage:(UIImage*)image color:(UIColor*)color {
    CGFloat scaleFactor = 1.0f;

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(floor(image.size.width * scaleFactor), floor(image.size.height * scaleFactor)), NO, 0.0f);

    [color set];

    CGRect rect = CGRectZero;
    rect.size.width = floor(image.size.width * scaleFactor);
    rect.size.height = floor(image.size.height * scaleFactor);

    UIRectFill(rect);

    [image drawInRect:CGRectMake(0.0f,
                                 0.0f,
                                 floor(image.size.width * scaleFactor),
                                 floor(image.size.height * scaleFactor))
            blendMode:kCGBlendModeDestinationIn
                alpha:1.0f];

    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}

- (void)loadAvailability {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [self.availabilityModel getCurrentAvailabilityWithBlock:^(NSString *currentAvailability, NSString *localizedError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (localizedError) {
                    self.availabilityDetailLabel.text = NSLocalizedString(@"Unable to fetch availability", nil);
                } else {
                    self.availabilityDetailLabel.text = currentAvailability;
                }
            });
        }];
    });
}


@end
