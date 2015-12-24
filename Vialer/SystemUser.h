//
//  SystemUser.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

/** SystemUser class is representing the user information as available on the VoIPGRID platform.
 Current the SystemUser class also represents a lot of information maintained/stored by the VoIPGRIDRequestOperationManager in the user defaults.

 */
@interface SystemUser : NSObject

+ (instancetype)currentUser;

- (void)removeCurrentUser;

#pragma mark - Login handling

@property (nonatomic, readonly, getter=isLoggedIn)BOOL loggedIn;

- (void)loginWithUser:(NSString *)user password:(NSString *)password completion:(void(^)(BOOL loggedin))completion;
- (void)logout;

#pragma mark - User/Settings information

// Account information
@property (readonly, nonatomic) NSString *user;
@property (readonly, nonatomic) NSString *displayName;
@property (readonly, nonatomic) NSString *outgoingNumber;
@property (readonly, nonatomic) NSString *mobileNumber;
@property (readonly, nonatomic) NSString *sipAccount;
@property (readonly, nonatomic) NSString *sipPassword;
@property (readonly, nonatomic) NSString *firstName;
@property (readonly, nonatomic) NSString *lastName;

#pragma mark - Sip specific handling

@property (readonly, nonatomic) BOOL isAllowedToSip;
@property (nonatomic, getter=isSipEnabled) BOOL sipEnabled;

- (void)checkSipStatus;
- (void)updateSIPAccountWithSuccess:(void (^)(BOOL success))success;

/**
 Does a API call to update it's properties. Currently outgoingNumber, mobileNumber, firstName and lastName are retrieved.

 @param completion A block giving access to the error variable which, when set, indicates an error condition.
 */
- (void)updateSystemUserFromVGWithCompletion:(void (^)(NSError *error))completion;
@end
