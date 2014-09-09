//
//  VoIPGRIDRequestOperationManager.m
//  Vialer
//
//  Created by Reinier Wieringa on 31/10/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "VoIPGRIDRequestOperationManager.h"
#import "NSDate+RelativeDate.h"

#import "SSKeychain.h"

@interface VoIPGRIDRequestOperationManager ()
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

- (void)loginWithUser:(NSString *)user password:(NSString *)password success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [self.requestSerializer setAuthorizationHeaderFieldWithUsername:user password:password];

    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"GET" URLString:[[NSURL URLWithString:@"permission/systemuser/profile/" relativeToURL:self.baseURL] absoluteString] parameters:nil];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *client = [responseObject objectForKey:@"client"];
        if (!client) {
            // This is a partner account, don't log in!
            failure(operation, nil);
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection failed", nil) message:NSLocalizedString(@"Your email and/or password is incorrect.", nil) delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
            [alert show];
        } else {
            NSString *outgoingCli = [responseObject objectForKey:@"outgoing_cli"];
            if (outgoingCli) {
                [[NSUserDefaults standardUserDefaults] setObject:outgoingCli forKey:@"OutgoingNumber"];
            }

            // Store credentials
            [[NSUserDefaults standardUserDefaults] setObject:user forKey:@"User"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [SSKeychain setPassword:password forService:[[self class] serviceName] account:user];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:LOGIN_SUCCEEDED_NOTIFICATION object:nil];
            
            success(operation, success);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(operation, error);
        if ([operation.response statusCode] == kVoIPGRIDHTTPBadCredentials) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection failed", nil) message:NSLocalizedString(@"Your email and/or password is incorrect.", nil) delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
            [alert show];
        } else {
            [self connectionFailed];
        }
    }];

    // NOTE: AFNetworking doesn't redirect the authorization header, so handle it here
    __block NSString *authorization = [request.allHTTPHeaderFields objectForKey:@"Authorization"];
    [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse) {
        if ([request.allHTTPHeaderFields objectForKey:@"Authorization"] != nil) {
            return request;
        }

        NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:request.URL cachePolicy:request.cachePolicy timeoutInterval:request.timeoutInterval];
        [urlRequest setValue:authorization forHTTPHeaderField:@"Authorization"];
        return  urlRequest;
    }];

    [self.operationQueue addOperation:operation];
}

- (void)logout {
    [self.operationQueue cancelAllOperations];

    NSString *user = [[NSUserDefaults standardUserDefaults] objectForKey:@"User"];
    
    NSError *error;
    [SSKeychain deletePasswordForService:[[self class] serviceName] account:user error:&error];

    if (error) {
        NSLog(@"Error logging out: %@", [error localizedDescription]);
    }
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"User"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"OutgoingNumber"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [[NSNotificationCenter defaultCenter] postNotificationName:LOGIN_FAILED_NOTIFICATION object:nil];
}

+ (BOOL)isLoggedIn {
    NSString *user = [[NSUserDefaults standardUserDefaults] objectForKey:@"User"];
    return (user != nil) && ([SSKeychain passwordForService:[[self class] serviceName] account:user] != nil);
}

- (void)userDestinationWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [self GET:@"userdestination/" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(operation, error);
        if ([operation.response statusCode] == kVoIPGRIDHTTPBadCredentials) {
            [self loginFailed];
        }
    }];
}

- (void)userProfileWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"GET" URLString:[[NSURL URLWithString:@"permission/systemuser/profile/" relativeToURL:self.baseURL] absoluteString] parameters:nil];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(operation, error);
        if ([operation.response statusCode] == kVoIPGRIDHTTPBadCredentials) {
            [self loginFailed];
        }
    }];
    
    // NOTE: AFNetworking doesn't redirect the authorization header, so handle it here
    __block NSString *authorization = [request.allHTTPHeaderFields objectForKey:@"Authorization"];
    [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse) {
        if ([request.allHTTPHeaderFields objectForKey:@"Authorization"] != nil) {
            return request;
        }
        
        NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:request.URL cachePolicy:request.cachePolicy timeoutInterval:request.timeoutInterval];
        [urlRequest setValue:authorization forHTTPHeaderField:@"Authorization"];
        return  urlRequest;
    }];

    [self.operationQueue addOperation:operation];
}

- (void)phoneAccountWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [self GET:@"phoneaccount/phoneaccount/" parameters:[NSDictionary dictionary] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(operation, error);
        if ([operation.response statusCode] == kVoIPGRIDHTTPBadCredentials) {
            [self loginFailed];
        }
    }];
}

- (void)clickToDialToNumber:(NSString *)toNumber fromNumber:(NSString *)fromNumber success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [self POST:@"clicktodial/" parameters:[NSDictionary dictionaryWithObjectsAndKeys:
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
    NSString *url = [[@"clicktodial/" stringByAppendingString:callId] stringByAppendingString:@"/"];

    [self GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(operation, error);
        if ([operation.response statusCode] == kVoIPGRIDHTTPBadCredentials) {
            [self loginFailed];
        }
    }];
}

- (void)cdrRecordWithLimit:(NSInteger)limit offset:(NSInteger)offset sourceNumber:(NSString *)sourceNumber callDateGte:(NSDate *)date success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [self GET:@"cdr/record/" parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                         @(limit), @"limit",
                                         @(offset), @"offset",
                                         sourceNumber, @"src_number",
                                         nil
                                         ]
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
    
    [manager POST:@"permission/password_reset/" parameters:[NSDictionary dictionaryWithObjectsAndKeys:email, @"email", nil]
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              success(operation, responseObject);
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              failure(operation, error);
          }];
}

- (void)autoLoginTokenWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [self GET:@"autologin/token/" parameters:[NSDictionary dictionary]
      success:^(AFHTTPRequestOperation *operation, id responseObject) {
          success(operation, responseObject);
      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
          failure(operation, error);
      }];
}

- (void)loginFailed {
    // No credentials
    [self logout];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection failed", nil) message:NSLocalizedString(@"Your email and/or password is incorrect.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
    [alert show];
}

- (void)connectionFailed {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection failed", nil) message:NSLocalizedString(@"Unknown error, please check your internet connection.", nil) delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
    [alert show];
}


+ (NSString *)serviceName {
    return [[NSBundle mainBundle] bundleIdentifier];
}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [[NSNotificationCenter defaultCenter] postNotificationName:LOGIN_FAILED_NOTIFICATION object:nil];
}

@end