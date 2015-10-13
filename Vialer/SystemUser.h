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

+ (instancetype)currentUser;

- (void)removeCurrentUser;

+ (instancetype)initWithUserDict:(NSDictionary *)userDict withUsername:(NSString *)username andPassword:(NSString *)password;

#pragma mark - Login handling

@property (nonatomic, readonly, getter=isLoggedIn) BOOL loggedIn;

- (void)loginWithUser:(NSString *)user password:(NSString *)password completion:(void(^)(BOOL loggedin))completion;

- (void)logout;

#pragma mark - User/Settings information

// Account information
@property (nonatomic, readonly) NSString *user;
@property (nonatomic, readonly) NSString *displayName;
@property (nonatomic, readonly) NSString *outgoingNumber;
@property (nonatomic, readonly) NSString *mobileNumber;
@property (nonatomic, readonly) NSString *sipAccount;
@property (nonatomic, readonly) NSString *sipPassword;

@property (nonatomic, readonly) NSString *localizedOutgoingNumber;

#pragma mark - Sip specific handling

@property (nonatomic, readonly) BOOL isAllowedToSip;
@property (nonatomic, assign, getter=isSipEnabled) BOOL sipEnabled;

- (void)checkSipStatus;
- (void)updateSIPAccountWithSuccess:(void (^)(BOOL success))success;

@end
