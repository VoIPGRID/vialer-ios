//
//  ConnectionStatusHandler.m
//  Vialer
//
//  Created by Reinier Wieringa on 19/12/14.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "ConnectionStatusHandler.h"

#import "AFNetworkReachabilityManager.h"

#import <CoreTelephony/CTTelephonyNetworkInfo.h>

NSString * const ConnectionStatusChangedNotification = @"com.vialer.ConnectionStatusChangedNotification";

@interface ConnectionStatusHandler ()
@property (nonatomic, assign) BOOL isOnWiFi;
@property (nonatomic, assign) BOOL isOn4G;
@end

@implementation ConnectionStatusHandler

+ (ConnectionStatusHandler *)sharedConnectionStatusHandler {
    static dispatch_once_t pred;
    static ConnectionStatusHandler *_sharedConnectionStatusHandler = nil;

    dispatch_once(&pred, ^{
        _sharedConnectionStatusHandler = [[self alloc] init];
    });
    return _sharedConnectionStatusHandler;
}

- (id)init {
    self = [super init];
    if (self != nil) {
    }
    return self;
}

- (void)connectionStatusChanged {
    NSLog(@"connectionStatusChanged: WIFI %@, 4G %@", self.isOnWiFi ? @"YES" : @"-", self.isOn4G ? @"YES" : @"-");
    self.connectionStatus = (self.isOn4G || self.isOnWiFi) ? ConnectionStatusHigh : ConnectionStatusLow;
    [[NSNotificationCenter defaultCenter] postNotificationName:ConnectionStatusChangedNotification object:self];
}

- (void)start {
    // Check if radio access is at least 4G
    CTTelephonyNetworkInfo *telephonyInfo = [[CTTelephonyNetworkInfo alloc] init];
    self.isOn4G = [telephonyInfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyLTE];
//    self.isOn4G = [telephonyInfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyWCDMA];
    [NSNotificationCenter.defaultCenter addObserverForName:CTRadioAccessTechnologyDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification *notification) {
        self.isOn4G = [notification.object isEqualToString:CTRadioAccessTechnologyLTE];
//        self.isOn4G = [notification.object isEqualToString:CTRadioAccessTechnologyWCDMA];
        [self connectionStatusChanged];
    }];

    // Check WiFi or no WiFi
    self.isOnWiFi = [AFNetworkReachabilityManager sharedManager].reachableViaWiFi;
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        self.isOnWiFi = (status == AFNetworkReachabilityStatusReachableViaWiFi);
        [self connectionStatusChanged];
    }];
}

@end
