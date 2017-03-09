//
//  VoIPGRIDRequestOperationManager+ForgotPassword.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "VoIPGRIDRequestOperationManager+ForgotPassword.h"

static NSString * const VoIPGRIDRequestOperationManagerURLPasswordReset = @"permission/password_reset/";

@implementation VoIPGRIDRequestOperationManager (ForgotPassword)

- (void)passwordResetWithEmail:(NSString *)email withCompletion:(void (^)(AFHTTPRequestOperation *operation, NSDictionary *responseData, NSError *error))completion {
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:self.baseURL];
    [manager setRequestSerializer:[AFJSONRequestSerializer serializer]];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];

    [manager POST:VoIPGRIDRequestOperationManagerURLPasswordReset parameters:@{@"email": email} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        completion(operation, responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(operation, nil, error);
    }];
}

@end
