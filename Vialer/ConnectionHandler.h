//
//  ConnectionHandler.h
//  Vialer
//
//  Created by Reinier Wieringa on 19/12/14.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Gossip.h"

typedef enum {
    ConnectionStatusLow  = 0,
    ConnectionStatusHigh = 1,   // WIFI or 4G
} ConnectionStatus;

NSString * const ConnectionStatusChangedNotification;
NSString * const IncomingSIPCallNotification;

@interface ConnectionHandler : NSObject<GSAccountDelegate>

@property (nonatomic, readonly) ConnectionStatus connectionStatus;
@property (nonatomic, readonly) GSAccountStatus accountStatus;
@property (nonatomic, readonly) NSString *sipDomain;

- (void)start;
- (void)sipConnect;
- (void)sipDisconnect;
- (void)sipUpdateConnectionStatus;

+ (ConnectionHandler *)sharedConnectionHandler;

@end
