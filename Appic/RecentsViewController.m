//
//  RecentsViewController.m
//  Appic
//
//  Created by Reinier Wieringa on 06/11/13.
//  Copyright (c) 2013 Voys. All rights reserved.
//

#import "RecentsViewController.h"
#import "VoysRequestOperationManager.h"

#import "SVProgressHUD.h"

@interface RecentsViewController ()
@property (nonatomic, assign) BOOL fetching;
@end

@implementation RecentsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Recents", nil);
        self.tabBarItem.image = [UIImage imageNamed:@"recents"];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]]];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (!self.fetching) {
        self.fetching = YES;

        NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
        [offsetComponents setMonth:-1];

        NSDate *lastMonth = [[NSCalendar currentCalendar] dateByAddingComponents:offsetComponents toDate:[NSDate date] options:0];

        [SVProgressHUD showWithStatus:NSLocalizedString(@"Fetching recents", nil)];
        [[VoysRequestOperationManager sharedRequestOperationManager] cdrRecordWithLimit:2 offset:0 callDateGte:lastMonth success:^(AFHTTPRequestOperation *operation, id responseObject) {
            self.fetching = NO;
            [SVProgressHUD dismiss];
            NSLog(@"%@", responseObject);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            self.fetching = NO;
            [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
        }];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

@end
