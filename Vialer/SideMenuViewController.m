//
//  SideMenuViewController.m
//  Vialer
//
//  Created by Reinier Wieringa on 4/16/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "SideMenuViewController.h"

#import "SettingsViewController.h"
#import "SideMenuHeaderView.h"
#import "SideMenuTableViewCell.h"
#import "SystemUser.h"
#import "UIAlertView+Blocks.h"
#import "UIViewController+MMDrawerController.h"
#import "VoIPGRIDRequestOperationManager.h"

#import "PBWebViewController.h"
#import "SVProgressHUD.h"

typedef enum : NSUInteger {
    MENU_INDEX_STATS = 0,
    MENU_INDEX_INFO,
    MENU_INDEX_ACCOUNT,
    MENU_INDEX_ROUTING,
    MENU_INDEX_LOGOUT,
    MENU_ITEM_COUNT,
    // Items after this line are disabled (not shown in the menu)
    MENU_INDEX_AVAILABILITY,
    MENU_INDEX_AUTOCONNECT
} SideMenuItems;

#define WEBVIEW_TARGET_DIALPLAN         0
#define WEBVIEW_TARGET_ACCESSIBILITY    1
#define WEBVIEW_TARGET_STATISTICS       2

@interface SideMenuViewController ()
@property (nonatomic, strong) SettingsViewController *settingsViewController;
@property (nonatomic, strong) UIColor *tintColor;
@property (nonatomic, strong) UIImageView *logoImageView;
@property (nonatomic, strong) SideMenuHeaderView *headerView;
@end

@implementation SideMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tintColor = [self navigationBarTintColor];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

#pragma mark - Table view data source
- (void)viewWillAppear:(BOOL)animated {
    //Force a reload of the data to display the proper phone number. Otherwise an old phone number could be displayed if it was changed.
    [self reloadUserData];

    CGFloat yOffset = CGRectGetMaxY(self.view.bounds) - 18.f;
    CGRect versionBuildLabelFrame = CGRectMake(0, yOffset, CGRectGetWidth(self.view.frame), 20.f);
    [self.view addSubview:[self versionBuildLabel:versionBuildLabelFrame]];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MENU_ITEM_COUNT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseId = @"SideMenuTableViewCell";
    SideMenuTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    if (!cell) {
        cell = [[SideMenuTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseId];
    }

    // Special styling for the Logout item
    if (indexPath.row == MENU_INDEX_LOGOUT) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.separatorInset = UIEdgeInsetsMake(0.0, self.view.bounds.size.width, 0.0, 0.0);
    }

    switch (indexPath.row) {
        case MENU_INDEX_STATS:
            [cell setMenuItemTitle:NSLocalizedString(@"Statistics", nil)
                           andIcon:[self coloredImageWithImage:[UIImage imageNamed:@"menu-stats"] color:self.tintColor]];
            break;
        case MENU_INDEX_INFO:
            [cell setMenuItemTitle:NSLocalizedString(@"Information", nil)
                           andIcon:[self coloredImageWithImage:[UIImage imageNamed:@"menu-info"] color:self.tintColor]];
            break;
        case MENU_INDEX_ACCOUNT:
            [cell setMenuItemTitle:NSLocalizedString(@"Settings", nil)
                           andIcon:[self coloredImageWithImage:[UIImage imageNamed:@"menu-settings"] color:self.tintColor]];
            break;
        case MENU_INDEX_LOGOUT:
            [cell setMenuItemTitle:NSLocalizedString(@"Logout", nil)
                           andIcon:[self coloredImageWithImage:[UIImage imageNamed:@"menu-logout"] color:self.tintColor]];
            break;
        case MENU_INDEX_AVAILABILITY:
            [cell setMenuItemTitle:NSLocalizedString(@"Availability", nil)
                           andIcon:[self coloredImageWithImage:[UIImage imageNamed:@"menu-availability"] color:self.tintColor]];
            break;
        case MENU_INDEX_ROUTING:
            [cell setMenuItemTitle:NSLocalizedString(@"Routing", nil)
                           andIcon:[self coloredImageWithImage:[UIImage imageNamed:@"menu-routing"] color:self.tintColor]];
            break;
        case MENU_INDEX_AUTOCONNECT:
            [cell setMenuItemTitle:NSLocalizedString(@"Autoconnect", nil)
                           andIcon:[self coloredImageWithImage:[UIImage imageNamed:@"menu-autoconnect"] color:self.tintColor]];
            break;
        default:
            [cell setMenuItemTitle:nil andIcon:nil];
            break;
    }
    return cell;
}

