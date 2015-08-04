//
//  VoIPGRIDRequestOperationManager.h
//  Vialer
//
//  Created by Reinier Wieringa on 31/10/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "AFHTTPRequestOperationManager.h"

#define LOGIN_FAILED_NOTIFICATION @"login.failed"
#define LOGIN_SUCCEEDED_NOTIFICATION @"login.succeeded"

enum VoIPGRIDHttpErrors {
    kVoIPGRIDHTTPBadCredentials = 401,
};
typedef enum VoIPGRIDHttpErrors VoIPGRIDHttpErrors;

@interface VoIPGRIDRequestOperationManager : AFHTTPRequestOperationManager

+ (VoIPGRIDRequestOperationManager *)sharedRequestOperationManager;

// Log in / Log out
- (void)loginWithUser:(NSString *)user password:(NSString *)password success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
- (void)logout;
+ (BOOL)isLoggedIn;

// Account info
- (NSString *)user;
- (NSString *)outgoingNumber;
- (NSString *)sipAccount;
- (NSString *)sipPassword;

// User requests
- (void)userDestinationWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
- (void)userProfileWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
- (void)phoneAccountWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
- (void)clickToDialToNumber:(NSString *)toNumber fromNumber:(NSString *)fromNumber success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
- (void)clickToDialStatusForCallId:(NSString *)callId success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
- (void)cdrRecordWithLimit:(NSInteger)limit offset:(NSInteger)offset sourceNumber:(NSString *)sourceNumber callDateGte:(NSDate *)date success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
- (void)passwordResetWithEmail:(NSString *)email success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
- (void)autoLoginTokenWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 * Pushes the user's mobile number to the server
 * @param mobileNumber the mobile number to push
 * @param succes the block being called on success
 * @param failure the block being called on failure including the NSError and a userFriendlyErrorString which can be presented to the user because it is serverside localized
 */
- (void)pushMobileNumber:(NSString *)mobileNumber success:(void (^)())success  failure:(void (^)(NSError *error, NSString *userFriendlyErrorString))failure;
@end