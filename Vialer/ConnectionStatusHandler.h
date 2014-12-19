//
//  ConnectionStatusHandler.h
//  Vialer
//
//  Created by Reinier Wieringa on 19/12/14.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    ConnectionStatusLow  = 0,
    ConnectionStatusHigh = 1,
} ConnectionStatus;

NSString * const ConnectionStatusChangedNotification;

@interface ConnectionStatusHandler : NSObject

@property (nonatomic, assign) ConnectionStatus connectionStatus;

- (void)start;

+ (ConnectionStatusHandler *)sharedConnectionStatusHandler;

@end