- (void)reloadUserData {
    SystemUser *user = [SystemUser currentUser];
    self.headerView.phoneNumber = user.localizedOutgoingNumber;
    self.headerView.displayName = user.displayName;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return self.headerView;
    }
    return nil;
}

- (SideMenuHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [[SideMenuHeaderView alloc] initWithFrame:CGRectMake(0, 0, 222.f, 144.f) andTintColor:self.tintColor];
    }
    return _headerView;
}

- (UILabel *)versionBuildLabel:(CGRect)frame {
    UILabel *versionBuildLabel = [[UILabel alloc] initWithFrame:frame];
    versionBuildLabel.font = [UIFont systemFontOfSize:10.f];
    versionBuildLabel.textAlignment = NSTextAlignmentCenter;
    versionBuildLabel.textColor = [UIColor darkGrayColor];
    versionBuildLabel.text = [self appVersionBuildString];

    return versionBuildLabel;
}

- (NSString *)appVersionBuildString {
    NSDictionary *infoDict = [NSBundle mainBundle].infoDictionary;
    NSMutableString *versionString = [NSMutableString stringWithFormat:@"v:%@", [infoDict objectForKey:@"CFBundleShortVersionString"]];
    //We sometimes use a tag the likes of 2.0.beta.03. Since Apple only wants numbers and dots as CFBundleShortVersionString
    //the additional part of the tag is stored in de plist by the update_version_number script. If set, display
    NSString *additionalVersionString = [infoDict objectForKey:@"Additional_Version_String"];
    if ([additionalVersionString length] >0)
        [versionString appendFormat:@".%@", additionalVersionString];
    NSString *version = [NSString stringWithFormat:@"%@ (%@)",
                         versionString,
                         [infoDict objectForKey:@"CFBundleVersion"]];

#if DEBUG
    version = [NSString stringWithFormat:@"%@ (%@) | %@",
               versionString,
               [infoDict objectForKey:@"CFBundleVersion"],
               [infoDict objectForKey:@"Commit_Short_Hash"]];
#endif
    return version;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 144.f;
    } else {
        return 0;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];

    if (indexPath.row == MENU_INDEX_AVAILABILITY) {
        [self showWebViewScreen:WEBVIEW_TARGET_ACCESSIBILITY];
    } else if (indexPath.row == MENU_INDEX_STATS) {
        [self showWebViewScreen:WEBVIEW_TARGET_STATISTICS];
    } else if (indexPath.row == MENU_INDEX_ROUTING) {
        [self showWebViewScreen:WEBVIEW_TARGET_DIALPLAN];
    } else if (indexPath.row == MENU_INDEX_INFO) {
        [self showInfoScreen];
    } else if (indexPath.row == MENU_INDEX_ACCOUNT) {
        [self showAccountView];
        //} else if (indexPath.row == MENU_INDEX_AUTOCONNECT) {

    } else if (indexPath.row == MENU_INDEX_LOGOUT) {

        NSMutableString *message = [NSMutableString stringWithFormat:NSLocalizedString(@"%@\nis currently logged in.", nil),
                                    [SystemUser currentUser].displayName];

        [message appendFormat:@"\n%@", NSLocalizedString(@"Are you sure you want to log out?", nil)];

        [UIAlertView showWithTitle:NSLocalizedString(@"Log out", nil)
                           message:message
                 cancelButtonTitle:NSLocalizedString(@"No", nil)
                 otherButtonTitles:@[NSLocalizedString(@"Yes", nil)]
                          tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                              if (buttonIndex == 1) {
                                  [[SystemUser currentUser] logout];
                              }
                          }];
    }
}

- (SettingsViewController *)settingsViewController {
    if (!_settingsViewController) {
        _settingsViewController = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:[NSBundle mainBundle]];
    }
    return _settingsViewController;
}

