//
//  ReachabilityBarViewController.m
//  Vialer
//
//  Created by Bob Voorneveld on 10/11/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "ReachabilityBarViewController.h"

#import "Configuration.h"
#import "SystemUser.h"

@interface ReachabilityBarViewController ()
@property (weak, nonatomic) IBOutlet UILabel *failedConnectionLabel;
@property (weak, nonatomic) IBOutlet UILabel *twoStepLabel;
@property (weak, nonatomic) IBOutlet UIButton *twoStepInfoButton;
@end

@implementation ReachabilityBarViewController

#pragma mark - View LifeCycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateLayout];
}

#pragma mark - properties

- (void)setStatus:(ReachabilityManagerStatusType)status {
    if (_status != status) {
        _status = status;
        [self updateLayout];
    }
}

#pragma mark - layout

- (void)updateLayout {
    self.failedConnectionLabel.hidden = YES;
    self.twoStepLabel.hidden = YES;
    self.twoStepInfoButton.hidden = YES;
    self.view.backgroundColor = nil;
    switch (self.status) {
        case ReachabilityManagerStatusOffline: {
            self.failedConnectionLabel.hidden = NO;
            self.view.backgroundColor = [Configuration tintColorForKey:ConfigurationReachabilityBarBackgroundColor];
            break;
        }
        case ReachabilityManagerStatusTwoStep: {
            if ([SystemUser currentUser].isSipEnabled) {
                self.twoStepLabel.hidden = NO;
                self.twoStepInfoButton.hidden = NO;
                self.view.backgroundColor = [Configuration tintColorForKey:ConfigurationReachabilityBarBackgroundColor];
            }
            break;
        }
        case ReachabilityManagerStatusSIP: {
            break;
        }
    }
}

#pragma mark - actions

- (IBAction)infobuttonPressed:(UIButton *)sender {
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:NSLocalizedString(@"Two step modus", nil)
                                          message:NSLocalizedString(@"Two step modus will setup a call to your phone first and will call the other party when you answer the call.", nil)
                                          preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:nil];

    [alertController addAction:defaultAction];
    [self presentViewController:alertController animated:YES completion:nil];
}


@end
