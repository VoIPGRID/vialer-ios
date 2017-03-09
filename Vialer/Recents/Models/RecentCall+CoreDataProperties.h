//
//  RecentCall+CoreDataProperties.h
//  Copyright © 2016 VoIPGRID. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "RecentCall.h"

NS_ASSUME_NONNULL_BEGIN

@interface RecentCall (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *amount;
@property (nullable, nonatomic, retain) NSDate *callDate;
@property (nullable, nonatomic, retain) NSString *callerID;
@property (nullable, nonatomic, retain) NSString *callerName;
@property (nullable, nonatomic, retain) NSString *callerRecordID;
@property (nullable, nonatomic, retain) NSNumber *callID;
@property (nullable, nonatomic, retain) NSString *destinationAccount;
@property (nullable, nonatomic, retain) NSString *destinationNumber;
@property (nullable, nonatomic, retain) NSString *dialedNumber;
@property (nullable, nonatomic, retain) NSNumber *duration;
@property (nullable, nonatomic, retain) NSNumber *inbound;
@property (nullable, nonatomic, retain) NSString *phoneType;
@property (nullable, nonatomic, retain) NSString *sourceAccount;
@property (nullable, nonatomic, retain) NSString *sourceNumber;

@end

NS_ASSUME_NONNULL_END