#pragma mark - Private Methods

// Correctly encode according to RFC 3986
- (NSString *)urlEncodedString:(NSString *)toEncode {
    if (!toEncode) {
        return @"";
    }
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                 (CFStringRef)toEncode,
                                                                                 NULL,
                                                                                 (CFStringRef) @"!*'();:@&=+$,/?%#[]",  // RFC 3986 characters
                                                                                 kCFStringEncodingUTF8));
}

- (void)showWebViewScreen:(int)webviewTarget {
    __block NSString *title = @"";
    __block NSString *nextUrl = @"";

    if (webviewTarget == WEBVIEW_TARGET_ACCESSIBILITY) {
        title = NSLocalizedString(@"Accessibility", nil);
        nextUrl = NSLocalizedString(@"/dashboard/", nil);
    } else if (webviewTarget == WEBVIEW_TARGET_DIALPLAN) {
        title = NSLocalizedString(@"Dial plan", nil);
        nextUrl = NSLocalizedString(@"/dialplan/", nil);
    } else if (webviewTarget == WEBVIEW_TARGET_STATISTICS) {
        title = NSLocalizedString(@"Statistics", nil);
        nextUrl = NSLocalizedString(@"/stats/dashboard/", nil);
    }

    __block NSString *partnerBaseUrl = [Configuration UrlForKey:@"Partner"];

    [SVProgressHUD showWithStatus:[NSString stringWithFormat:NSLocalizedString(@"Loading %@...", nil), title]];

    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] autoLoginTokenWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSString *token = [responseObject objectForKey:@"token"];
            if ([token isKindOfClass:[NSString class]]) {
                // Encode the token and nextUrl, and also the user after retrieving it.
                token = [self urlEncodedString:token];
                nextUrl = [self urlEncodedString:nextUrl];
                NSString *user = [self urlEncodedString:[SystemUser currentUser].user];
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/user/autologin/?username=%@&token=%@&next=%@", partnerBaseUrl, user, token, nextUrl]];
                NSLog(@"Go to url: %@", url);

                PBWebViewController *webViewController = [[PBWebViewController alloc] init];
                webViewController.URL = url;
                webViewController.title = title;
                webViewController.showsNavigationToolbar = YES;
                webViewController.hidesBottomBarWhenPushed = YES;

                UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];

                UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(navigationDidTapCancel)];
                webViewController.navigationItem.leftBarButtonItem = cancelButton;

                [self presentViewController:navController animated:YES completion:nil];
            }
            [SVProgressHUD dismiss];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error %@", [error localizedDescription]);
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:NSLocalizedString(@"Failed to load %@", nil), title]];
    }];
}

- (void)showAccountView {
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.settingsViewController];
    // Place a done button
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(navigationDidTapCancel)];
    self.settingsViewController.navigationItem.rightBarButtonItem = doneButton;
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)showInfoScreen {
    PBWebViewController *webViewController = [[PBWebViewController alloc] init];

    NSString *onboardingUrl = [Configuration UrlForKey:NSLocalizedString(@"onboarding", @"Reference to URL String in the config.plist to the localized onboarding information page")];
    webViewController.URL = [NSURL URLWithString:onboardingUrl];
    webViewController.showsNavigationToolbar = YES;
    webViewController.hidesBottomBarWhenPushed = YES;
    webViewController.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(navigationDidTapCancel)];
    webViewController.navigationItem.rightBarButtonItem = cancelButton;

    [self presentViewController:navController animated:YES completion:nil];
}

#pragma mark - Selectors

- (void)navigationDidTapCancel {
    if (self.presentedViewController) {
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Utils

- (UIColor *)navigationBarTintColor {
    return [Configuration tintColorForKey:kTintColorNavigationBar];
}

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

#pragma mark - SideMenuItem

@implementation SideMenuItem

+ (instancetype)sideMenuItemWithTitle:(NSString *)title andIcon:(UIImage *)icon {
    SideMenuItem *item = [[SideMenuItem alloc] init];
    item.title = title;
    item.icon = icon;
    return item;
}

@end
