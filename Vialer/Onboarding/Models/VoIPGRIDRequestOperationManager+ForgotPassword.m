//
//  VoIPGRIDRequestOperationManager+ForgotPassword.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "VoIPGRIDRequestOperationManager+ForgotPassword.h"

static NSString * const VoIPGRIDRequestOperationManagerURLPasswordReset = @"permission/password_reset/";

@implementation VoIPGRIDRequestOperationManager (ForgotPassword)

- (void)passwordResetWithEmail:(NSString *)email withCompletion:(void (^)(NSURLResponse *operation, NSDictionary *responseData, NSError *error))completion {
    [self POST:VoIPGRIDRequestOperationManagerURLPasswordReset parameters:@{@"email": email} withCompletion:completion];
}

@end
