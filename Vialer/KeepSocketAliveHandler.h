//
//  KeepSocketAliveHandler.h
//  Vialer
//
//  Created by Reinier Wieringa on 19/02/15.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeepSocketAliveHandler : NSObject<NSStreamDelegate>

+ (KeepSocketAliveHandler *)sharedKeepSocketAliveHandler;

@end
