//
//  VoIPGRIDRequestOperationManager.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "VoIPGRIDRequestOperationManager.h"

#import "Configuration.h"
#import "NSDate+RelativeDate.h"
#import "SystemUser.h"

#import "SSKeychain.h"

#define GetPermissionSystemUserProfileUrl @"permission/systemuser/profile/"
#define GetUserDestinationUrl @"userdestination/"
#define GetPhoneAccountUrl @"phoneaccount/phoneaccount/"
#define twoStepCallURL @"mobileapp/"
#define GetCdrRecordUrl @"cdr/record/"
#define PostPermissionPasswordResetUrl @"permission/password_reset/"
#define GetAutoLoginTokenUrl @"autologin/token/"
#define PutMobileNumber @"/api/permission/mobile_number/"
#define kMobileNumberKey @"mobile_nr"

NSString *const VGErrorDomain = @"com.voipgrid.error";
NSString *const TwoStepCallCallIDKey = @"callid";
NSString *const TwoStepCallStatusKey = @"status";
static NSString * const VoIPGRIDRequestOperationManagerTwoStepCallErrorPhoneNumber = @"Extensions or phonenumbers not valid";

@interface VoIPGRIDRequestOperationManager ()
@property (nonatomic, strong)NSDateFormatter *callDateGTFormatter;
@end

@implementation VoIPGRIDRequestOperationManager

+ (VoIPGRIDRequestOperationManager *)sharedRequestOperationManager {
    static dispatch_once_t pred;
    static VoIPGRIDRequestOperationManager *_sharedRequestOperationManager = nil;

    dispatch_once(&pred, ^{
        _sharedRequestOperationManager = [[self alloc] initWithBaseURL:[NSURL URLWithString:[Configuration UrlForKey:@"API"]]];
    });
    return _sharedRequestOperationManager;
}

- (instancetype)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (self) {
        [self setRequestSerializer:[AFJSONRequestSerializer serializer]];
        [self.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];

        // Set basic authentication if user is logged in
        NSString *user = [SystemUser currentUser].user;
        if (user) {
            NSString *password = [SSKeychain passwordForService:[[self class] serviceName] account:user];
            [self.requestSerializer setAuthorizationHeaderFieldWithUsername:user password:password];
        }
    }
    return self;
}

- (void)retrievePhoneAccountForUrl:(NSString *)phoneAccountUrl success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [self GET:[phoneAccountUrl stringByReplacingOccurrencesOfString:@"/api/" withString:@""] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(operation, error);
    }];
}

typedef NS_ENUM(NSInteger, VoIPGRIDLoginErrors) {
    VoIPGRIDLoginErrorUserTypeNotAllowed, //Partner or superuser login attempt. Denied.
};
- (void)loginWithUser:(NSString *)user password:(NSString *)password success:(void (^)(NSDictionary *responseData))success failure:(void (^)(NSError *error))failure {
    [self.requestSerializer setAuthorizationHeaderFieldWithUsername:user password:password];

    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"GET" URLString:[[NSURL URLWithString:GetPermissionSystemUserProfileUrl relativeToURL:self.baseURL] absoluteString] parameters:nil error:nil];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *responseData = (NSDictionary *)responseObject;
        id partner = [responseData objectForKey:@"partner"];
        NSString *client = [responseData objectForKey:@"client"];
        // Client should be valid, and partner should not be present.
        BOOL clientValid = (client != nil && ![client isKindOfClass:[NSNull class]]);
        BOOL partnerValid = (partner != nil && ![partner isKindOfClass:[NSNull class]]);
        if (!clientValid || partnerValid) {
            // This is a partner or superuser account, don't log in!
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : NSLocalizedString(@"user type not allowed", nil)};
            failure([NSError errorWithDomain:VGErrorDomain code:VoIPGRIDLoginErrorUserTypeNotAllowed userInfo:userInfo]);

            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login failed", nil)
                                                            message:NSLocalizedString(@"This user is not allowed to use the app", nil)
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
            [alert show];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:LOGIN_SUCCEEDED_NOTIFICATION object:nil];

            // Notify we are completed here
            if (success) {
                success (responseObject);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
        if ([operation.response statusCode] == VoIPGRIDHttpErrorUnauthorized) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login failed", nil) message:NSLocalizedString(@"Your email and/or password is incorrect.", nil) delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
            [alert show];
        } else {
            [self connectionFailed];
        }
    }];

    [self setHandleAuthorizationRedirectForRequest:request andOperation:operation];
    [self.operationQueue addOperation:operation];
}

