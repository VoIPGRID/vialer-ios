//
//  SideMenuViewController.m
//  Vialer
//
//  Created by Reinier Wieringa on 4/16/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "SideMenuViewController.h"
#import "UIViewController+MMDrawerController.h"
#import "SideMenuTableViewCell.h"
#import "VoIPGRIDRequestOperationManager.h"
#import "PBWebViewController.h"
#import "SVProgressHUD.h"
#import "InfoCarouselViewController.h"
#import "UIAlertView+Blocks.h"
#import "AccountViewController.h"

#define MENU_INDEX_AVAILABILITY     0
#define MENU_INDEX_STATS            1
#define MENU_INDEX_ROUTING          2
#define MENU_INDEX_INFO             3
#define MENU_INDEX_ACCOUNT          4
//#define MENU_INDEX_AUTOCONNECT      5
#define MENU_INDEX_LOGOUT           5

#define WEBVIEW_TARGET_ACCESSIBILITY    0
#define WEBVIEW_TARGET_DIALPLAN         1
#define WEBVIEW_TARGET_STATISTICS       2

@interface SideMenuViewController ()
@property (strong, nonatomic) NSArray *menuItems;
@property (nonatomic, strong) AccountViewController *accountViewController;
@end

@implementation SideMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIColor *tintColor = [self navigationBarTintColor];
    UIImage *availabilityIcon = [self coloredImageWithImage:[UIImage imageNamed:@"menu-availability"] color:tintColor];
    UIImage *statsIcon = [self coloredImageWithImage:[UIImage imageNamed:@"menu-stats"] color:tintColor];
    UIImage *routingIcon = [self coloredImageWithImage:[UIImage imageNamed:@"menu-routing"] color:tintColor];
    UIImage *infoIcon = [self coloredImageWithImage:[UIImage imageNamed:@"menu-info"] color:tintColor];
    UIImage *accountIcon = [self coloredImageWithImage:[UIImage imageNamed:@"menu-account"] color:tintColor];
    //UIImage *autoconnectIcon = [self coloredImageWithImage:[UIImage imageNamed:@"menu-autoconnect"] color:tintColor];
    
    self.menuItems = @[
        [SideMenuItem sideMenuItemWithTitle:NSLocalizedString(@"Availability", nil) andIcon:availabilityIcon],
        [SideMenuItem sideMenuItemWithTitle:NSLocalizedString(@"Statistics", nil) andIcon:statsIcon],
        [SideMenuItem sideMenuItemWithTitle:NSLocalizedString(@"Routing", nil) andIcon:routingIcon],
        [SideMenuItem sideMenuItemWithTitle:NSLocalizedString(@"Information", nil) andIcon:infoIcon],
        [SideMenuItem sideMenuItemWithTitle:NSLocalizedString(@"Account", nil) andIcon:accountIcon],
        [SideMenuItem sideMenuItemWithTitle:NSLocalizedString(@"Logout", nil) andIcon:nil]
    ];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

#pragma mark - Table view data source
- (void)viewWillAppear:(BOOL)animated {
    //Force a reload of the data to display the proper phone number. Otherwise an old phone number could be displayed if it was changed.
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.menuItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseId = @"SideMenuTableViewCell";
    SideMenuTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    if (!cell) {
        cell = [[SideMenuTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseId];
    }
    
    cell.menuItem = self.menuItems[indexPath.row];

    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 222.f, 144.f)];
        headerView.backgroundColor = [UIColor groupTableViewBackgroundColor];
        
        CGFloat xOffset = (CGRectGetWidth(headerView.frame) - 171.f) / 2;
        UIImageView *logo = [[UIImageView alloc] initWithFrame:CGRectMake(xOffset, 40.f, 171.f, 41.f)];
        logo.image = [UIImage imageNamed:@"logoMedium"];
        
        CGFloat yOffset = CGRectGetMaxY(logo.frame) + 10.f;
        UILabel *numberLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, yOffset, CGRectGetWidth(headerView.frame), 20.f)];
        numberLabel.font = [UIFont systemFontOfSize:14.f];
        numberLabel.textAlignment = NSTextAlignmentCenter;
        numberLabel.textColor = [self navigationBarTintColor];
        
        NSString *phoneNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"MobileNumber"];
        numberLabel.text = [phoneNumber length] ? phoneNumber : NSLocalizedString(@"No mobile number configured", nil);
        
        [headerView addSubview:logo];
        [headerView addSubview:numberLabel];
        
        return headerView;
    } else {
        return nil;
    }
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
                                    [[NSUserDefaults standardUserDefaults] objectForKey:@"User"]];
        
        [message appendFormat:@"\n%@", NSLocalizedString(@"Are you sure you want to log out?", nil)];
        
        [UIAlertView showWithTitle:NSLocalizedString(@"Log out", nil)
                           message:message
                 cancelButtonTitle:NSLocalizedString(@"No", nil)
                 otherButtonTitles:@[NSLocalizedString(@"Yes", nil)]
                          tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                              if (buttonIndex == 1) {
                                  [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] logout];
                              }
                          }];
    }
}

- (AccountViewController *)accountViewController {
    if (!_accountViewController) {
        _accountViewController = [[AccountViewController alloc] initWithNibName:@"AccountViewController" bundle:[NSBundle mainBundle]];
    }
    return _accountViewController;
}

#pragma mark - Private Methods

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
    
    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"]];
    NSAssert(config != nil, @"Config.plist not found!");
    __block NSString *partnerBaseUrl = [[config objectForKey:@"URLS"] objectForKey:@"Partner"];
    NSAssert(partnerBaseUrl != nil, @"URLS - Partner not found in Config.plist!");
    
    [SVProgressHUD showWithStatus:[NSString stringWithFormat:NSLocalizedString(@"Loading %@...", nil), title]];
    
    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] autoLoginTokenWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSString *token = [responseObject objectForKey:@"token"];
            if ([token isKindOfClass:[NSString class]]) {
                NSString *user = [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] user];
                NSURL *url = [NSURL URLWithString:[[NSString stringWithFormat:@"%@/user/autologin/?username=%@&token=%@&next=%@", partnerBaseUrl, user, token, nextUrl] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
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
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.accountViewController];
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(navigationDidTapCancel)];
    self.accountViewController.navigationItem.leftBarButtonItem = cancelButton;
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)showInfoScreen {
    InfoCarouselViewController *infoCarouselViewController = [[InfoCarouselViewController alloc] initWithNibName:@"InfoCarouselViewController" bundle:[NSBundle mainBundle]];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:infoCarouselViewController];
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(navigationDidTapCancel)];
    infoCarouselViewController.navigationItem.leftBarButtonItem = cancelButton;
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
    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"]];
    NSAssert(config != nil, @"Config.plist not found!");
    NSArray *navigationBarColor = [[config objectForKey:@"Tint colors"] objectForKey:@"NavigationBar"];
    NSAssert(navigationBarColor != nil && navigationBarColor.count == 3, @"Tint colors - NavigationBar not found in Config.plist!");
    return [UIColor colorWithRed:[navigationBarColor[0] intValue] / 255.f green:[navigationBarColor[1] intValue] / 255.f blue:[navigationBarColor[2] intValue] / 255.f alpha:1.f];
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
