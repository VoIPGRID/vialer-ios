//
//  SystemUser.h
//  Vialer
//
//  Created by Maarten de Zwart on 14/09/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

/** SystemUser class is representing the user information as available on the VoIPGRID platform.
 Current the SystemUser class also represents a lot of information maintained/stored by the VoIPGRIDRequestOperationManager in the user defaults.
 
 */
@interface SystemUser : NSObject

#pragma mark - Login handling

+ (BOOL)isLoggedIn;

+ (void)loginWithUser:(NSString *)user password:(NSString *)password completion:(void(^)(BOOL loggedin))completion;

+ (void)logout;

#pragma mark - User/Settings information

// Account info
+ (NSString *)user;
+ (NSString *)outgoingNumber;
+ (NSString *)sipAccount;
+ (NSString *)sipPassword;

#pragma mark - Sip specific handling

+ (BOOL)isAllowedToSip;
+ (BOOL)isSipEnabled;
+ (void)enableSip:(BOOL)enabled;
+ (void)updateSIPAccountWithSuccess:(void (^)(BOOL success))success;

@end
