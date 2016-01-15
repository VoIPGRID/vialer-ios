//
//  VoIPGRIDRequestOperationManager.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "AFHTTPRequestOperationManager.h"

#define LOGIN_FAILED_NOTIFICATION @"login.failed"
#define LOGIN_SUCCEEDED_NOTIFICATION @"login.succeeded"

typedef NS_ENUM(NSInteger, VoIPGRIDHttpErrors) {
    VoIPGRIDHttpErrorBadRequest = 400,
    VoIPGRIDHttpErrorUnauthorized = 401,
    VoIPGRIDHttpErrorForbidden = 403,
    VoIPGRIDHttpErrorNotFound = 404,
};

typedef NS_ENUM (NSUInteger, VGTwoStepCallErrors) {
    VGTwoStepCallErrorSetupFailed,
    VGTwoStepCallErrorStatusRequestFailed,
    VGTwoStepCallErrorStatusUnAuthorized,
    VGTwoStepCallInvalidNumber,
    VGTwoStepCallErrorCancelFailed
};

@interface VoIPGRIDRequestOperationManager : AFHTTPRequestOperationManager

+ (VoIPGRIDRequestOperationManager *)sharedRequestOperationManager;

// Log in / Log out
- (void)loginWithUser:(NSString *)user password:(NSString *)password success:(void (^)(NSDictionary *responseData))success failure:(void (^)(NSError *error))failure;
- (void)logout;

- (void)retrievePhoneAccountForUrl:(NSString *)phoneAccountUrl success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;


// User requests
- (void)userDestinationWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Make a request to the systemuser endpoint.

 @param completion A block giving access to the properties of a system user or an error.
 */
- (void)userProfileWithCompletion:(void (^)(id responseObject, NSError *error))completion;
- (void)phoneAccountWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
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
 Once an Call ID has been obtained through the -setupTwoStepCallWith... function the the call can be canceled
 using this function

 @param callID The Call ID of the call that needs to be canceled.
 @param completion A block giving access to the success of the cancelation or an error.
 */
- (void)cancelTwoStepCallForCallId:(NSString *)callId withCompletion:(void (^)(BOOL success, NSError *error))completion;

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