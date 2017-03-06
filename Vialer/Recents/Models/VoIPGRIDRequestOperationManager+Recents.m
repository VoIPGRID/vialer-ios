//
//  VoIPGRIDRequestOperationManager+Recents.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "VoIPGRIDRequestOperationManager+Recents.h"

static NSString * const VoIPGRIDRequestOperationManagerURLCdrRecord = @"cdr/record/";

@implementation VoIPGRIDRequestOperationManager (Recents)

- (void)cdrRecordsWithParameters:(NSDictionary *)parameters withCompletion:(void (^)(AFHTTPRequestOperation *operation, NSDictionary *responseData, NSError *error))completion {
    [self GET:VoIPGRIDRequestOperationManagerURLCdrRecord parameters:parameters withCompletion:completion];
}

@end
