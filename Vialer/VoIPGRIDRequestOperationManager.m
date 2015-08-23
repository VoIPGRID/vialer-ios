//
//  VoIPGRIDRequestOperationManager.m
//  Vialer
//
//  Created by Reinier Wieringa on 31/10/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "VoIPGRIDRequestOperationManager.h"
#import "NSDate+RelativeDate.h"
#import "PZPushMiddleware.h"
#import "ConnectionHandler.h"

#import "SSKeychain.h"

#define GetPermissionSystemUserProfileUrl @"permission/systemuser/profile/"
#define GetUserDestinationUrl @"userdestination/"
#define GetPhoneAccountUrl @"phoneaccount/phoneaccount/"
#define GetClickToDialUrl @"clicktodial/"
#define GetCdrRecordUrl @"cdr/record/"
#define PostPermissionPasswordResetUrl @"permission/password_reset/"
#define GetAutoLoginTokenUrl @"autologin/token/"
#define PutMobileNumber @"/api/permission/mobile_number/"


@interface VoIPGRIDRequestOperationManager ()
@property (nonatomic, strong)NSDateFormatter *callDateGTFormatter;
@end

@implementation VoIPGRIDRequestOperationManager

+ (VoIPGRIDRequestOperationManager *)sharedRequestOperationManager {
    static dispatch_once_t pred;
    static VoIPGRIDRequestOperationManager *_sharedRequestOperationManager = nil;

    dispatch_once(&pred, ^{
        NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"]];
        NSAssert(config != nil, @"Config.plist not found!");

        NSString *baseUrl = [[config objectForKey:@"URLS"] objectForKey:@"API"];
        NSAssert(baseUrl != nil, @"URLS - API not found in Config.plist!");

        _sharedRequestOperationManager = [[self alloc] initWithBaseURL:[NSURL URLWithString:baseUrl]];
    });
    return _sharedRequestOperationManager;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (self) {
        [self setRequestSerializer:[AFJSONRequestSerializer serializer]];
        [self.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];

        // Set basic authentication if user is logged in
        NSString *user = [[NSUserDefaults standardUserDefaults] objectForKey:@"User"];
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

- (void)loginWithUser:(NSString *)user password:(NSString *)password success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [self.requestSerializer setAuthorizationHeaderFieldWithUsername:user password:password];
    
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"GET" URLString:[[NSURL URLWithString:GetPermissionSystemUserProfileUrl relativeToURL:self.baseURL] absoluteString] parameters:nil error:nil];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *client = [responseObject objectForKey:@"client"];
        if (!client) {
            // This is a partner account, don't log in!
            failure(operation, nil);

            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login failed", nil) message:NSLocalizedString(@"Your email and/or password is incorrect.", nil) delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
            [alert show];
        } else {
            
            
            NSString *outgoingCli = [responseObject objectForKey:@"outgoing_cli"];
            if ([outgoingCli isKindOfClass:[NSString class]]) {
                [[NSUserDefaults standardUserDefaults] setObject:outgoingCli forKey:@"OutgoingNumber"];
            } else {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"OutgoingNumber"];
            }
            
            NSString *mobile_nr = [responseObject objectForKey:@"mobile_nr"];
            if ([mobile_nr isKindOfClass:[NSString class]]) {
                [[NSUserDefaults standardUserDefaults] setObject:mobile_nr forKey:@"MobileNumber"];
            } else {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"MobileNumber"];
            }

            // Store credentials
            [[NSUserDefaults standardUserDefaults] setObject:user forKey:@"User"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [SSKeychain setPassword:password forService:[[self class] serviceName] account:user];

            [[NSNotificationCenter defaultCenter] postNotificationName:LOGIN_SUCCEEDED_NOTIFICATION object:nil];

            // Fetch SIP account credentials
            [self updateSIPAccountWithSuccess:^{
                if (success) success(operation, success);
            } failure:^(NSError *error) {
                //The old code stated that success should also be called on a failure
                if (success) success(operation, success);
            }];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(operation, error);
        if ([operation.response statusCode] == kVoIPGRIDHTTPBadCredentials) {
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
    //unregister from middleware
    [[PZPushMiddleware sharedInstance] unregisterSipAccount:self.sipAccount];
    
    // Remove sip account if present
    NSString *sipAccount = [[NSUserDefaults standardUserDefaults] objectForKey:@"SIPAccount"];
    if (sipAccount) {
        [SSKeychain deletePasswordForService:[[self class] serviceName] account:sipAccount error:NULL];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SIPAccount"];
    }

    NSError *error;
    NSString *user = [[NSUserDefaults standardUserDefaults] objectForKey:@"User"];

    [SSKeychain deletePasswordForService:[[self class] serviceName] account:user error:&error];
    if (error) {
        NSLog(@"Error logging out: %@", [error localizedDescription]);
    }

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"User"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"OutgoingNumber"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"MobileNumber"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [[NSNotificationCenter defaultCenter] postNotificationName:LOGIN_FAILED_NOTIFICATION object:nil];
}

+ (BOOL)isLoggedIn {
    NSString *user = [[NSUserDefaults standardUserDefaults] objectForKey:@"User"];
    return (user != nil);
}

- (void)userDestinationWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [self GET:GetUserDestinationUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(operation, error);
        if ([operation.response statusCode] == kVoIPGRIDHTTPBadCredentials) {
            [self loginFailed];
        }
    }];
}

