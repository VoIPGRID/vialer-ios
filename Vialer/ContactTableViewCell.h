//
//  ContactTableViewCell.h
//  Vialer
//
//  Created by Johannes Nevels on 23-04-15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContactTableViewCell : UITableViewCell
- (void) populateBasedOnContactDict:(NSDictionary *)contactDict;
@end
