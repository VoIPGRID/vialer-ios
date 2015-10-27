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

typedef NS_ENUM(NSInteger, VoIPGRIDHttpErrors) {
    kVoIPGRIDHTTPBadRequest = 400,
    kVoIPGRIDHTTPUnauthorized = 401,
    kVoIPGRIDHTTPForbidden = 403,
    kVoIPGRIDHTTPNotFound = 404,
};

typedef NS_ENUM (NSUInteger, VGTwoStepCallErrors) {
    VGTwoStepCallErrorSetupFailed,
    VGTwoStepCallErrorStatusRequestFailed,
};

@interface VoIPGRIDRequestOperationManager : AFHTTPRequestOperationManager

+ (VoIPGRIDRequestOperationManager *)sharedRequestOperationManager;

// Log in / Log out
- (void)loginWithUser:(NSString *)user password:(NSString *)password success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
- (void)logout;

- (void)retrievePhoneAccountForUrl:(NSString *)phoneAccountUrl success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;


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
 Initializes a Two Step Call to the supplied phone numbers. If succesful the call id and status are returned.
 
 @param aNumber The number which will be called first.
 @param bNumber The number called when a connection to aNumber is successful.
 @param completion A block giving access to the call ID or an error.
 */
- (void)setupTwoStepCallWithANumber:(NSString *)aNumber bNumber:(NSString*)bNumber withCompletion:(void (^)(NSString * callID, NSError *error))completion;

/**
 Once an Call ID has been obtained through the -setupTwoStepCallWith... function the status of the call can be
 retrieved using this function
 
 @param callID The Call ID of the call for which it's status should be checked.
 @param completion A block giving access to the call status or an error.
 */
- (void)twoStepCallStatusForCallId:(NSString *)callId withCompletion:(void (^)(NSString* callStatus, NSError *error))completion;

/** 
 Pushes the user's mobile number to the server
 
 @param mobileNumber the mobile number to push
 @param forcePush Pushes the number to the server irrespective of change or not
 @param succes the block being called on success
 @param failure the block being called on failure including an localized error string which can be presented to the user
 */
- (void)pushMobileNumber:(NSString *)mobileNumber forcePush:(BOOL)forcePush success:(void (^)())success failure:(void (^)(NSString *localizedErrorString))failure;

- (void)pushSelectedUserDestination:(NSString *)selectedUserResourceUri destinationDict:(NSDictionary *)destinationDict success: (void (^)())success failure:(void (^)(NSString * localizedErrorString))failure;
@end