//
//  ReachabilityManager.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "ReachabilityManager.h"

#import <CoreTelephony/CTTelephonyNetworkInfo.h>

#import "Reachability.h"

static NSString * const ReachabilityManagerStatusKey = @"reachabilityStatus";

@interface ReachabilityManager()
@property (strong, nonatomic) Reachability *reachabilityPodInstance;
@property (strong, nonatomic) CTTelephonyNetworkInfo *networkInfo;

@property (nonatomic) ReachabilityManagerStatusType reachabilityStatus;
@end

@implementation ReachabilityManager

#pragma mark - lifecycle
- (void)dealloc {
    [self stopMonitoring];
}

#pragma mark - properties
- (Reachability *)reachabilityPodInstance {
    if (!_reachabilityPodInstance) {
        _reachabilityPodInstance = [Reachability reachabilityForInternetConnection];
    }
    return _reachabilityPodInstance;
}

- (CTTelephonyNetworkInfo *)networkInfo {
    if (!_networkInfo) {
        _networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    }
    return _networkInfo;
}

- (void)setReachabilityStatus:(ReachabilityManagerStatusType)reachabilityStatus {
    if (reachabilityStatus != _reachabilityStatus) {
        [self willChangeValueForKey:ReachabilityManagerStatusKey];
        _reachabilityStatus = reachabilityStatus;
        [self didChangeValueForKey:ReachabilityManagerStatusKey];
    }
}

#pragma mark - start/stop monitoring
- (void)startMonitoring {
    [self currentReachabilityStatus];

    [self.reachabilityPodInstance startNotifier];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged:) name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(radioAccessChanged:) name:CTRadioAccessTechnologyDidChangeNotification object:nil];
}

- (void)stopMonitoring {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CTRadioAccessTechnologyDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [self.reachabilityPodInstance stopNotifier];
}

#pragma mark - Status logic
/**
 *  @return Returns Yes if connection is 4g, otherwise No.
 */
- (BOOL)on4g {
    return [self.networkInfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyLTE];;
}

/**
 *  @return Returns Yes if connection is Wifi, otherwise No.
 */
- (BOOL)onWifi {
    return [self.reachabilityPodInstance isReachableViaWiFi];
}

/**
 *  @return Returns Yes if the device has an internet connection, otherwise No.
 */
- (BOOL)hasInternet {
    return [self.reachabilityPodInstance isReachable];
}

/**
 *  For internal use, the function has a side effect of updating the internal reachability status
 *  which is used in a couple of functions inside this class.
 *
 *  @return The current up to date reability status.
 */
- (ReachabilityManagerStatusType)currentReachabilityStatus {
    if (self.on4g || self.onWifi) {
        self.reachabilityStatus = ReachabilityManagerStatusHighSpeed;
    } else if (self.hasInternet) {
        self.reachabilityStatus = ReachabilityManagerStatusLowSpeed;
    } else {
        self.reachabilityStatus = ReachabilityManagerStatusOffline;
    }
    return self.reachabilityStatus;
}

#pragma mark - Callback functions
- (void)internetConnectionChanged:(NSNotification *)notification {
    [self currentReachabilityStatus];
}

- (void)radioAccessChanged:(NSNotification *)notification {
    [self currentReachabilityStatus];
}

#pragma mark - KVO overrider
// To override default KVO behaviour for the Reachability status property.
+ (BOOL)automaticallyNotifiesObserversOfReachabilityStatus {
    return NO;
}

@end
