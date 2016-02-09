//
//  RecentCall.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "RecentCall.h"

@implementation RecentCall


- (NSString *)displayName {
    if (self.callerName) {
        return self.callerName;
    } else if (self.callerID) {
        NSError *error;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\"(.*?)\"" options:NSRegularExpressionCaseInsensitive error:&error];
        NSTextCheckingResult *match = [regex firstMatchInString:self.callerID options:0 range:NSMakeRange(0, self.callerID.length)];
        if (match) {
            return [self.callerID substringWithRange:[match rangeAtIndex:1]];
        }
    }
    return [self.inbound boolValue] ? self.sourceNumber : self.destinationNumber;
}

+ (RecentCall *)latestCallInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RecentCall" inManagedObjectContext:managedObjectContext];
    fetchRequest.entity = entity;

    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"callDate" ascending:NO];
    fetchRequest.sortDescriptors = @[sort];

    fetchRequest.fetchLimit =1;

    RecentCall *call;
    NSError *error;
    NSArray *lastCalls = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (!error && lastCalls.count == 1) {
        call = lastCalls[0];
    }
    return call;
}

@end