- (void)logout {
    [self.operationQueue cancelAllOperations];
    [self.requestSerializer clearAuthorizationHeader];

    // Clear cookies for web view
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in cookieStorage.cookies) {
        [cookieStorage deleteCookie:cookie];
    }

    NSError *error;
    NSString *user = [SystemUser currentUser].user;

    [SSKeychain deletePasswordForService:[[self class] serviceName] account:user error:&error];
    if (error) {
        NSLog(@"Error logging out: %@", [error localizedDescription]);
    }

    [[SystemUser currentUser] removeCurrentUser];

    [[NSNotificationCenter defaultCenter] postNotificationName:LOGIN_FAILED_NOTIFICATION object:nil];
}

- (void)userDestinationWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [self GET:GetUserDestinationUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(operation, error);
        if ([operation.response statusCode] == VoIPGRIDHttpErrorUnauthorized) {
            [self loginFailed];
        }
    }];
}

- (void)userProfileWithCompletion:(void (^)(id responseObject, NSError *error))completion {
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"GET" URLString:[[NSURL URLWithString:GetPermissionSystemUserProfileUrl relativeToURL:self.baseURL] absoluteString] parameters:nil error:nil];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        completion(responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey : NSLocalizedString(@"Error updating user profile", nil)};
        completion(nil, [NSError errorWithDomain:VGErrorDomain code:operation.response.statusCode userInfo:userInfo]);
    }];

    [self setHandleAuthorizationRedirectForRequest:request andOperation:operation];
    [self.operationQueue addOperation:operation];
}

- (void)phoneAccountWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [self GET:GetPhoneAccountUrl parameters:[NSDictionary dictionary] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(operation, error);
        if ([operation.response statusCode] == VoIPGRIDHttpErrorUnauthorized) {
            [self loginFailed];
        }
    }];
}

- (void)setupTwoStepCallWithANumber:( NSString *)aNumber bNumber:(NSString *)bNumber withCompletion:(void (^)(NSString *callID, NSError *error))completion {
    NSAssert(aNumber, @"A Number must not be empty when setting up a two way call.");
    NSAssert(bNumber, @"A Number must not be empty when setting up a two way call.");
    NSAssert(completion, @"A completion block must be supplied.");

    [self POST:twoStepCallURL
    parameters:@{@"a_number" : aNumber,
                 @"b_number" : bNumber,
                 @"a_cli" : @"default_number",
                 @"b_cli" : @"default_number",
                 }
       success:^(AFHTTPRequestOperation *operation, id  responseObject) {
           NSString *callID;
           if ((callID = [self getObjectForKey:TwoStepCallCallIDKey fromResponseObject:responseObject])) {
               completion(callID, nil);
           } else {
               NSDictionary *userInfo = @{NSLocalizedString(@"Two step call failed", nil) : NSLocalizedDescriptionKey};
               completion(nil, [NSError errorWithDomain:VGErrorDomain code:VGTwoStepCallErrorSetupFailed userInfo:userInfo]);
           }
       } failure:^(AFHTTPRequestOperation *operation, NSError * error) {
           NSString *userInfoString = NSLocalizedString(@"Two step call failed", nil);
           NSInteger errorCode = -1;

           if (operation.response.statusCode == VoIPGRIDHttpErrorBadRequest) {
               //Request malfomed, the request returned the failure reason, return this wrapped in an error.

               //Possible reasons:
               //- Extensions or phonenumbers not valid
               //- This number is not permitted.
               if (operation.responseString.length > 0) {
                   if ([operation.responseString isEqualToString:VoIPGRIDRequestOperationManagerTwoStepCallErrorPhoneNumber]) {
                       errorCode = VGTwoStepCallInvalidNumber;
                       userInfoString = NSLocalizedString(@"Invalid number used to setup call", nil);
                   } else {
                       userInfoString = operation.responseString;
                   }
               }
           } else if (operation.response.statusCode == VoIPGRIDHttpErrorUnauthorized) {
               [self loginFailed];
               errorCode = VGTwoStepCallErrorStatusUnAuthorized;
               userInfoString = NSLocalizedString(@"Couldn't login, authorization failed", nil);
           }
           NSDictionary *userInfo = @{NSLocalizedDescriptionKey : userInfoString};
           completion(nil, [NSError errorWithDomain:VGErrorDomain code:errorCode userInfo:userInfo]);
       }];
}

