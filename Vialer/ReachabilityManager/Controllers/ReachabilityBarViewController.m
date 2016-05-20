//
//  ReachabilityBarViewController.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "ReachabilityBarViewController.h"

#import "Configuration.h"
#import "SystemUser.h"

@interface ReachabilityBarViewController ()
@property (weak, nonatomic) IBOutlet UILabel *informationLabel;
@property (weak, nonatomic) IBOutlet UIButton *twoStepInfoButton;
@property (strong, nonatomic) ReachabilityManager *reachabilityManager;
@property (strong, nonatomic) SystemUser *currentUser;
@property (assign) BOOL shouldBeVisible;
@end

@implementation ReachabilityBarViewController

#pragma mark - View LifeCycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupReachability) name:UIApplicationDidBecomeActiveNotification object:nil];
    [self.currentUser addObserver:self forKeyPath:NSStringFromSelector(@selector(sipAllowed)) options:0 context:NULL];
    [self.currentUser addObserver:self forKeyPath:NSStringFromSelector(@selector(sipEnabled)) options:0 context:NULL];
    [self setupReachability];
    [self updateLayout];
    [self.delegate reachabilityBar:self statusChanged:self.reachabilityManager.reachabilityStatus];
}

- (void)viewWillDisappear:(BOOL)animated {
    @try{
        [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:UIApplicationDidBecomeActiveNotification];
    }@catch(id exception) {}
    [self.currentUser removeObserver:self forKeyPath:NSStringFromSelector(@selector(sipAllowed))];
    [self.currentUser removeObserver:self forKeyPath:NSStringFromSelector(@selector(sipEnabled))];
    [self teardownReachability];
    [super viewWillDisappear:animated];
}

#pragma mark - Properties

- (ReachabilityManager *)reachabilityManager {
    if (!_reachabilityManager) {
        _reachabilityManager = [[ReachabilityManager alloc] init];
    }
    return _reachabilityManager;
}

- (SystemUser *)currentUser {
    if (!_currentUser) {
        _currentUser = [SystemUser currentUser];
    }
    return _currentUser;
}

#pragma mark - Layout

- (void)updateLayout {
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL shouldBeVisible = NO;
        self.twoStepInfoButton.hidden = YES;

        switch (self.reachabilityManager.reachabilityStatus) {
            case ReachabilityManagerStatusOffline: {
                self.informationLabel.text = NSLocalizedString(@"No connection, cannot call.", nil);
                shouldBeVisible = YES;
                break;
            }
            case ReachabilityManagerStatusLowSpeed: {
                if ([SystemUser currentUser].sipEnabled) {
                    self.informationLabel.text = NSLocalizedString(@"Poor connection, Two step calling enabled.", nil);
                    self.twoStepInfoButton.hidden = NO;
                    shouldBeVisible = YES;
                } else {
                    self.informationLabel.text = @"";
                }
                break;
            }
            case ReachabilityManagerStatusHighSpeed: {
                if (!self.currentUser.sipEnabled && self.currentUser.sipAllowed) {
                    self.informationLabel.text = NSLocalizedString(@"VoIP disabled, enable in settings", nil);
                    shouldBeVisible = YES;
                } else {
                    self.informationLabel.text = @"";
                }
                break;
            }
        }

        if (shouldBeVisible) {
            self.view.backgroundColor = [[Configuration defaultConfiguration] tintColorForKey:ConfigurationReachabilityBarBackgroundColor];
        } else {
            self.view.backgroundColor = nil;
        }

        if ([self.delegate respondsToSelector:@selector(reachabilityBar:shouldBeVisible:)]) {
            self.shouldBeVisible = shouldBeVisible;
            [self.delegate reachabilityBar:self shouldBeVisible:shouldBeVisible];
        }

        [self.delegate reachabilityBar:self statusChanged:self.reachabilityManager.reachabilityStatus];
    });
}

#pragma mark - Actions

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

#pragma mark - Notificationcenter actions

- (void)setupReachability {
    [self.reachabilityManager addObserver:self forKeyPath:NSStringFromSelector(@selector(reachabilityStatus)) options:0 context:NULL];
    [self.reachabilityManager startMonitoring];
}

- (void)teardownReachability {
    [self.reachabilityManager removeObserver:self forKeyPath:NSStringFromSelector(@selector(reachabilityStatus))];
    self.reachabilityManager = nil;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    // Keep track of connection status from reachabilityManager.
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(reachabilityStatus))] ||
        [keyPath isEqualToString:NSStringFromSelector(@selector(sipAllowed))] ||
        [keyPath isEqualToString:NSStringFromSelector(@selector(sipEnabled))]) {
        [self updateLayout];
    }
}
@end
