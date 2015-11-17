//
//  SideMenuTableViewController.m
//  Vialer
//
//  Created by Bob Voorneveld on 17/11/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "SideMenuTableViewController.h"

#import "Configuration.h"
#import "GAITracker.h"
#import "SystemUser.h"
#import "VialerWebViewController.h"

static NSString * const SideMenuTableViewControllerShowStatisticsSegue = @"ShowStatisticsSegue";
static NSString * const SideMenuTableViewControllerShowInformationSegue = @"ShowInformationSegue";
static NSString * const SideMenuTableViewControllerShowDialPlanSegue = @"ShowDialPlanSegue";

static NSString * const SideMenuTableViewControllerLogoImageName = @"logo";

@interface SideMenuTableViewController ()
@property (strong, nonatomic) UIColor *tintColor;
@property (weak, nonatomic) IBOutlet UIImageView *availabilityIcon;
@property (weak, nonatomic) IBOutlet UIImageView *statisticsIcon;
@property (weak, nonatomic) IBOutlet UIImageView *informationIcon;
@property (weak, nonatomic) IBOutlet UIImageView *settingsIcon;
@property (weak, nonatomic) IBOutlet UIImageView *dialplanIcon;
@property (weak, nonatomic) IBOutlet UIImageView *logoutIcon;
@property (weak, nonatomic) IBOutlet UILabel *availabilityDetailLabel;
@end

@implementation SideMenuTableViewController

#pragma mark - properties

- (UIColor *)tintColor {
    return [Configuration tintColorForKey:ConfigurationSideMenuTintColor];
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

// TODO
- (void)setAvailabilityDetailLabel:(UILabel *)availabilityDetailLabel {
    _availabilityDetailLabel = availabilityDetailLabel;
    _availabilityDetailLabel.hidden = YES;
}

#pragma mark - actions

/**
 For some reason, the tableview didSelectRowForIndexPath isn't always fired. So a UIButton on the logout cell
 with this target action does the trick.
 */
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
    if ([segue.identifier isEqualToString:SideMenuTableViewControllerShowStatisticsSegue]) {
        [GAITracker trackScreenForControllerName:@"StatisticsWebView"];
        UINavigationController *navController = (UINavigationController *)segue.destinationViewController;
        VialerWebViewController *webController = navController.viewControllers[0];
        webController.title = NSLocalizedString(@"Statistics", nil);
        webController.nextUrl = @"/stats/dashboard/";

    } else if ([segue.identifier isEqualToString:SideMenuTableViewControllerShowInformationSegue]) {
        [GAITracker trackScreenForControllerName:@"InformationWebView"];
        UINavigationController *navController = (UINavigationController *)segue.destinationViewController;
        VialerWebViewController *webController = navController.viewControllers[0];
        webController.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:SideMenuTableViewControllerLogoImageName]];
        NSString *onboardingUrl = [Configuration UrlForKey:NSLocalizedString(@"onboarding", @"Reference to URL String in the config.plist to the localized onboarding information page")];
        webController.URL = [NSURL URLWithString:onboardingUrl];

    } else if ([segue.identifier isEqualToString:SideMenuTableViewControllerShowDialPlanSegue]) {
        [GAITracker trackScreenForControllerName:@"DialplanWebview"];
        UINavigationController *navController = (UINavigationController *)segue.destinationViewController;
        VialerWebViewController *webController = navController.viewControllers[0];
        webController.title = NSLocalizedString(@"Dial plan", nil);
        webController.nextUrl = @"/dialplan/";
    }
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

@end