- (void)twoStepCallStatusForCallId:(NSString *)callId withCompletion:(void (^)(NSString *callStatus, NSError *error))completion {
    NSAssert(callId, @"Call ID cannot by empty when checking for it's status");
    NSAssert(completion, @"A completion block must be supplied.");

    NSString *updateStatusURL = [NSString stringWithFormat:@"%@%@/", twoStepCallURL, callId];
    [self GET:updateStatusURL parameters:nil
      success:^(AFHTTPRequestOperation * operation, id responseObject) {
          //Get the callStatus from the response
          NSString *callStatus;
          if ((callStatus = [self getObjectForKey:TwoStepCallStatusKey fromResponseObject:responseObject])) {
              completion(callStatus, nil);
          } else {
              NSDictionary *userInfo = @{NSLocalizedDescriptionKey : NSLocalizedString(@"Two step call failed", nil)};
              completion(nil, [NSError errorWithDomain:VGErrorDomain code:VGTwoStepCallErrorStatusRequestFailed userInfo:userInfo]);
          }

      } failure:^(AFHTTPRequestOperation * operation, NSError * error) {
          NSDictionary *userInfo = @{NSLocalizedDescriptionKey : NSLocalizedString(@"Two step call failed", nil)};
          completion(nil, [NSError errorWithDomain:VGErrorDomain code:VGTwoStepCallErrorStatusRequestFailed userInfo:userInfo]);
      }];
}

- (void)cancelTwoStepCallForCallId:(NSString * _Nonnull)callId withCompletion:(void (^ _Nonnull)(BOOL success, NSError *error))completion {
    NSString *updateStatusURL = [NSString stringWithFormat:@"%@%@/", twoStepCallURL, callId];
    [self DELETE:updateStatusURL parameters:nil
      success:^(AFHTTPRequestOperation *operation, id responseObject) {
          // Check if the cancelation was successfull by checking HTTP statusCode.
          if (operation.response.statusCode == 204) {
              completion(YES, nil);
          } else {
              NSDictionary *userInfo = @{NSLocalizedDescriptionKey : NSLocalizedString(@"Two step call cancel failed", nil)};
              completion(NO, [NSError errorWithDomain:VGErrorDomain code:VGTwoStepCallErrorCancelFailed userInfo:userInfo]);
          }

      } failure:^(AFHTTPRequestOperation * operation, NSError * error) {
          NSDictionary *userInfo = @{NSLocalizedDescriptionKey : NSLocalizedString(@"Two step call cancel failed", nil)};
          completion(NO, [NSError errorWithDomain:VGErrorDomain code:VGTwoStepCallErrorCancelFailed userInfo:userInfo]);
      }];
}
/**
 * Return the Object for the given key from a response object
 * @param key The key to search for in the respons object.
 * @param responseObject The response object to query for the given key.
 * @return The object found for the given key or nil.
 */
- (NSString *)getObjectForKey:(NSString *)key fromResponseObject:(id)responseObject {
    NSString *callStatus = nil;
    if ([[responseObject objectForKey:key] isKindOfClass:[NSString class]]) {
        callStatus = [responseObject objectForKey:key];
    }
    return callStatus;
}

/**
 * Since a DateFormatter is pretty expensive to load, lazy load it and keep it in memory
 */
- (NSDateFormatter *)callDateGTFormatter {
    if (! _callDateGTFormatter) {
        _callDateGTFormatter = [[NSDateFormatter alloc] init];
        [_callDateGTFormatter setDateFormat:@"yyyy-MM-dd"];
    }
    return _callDateGTFormatter;
}

- (void)cdrRecordWithLimit:(NSInteger)limit offset:(NSInteger)offset sourceNumber:(NSString *)sourceNumber callDateGte:(NSDate *)date success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {

    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:@(limit) forKey:@"limit"];
    [params setObject:@(offset) forKey:@"offset"];
    [params setObject:[self.callDateGTFormatter stringFromDate:date] forKey:@"call_date__gt"];

    if ([sourceNumber length] > 0)
        [params setObject:sourceNumber forKey:@"src_number"];

    [self GET:GetCdrRecordUrl parameters:params
      success:^(AFHTTPRequestOperation *operation, id responseObject) {
          success(operation, responseObject);
      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
          failure(operation, error);
      }];
}

