//
//  GoToViewController.m
//  Vialer
//
//  Created by Reinier Wieringa on 13/08/14.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "GoToViewController.h"
#import "VoIPGRIDRequestOperationManager.h"

#import "PBWebViewController.h"
#import "SVProgressHUD.h"

@interface GoToViewController ()
@property (nonatomic, strong) NSString *partnerBaseUrl;
@property (nonatomic, strong) NSArray *texts;
@property (nonatomic, strong) NSArray *detailTexts;
@property (nonatomic, strong) NSArray *icons;
@property (nonatomic, strong) NSArray *targetUrls;
@end

@implementation GoToViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Go to", nil);
        self.tabBarItem.image = [UIImage imageNamed:@"goto"];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]]];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"]];
    NSAssert(config != nil, @"Config.plist not found!");

    self.partnerBaseUrl = [[config objectForKey:@"URLS"] objectForKey:@"Partner"];
    NSAssert(self.partnerBaseUrl != nil, @"URLS - Partner not found in Config.plist!");

    self.texts = @[NSLocalizedString(@"Dial plan", nil), NSLocalizedString(@"Statistics", nil), NSLocalizedString(@"Accessibility", nil)];
    self.detailTexts = @[NSLocalizedString(@"Change your dial plan", nil), NSLocalizedString(@"Show statistics about your accessibility", nil), NSLocalizedString(@"Change your accessibility", nil)];
    self.icons = @[@"dialPlan", @"statistics", @"accessibility"];
    self.targetUrls = @[@"/dialplan/", @"/stats/dashboard/", @"/dashboard/"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Tableview datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.texts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"GoToCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }

    cell.textLabel.text = self.texts[indexPath.row];
    cell.detailTextLabel.text = self.detailTexts[indexPath.row];
    
    UIImage *iconImage = [UIImage imageNamed:self.icons[indexPath.row]];
    if (iconImage) {
        cell.imageView.image = iconImage;
    }

    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    __block NSString *title = self.texts[indexPath.row];
    __block NSString *nextUrl = self.targetUrls[indexPath.row];
    
    [SVProgressHUD showWithStatus:[NSString stringWithFormat:NSLocalizedString(@"Loading %@...", nil), title]];

    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] autoLoginTokenWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSString *token = [responseObject objectForKey:@"token"];
            if ([token isKindOfClass:[NSString class]]) {
                NSString *user = [[NSUserDefaults standardUserDefaults] objectForKey:@"User"];
                NSURL *url = [NSURL URLWithString:[[NSString stringWithFormat:@"%@/user/autologin/?username=%@&token=%@&next=%@", self.partnerBaseUrl, user, token, nextUrl] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                NSLog(@"Go to url: %@", url);

                PBWebViewController *webViewController = [[PBWebViewController alloc] init];
                webViewController.URL = url;
                webViewController.title = title;
                webViewController.showsNavigationToolbar = NO;

                [self.navigationController pushViewController:webViewController animated:YES];
            }
            [SVProgressHUD dismiss];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error %@", [error localizedDescription]);
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:NSLocalizedString(@"Failed to load %@", nil), title]];
    }];
}

@end
