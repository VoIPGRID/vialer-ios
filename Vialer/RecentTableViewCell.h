//
//  RecentTableViewCell.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RecentCall.h"

@interface RecentTableViewCell : UITableViewCell

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *subtitle;
@property (strong, nonatomic) NSString *date;
@property (nonatomic) CallDirection callDirection;
@property (nonatomic) BOOL answered;
@end