- (void)userProfileWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"GET" URLString:[[NSURL URLWithString:GetPermissionSystemUserProfileUrl relativeToURL:self.baseURL] absoluteString] parameters:nil error:nil];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *outgoingCli = [responseObject objectForKey:@"outgoing_cli"];
        if ([outgoingCli isKindOfClass:[NSString class]]) {
            [[NSUserDefaults standardUserDefaults] setObject:outgoingCli forKey:@"OutgoingNumber"];
        } else {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"OutgoingNumber"];
        }
        success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(operation, error);
        if ([operation.response statusCode] == kVoIPGRIDHTTPBadCredentials) {
            [self loginFailed];
        }
    }];

    [self setHandleAuthorizationRedirectForRequest:request andOperation:operation];
    [self.operationQueue addOperation:operation];
}

- (void)phoneAccountWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [self GET:GetPhoneAccountUrl parameters:[NSDictionary dictionary] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(operation, error);
        if ([operation.response statusCode] == kVoIPGRIDHTTPBadCredentials) {
            [self loginFailed];
        }
    }];
}

- (void)clickToDialToNumber:(NSString *)toNumber fromNumber:(NSString *)fromNumber success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [self POST:GetClickToDialUrl parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                             toNumber, @"b_number",
                                             fromNumber, @"a_number",
                                             @"default_number", @"b_cli",
                                             @"default_number", @"a_cli",
                                             nil
                                             ] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(operation, error);
        if ([operation.response statusCode] == kVoIPGRIDHTTPBadCredentials) {
            [self loginFailed];
        }
    }];
}

- (void)clickToDialStatusForCallId:(NSString *)callId success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    NSString *url = [[GetClickToDialUrl stringByAppendingString:callId] stringByAppendingString:@"/"];

    [self GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(operation, error);
        if ([operation.response statusCode] == kVoIPGRIDHTTPBadCredentials) {
            [self loginFailed];
        }
    }];
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
    // No credentials
    [self logout];

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

// TODO: don't use success/failblocks, use one completion block
// http://collindonnell.com/2013/04/07/stop-using-success-failure-blocks/
- (void)updateSIPAccountWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    if ([[self class] isLoggedIn]) {
        NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"GET"
                                                                       URLString:[[NSURL URLWithString:GetPermissionSystemUserProfileUrl relativeToURL:self.baseURL] absoluteString]
                                                                      parameters:nil
                                                                           error:nil];
        
        AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSString *appAccountUrl = [responseObject objectForKey:@"app_account"];
            [self fetchSipAccountFromAppAccountURL:appAccountUrl withSuccess:^(NSString *sipUsername, NSString *sipPassword) {
                [self setSipAccount:sipUsername andSipPassword:sipPassword];
                if (success) success ();
            } failure:^(NSError *error) {
                if (failure) failure(error);
            }];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (failure) failure(error);
        }];
        
        [self setHandleAuthorizationRedirectForRequest:request andOperation:operation];
        [self.operationQueue addOperation:operation];
    }
}

