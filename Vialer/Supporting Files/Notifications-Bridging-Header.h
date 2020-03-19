//
//  Notifications-Bridging-Header.h
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

#ifndef Notifications_Bridging_Header_h
#define Notifications_Bridging_Header_h

#pragma mark - AppDelegate
static NSString * const AppDelegateIncomingCallNotification = @"AppDelegateIncomingCallNotification";
static NSString * const AppDelegateIncomingBackgroundCallAcceptedNotification = @"AppDelegateIncomingBackgroundCallAcceptedNotification";
static NSString * const AppDelegateStartConnectABCallNotification = @"AppDelegateStartConnectABCallNotification";
static NSString * const AppDelegateStartConnectABCallUserInfoKey = @"PhoneNumber";
static NSString * const ReachabilityChangedNotification = @"ReachabilityChangedNotification";
static NSString * const NetworkChangedNotification = @"VSLNetworkMonitorChangedNotification" ; //orp @"VSLNetworkMonitorChangedNotification" @"kReachabilityChangedNotification"
#endif /* Notifications_Bridging_Header_h */
