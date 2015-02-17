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
    kVoIPGRIDHTTPBadCredentials = 403,
};
typedef enum VoIPGRIDHttpErrors VoIPGRIDHttpErrors;

@interface VoIPGRIDRequestOperationManager : AFHTTPRequestOperationManager

+ (VoIPGRIDRequestOperationManager *)sharedRequestOperationManager;

// Log in / Log out
- (void)loginWithUser:(NSString *)user password:(NSString *)password success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
- (void)logout;
+ (BOOL)isLoggedIn;

// User requests
- (void)userDestinationWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
- (void)userProfileWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
- (void)phoneAccountWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
- (void)clickToDialToNumber:(NSString *)toNumber fromNumber:(NSString *)fromNumber success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
- (void)clickToDialStatusForCallId:(NSString *)callId success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
- (void)cdrRecordWithLimit:(NSInteger)limit offset:(NSInteger)offset sourceNumber:(NSString *)sourceNumber callDateGte:(NSDate *)date success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
- (void)passwordResetWithEmail:(NSString *)email success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
- (void)autoLoginTokenWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

@end