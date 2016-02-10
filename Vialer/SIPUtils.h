//
//  SIPUtils.h
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SIPUtils : NSObject

/**
 *  Setup the SIP endpoint with the VialerSIPLib.
 *
 *  @return BOOL
 */
+ (BOOL)setupSIPEndpoint;

/**
 *  Remove the SIP endpoint.
 */
+ (void)removeSIPEndpoint;

@end
