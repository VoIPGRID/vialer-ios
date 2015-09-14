//
//  WelcomeViewController.h
//  Vialer
//
//  Created by Reinier Wieringa on 08/09/14.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TrackedViewController.h"

@class WelcomeViewController;

@protocol WelcomeViewControllerDelegate <NSObject>
- (void)welcomeViewControllerDidFinish:(WelcomeViewController *)welcomeViewController;
@end

@interface WelcomeViewController : TrackedViewController<UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UITableViewCell *welcomeTableViewCell;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (strong, nonatomic) IBOutlet UILabel *phoneNumberLabel;
@property (strong, nonatomic) IBOutlet UIButton *okButton;
@property (nonatomic, assign) id <WelcomeViewControllerDelegate> delegate;

- (IBAction)okButtonPressed:(UIButton *)sender;
@end
