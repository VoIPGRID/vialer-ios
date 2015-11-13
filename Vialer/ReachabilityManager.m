//
//  ReachabilityManager.m
//  Vialer
//
//  Created by Bob Voorneveld on 10/11/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "ReachabilityManager.h"

#import <CoreTelephony/CTTelephonyNetworkInfo.h>

#import "Reachability.h"

static NSString * const ReachabilityManagerStatusKey = @"status";

@interface ReachabilityManager()
@property (nonatomic, strong) Reachability *reachabilityManager;
@property (nonatomic, strong) CTTelephonyNetworkInfo *networkInfo;
@property (nonatomic) BOOL on4g;
@property (nonatomic) BOOL onWifi;
@property (nonatomic) BOOL hasInternet;
@end

@implementation ReachabilityManager

#pragma mark - lifecycle

- (void)dealloc {
    [self stopMonitoring];
}

#pragma mark - properties

- (Reachability *)reachabilityManager {
    if (!_reachabilityManager) {
        _reachabilityManager = [Reachability reachabilityForInternetConnection];
    }
    return _reachabilityManager;
}

- (CTTelephonyNetworkInfo *)networkInfo {
    if (!_networkInfo) {
        _networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    }
    return _networkInfo;
}

- (void)setOn4g:(BOOL)on4g {
    _on4g = on4g;
    [self updateStatus];
}

- (void)setOnWifi:(BOOL)onWifi {
    _onWifi = onWifi;
    [self updateStatus];
}

- (void)setHasInternet:(BOOL)hasInternet {
    _hasInternet = hasInternet;
    [self updateStatus];
}

/**
 Overridden setter for status to manually fire KVO notifications only when the status actually changes
 */
- (void)setStatus:(ReachabilityManagerStatusType)status {
    if (_status != status) {
        [self willChangeValueForKey:ReachabilityManagerStatusKey];
        _status = status;
        [self didChangeValueForKey:ReachabilityManagerStatusKey];
    }
}

#pragma mark - start/stop monitoring

- (void)startMonitoring {
    // Check connections before monitoring
    [self check4gStatus];
    [self checkInternetAccess];

    // Start monitoring
    [self.reachabilityManager startNotifier];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged:) name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(radioAccessChanged:) name:CTRadioAccessTechnologyDidChangeNotification object:nil];
}

- (void)stopMonitoring {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.reachabilityManager stopNotifier];
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    if ([key isEqualToString:ReachabilityManagerStatusKey]) {
        return NO;
    } else {
        return [super automaticallyNotifiesObserversForKey:key];
    }

}

#pragma mark - update status

- (void)check4gStatus {
    self.on4g = [self.networkInfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyLTE];
}

- (void)checkInternetAccess {
    self.hasInternet = [self.reachabilityManager isReachable];
    self.onWifi = [self.reachabilityManager isReachableViaWiFi];
}

- (void)updateStatus {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.on4g || self.onWifi) {
            self.status = ReachabilityManagerStatusSIP;
        } else if (self.hasInternet) {
            self.status = ReachabilityManagerStatusTwoStep;
        } else {
            self.status = ReachabilityManagerStatusOffline;
        }
    });
}

#pragma mark - notifications

- (void)internetConnectionChanged:(NSNotification *)notification {
    [self checkInternetAccess];
}

- (void)radioAccessChanged:(NSNotification *)notification {
    [self check4gStatus];
}

@end