- (void)passwordResetWithEmail:(NSString *)email success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:self.baseURL];
    [manager setRequestSerializer:[AFJSONRequestSerializer serializer]];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];

    [manager POST:PostPermissionPasswordResetUrl parameters:[NSDictionary dictionaryWithObjectsAndKeys:email, @"email", nil]
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              success(operation, responseObject);
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              failure(operation, error);
          }];
}

- (void)autoLoginTokenWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [self GET:GetAutoLoginTokenUrl parameters:[NSDictionary dictionary]
      success:^(AFHTTPRequestOperation *operation, id responseObject) {
          success(operation, responseObject);
      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
          failure(operation, error);
      }];
}

- (void)loginFailed {
    // No credentials, forward the logout call to SystemUser to clear all stored properties
    [[SystemUser currentUser] logout];

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login failed", nil) message:NSLocalizedString(@"Your email and/or password is incorrect.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
    [alert show];
}

- (void)connectionFailed {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection failed", nil) message:NSLocalizedString(@"Unknown error, please check your internet connection.", nil) delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
    [alert show];
}

+ (NSString *)serviceName {
    return [[NSBundle mainBundle] bundleIdentifier];
}

- (void)setHandleAuthorizationRedirectForRequest:(NSURLRequest *)request andOperation:(AFHTTPRequestOperation *)operation {
    __block NSString *authorization = [request.allHTTPHeaderFields objectForKey:@"Authorization"];
    [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse) {
        if ([request.allHTTPHeaderFields objectForKey:@"Authorization"] != nil) {
            return request;
        }

        NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:request.URL cachePolicy:request.cachePolicy timeoutInterval:request.timeoutInterval];
        [urlRequest setValue:authorization forHTTPHeaderField:@"Authorization"];
        return urlRequest;
    }];
}

- (void)pushSelectedUserDestination:(NSString *)selectedUserResourceUri destinationDict:(NSDictionary *)destinationDict success:(void (^)())success failure:(void (^)(NSString *))failure {

    [self PUT:selectedUserResourceUri parameters:destinationDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSString *localizedErrorString = [error localizedDescription];
        if (failure) {
            failure(localizedErrorString);
        }
    }];
}

/**
 Under some circumstances we would like to force setting of the mobile number. For instance with the migration of v1.x to version 2.0
 in which case the user has entered his mobile number but it was never actually pushed to the server.
 */
- (void)pushMobileNumber:(NSString *)mobileNumber forcePush:(BOOL)forcePush success:(void (^)())success  failure:(void (^)(NSString *localizedErrorString))failure {
    //Has the user entered a number
    if (![mobileNumber length] > 0) {
        if (failure) failure(NSLocalizedString(@"Unable to save \"My number\"", nil));
        return;
    }
    //Strip whitespaces
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@" " withString:@""];

    //Change country code from 00xx to +xx
    if ([mobileNumber hasPrefix:@"00"])
        mobileNumber = [NSString stringWithFormat:@"+%@", [mobileNumber substringFromIndex:2]];

    //Has the user entered the number in the international format with check above 00xx is also accepted
    if (![mobileNumber hasPrefix:@"+"]) {
        if (failure) failure(NSLocalizedString(@"MOBILE_NUMBER_SHOULD_START_WITH_COUNTRY_CODE_ERROR", nil));
        return;
    }

    //With all the checks and replacements done, is the number actually different from the stored one?
    if ([mobileNumber isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:@"MobileNumber"]] && !forcePush) {
        if (success) success();
        return;
    }

    //Sent the new number to the server
    NSDictionary *parameters = @{kMobileNumberKey : mobileNumber};
    [self PUT:PutMobileNumber parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [[NSUserDefaults standardUserDefaults] setObject:mobileNumber forKey:@"MobileNumber"];
        if (success) success();
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //Provide user with the message from the error
        NSString *localizedErrorString = [error localizedDescription];

        //if the status code was 400, the platform will give us a localized error description in the mobile_nr parameter
        if (operation.response.statusCode == 400)
            localizedErrorString = [[operation.responseObject objectForKey:kMobileNumberKey] firstObject];

        if (failure) failure(localizedErrorString);
    }];
}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [[NSNotificationCenter defaultCenter] postNotificationName:LOGIN_FAILED_NOTIFICATION object:nil];
}

@end