/**
 * Given an URL to an App specific SIP account (phoneaccount) this function fetches and sets the SIP account details for use in the app if any, otherwise the SIP data is set to nil.
 * @param appAccountURL the URL from where to fetch the SIP account details e.g. /api/phoneaccount/basic/phoneaccount/XXXXX/
 */
- (void)fetchSipAccountFromAppAccountURL:(NSString *)appAccountURL withSuccess:(void (^)(NSString *sipUsername, NSString *sipPassword))success failure:(void (^)(NSError *error))failure {
    if ([appAccountURL isKindOfClass:[NSString class]])
        [self retrievePhoneAccountForUrl:appAccountURL success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSObject *account = [responseObject objectForKey:@"account_id"];
            NSObject *password = [responseObject objectForKey:@"password"];
            if ([account isKindOfClass:[NSNumber class]] && [password isKindOfClass:[NSString class]]) {
                if (success) success([(NSNumber *)account stringValue], (NSString *)password);
            } else {
                //No information about SIP account found, removed by user
                if (success) success(nil, nil);
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (failure) failure(error);
        }];
    else
        //No URL supplied for Mobile app account, this means the user does not have the account set.
        //We are also going to unset it by calling success with but sipUsername and sipPassword set to nil
        if (success) success(nil, nil);
}

- (void)setSipAccount:(NSString *)sipAccount andSipPassword:(NSString *)sipPassword {
    if (sipAccount) {
        [[NSUserDefaults standardUserDefaults] setObject:sipAccount forKey:@"SIPAccount"];
        [SSKeychain setPassword:sipPassword forService:[[self class] serviceName] account:sipAccount];
        //Inform the connection handler to connect to the new sip account
        [[ConnectionHandler sharedConnectionHandler] sipConnect];
        //Update the middleware that we are reachable under a new sip account
        [[PZPushMiddleware sharedInstance] updateDeviceRecord];
        NSLog(@"Setting SIP Account %@", sipAccount);
    } else {
        //First unregister the account with the middleware
        [[PZPushMiddleware sharedInstance] unregisterSipAccount:self.sipAccount];
        //Now delete it from the user defaults
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SIPAccount"];
        //And disconnect the Sip Connection Handler
        [[ConnectionHandler sharedConnectionHandler] sipDisconnect:nil];
        NSLog(@"No SIP Account");
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)user {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"User"];
}

- (NSString *)outgoingNumber {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"OutgoingNumber"];
}

- (NSString *)sipAccount {
    NSString *sipAccount = [[NSUserDefaults standardUserDefaults] objectForKey:@"SIPAccount"];
    return sipAccount;
}

- (NSString *)sipPassword {
    NSString *sipAccount = [self sipAccount];
    if (sipAccount) {
        return [SSKeychain passwordForService:[[self class] serviceName] account:sipAccount];
    }
    return nil;
}

/**
 * Under some circumstances we would like to force setting of the mobile number. For instance with the migration of v1.x to version 2.0
 * in which case the user has entered his mobile number but it was never actually pushed to the server.
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
    NSDictionary *parameters = @{@"mobile_nr" : mobileNumber};
    [self PUT:PutMobileNumber parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [[NSUserDefaults standardUserDefaults] setObject:mobileNumber forKey:@"MobileNumber"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        if (success) success();
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //Provide user with the message from the error
        NSString *localizedErrorString = [error localizedDescription];
        
        //if the status code was 400, the platform will give us a localized error description in the mobile_nr parameter
        if (operation.response.statusCode == 400)
            localizedErrorString = [[operation.responseObject objectForKey:@"mobile_nr"] firstObject];
        
        if (failure) failure(localizedErrorString);
    }];
}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [[NSNotificationCenter defaultCenter] postNotificationName:LOGIN_FAILED_NOTIFICATION object:nil];
}

@end