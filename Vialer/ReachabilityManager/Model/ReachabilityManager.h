//
//  ReachabilityManager.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

@import UIKit;

/**
 *  Enum indicating the quality of the current network connection.
 */
typedef NS_ENUM(NSInteger, ReachabilityManagerStatusType) {
    /**
     *  A high speed network connection is available, 4g or wifi.
     */
    ReachabilityManagerStatusHighSpeed,
    /**
     *  Only a limited, low speed network connection available, 3g or lower.
     */
    ReachabilityManagerStatusLowSpeed,
    /**
     *  Offline, no network connection available.
     */
    ReachabilityManagerStatusOffline,
};

/**
 *  Enum indicating the type of the current connection as an int.
 *
 *  Is used by google Analytics and is aligned between the apps.
 *  See the "Google Analytics evetns for all Mobile apps" document.
 */
typedef NS_ENUM(NSInteger, ReachabilityManagerConnectionType) {
    /**
     *  When non of the other types are valid.
     */
    ReachabilityManagerConnectionTypeOther = 0,
    /**
     *  Indicating a Wifi connection.
     */
    ReachabilityManagerConnectionTypeWifi,
    /**
     *  Indicating a 4G connection.
     */
    ReachabilityManagerConnectionType4g,
};

/**
 *  Manager for keeping track of the device's reachability.
 *
 *  The reachability manager can be used in 2 ways:
 *  1) You can obtain the current reachability status directly by calling currentReachabilityStatus.
 *  2) You can setup KVO on the reachabilityStatus property and recieve updates on changes.
 *     In this case you will need to call startMonitoring to start a Listener on the current connection type.
 */
@interface ReachabilityManager : NSObject

/**
 *  Property indicates the device's current connection Status.
 *
 *  When querying the property directly, it will give the current connection Status.
 *  The property is KVO compliant but you will need to call the startMonitoring function.
 */
@property (readonly, nonatomic) ReachabilityManagerStatusType reachabilityStatus;

/**
 *  Direct way of obtaining the managers current reachability.
 *
 *  @return The current reachability of the manager.
 */
- (ReachabilityManagerStatusType)currentReachabilityStatus;

/**
 *  Indicates the current connection type by returning a value defined in ReachabilityManagerConnectionType.
 *
 *  @return An int indicating the current connection type.
 */
- (ReachabilityManagerConnectionType)currentConnectionType;

/**
 *  Resetting the CTTelephonyNetworkInfo instance and then getting the current reachability status
 *
 *  @return The current reachability of the manager.
 */
- (ReachabilityManagerStatusType)resetAndGetCurrentReachabilityStatus;

/**
 *  Listener start function.
 *
 *  Start the periodic listener which updates the reachabilityStatus automatically.
 */
- (void)startMonitoring;

/**
 *  Listener stop function.
 *
 *  Stop the periodic listener which updates the reachabilityStatus automatically.
 */
- (void)stopMonitoring;

@end
