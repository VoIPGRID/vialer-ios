//
//  RecentTableViewCell.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RecentTableViewCell : UITableViewCell

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *subtitle;
@property (strong, nonatomic) NSDate *date;
@property (nonatomic) BOOL inbound;
@property (nonatomic) BOOL missed;
@end
