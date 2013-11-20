//
//  ChatMessageTableViewCell.h
//  Appic
//
//  Created by Reinier Wieringa on 13/11/13.
//  Copyright (c) 2013 Voys. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RecentTableViewCell : UITableViewCell
@property (nonatomic, readonly) UIImageView *iconImageView;
@property (nonatomic, readonly) UILabel *nameLabel;
@property (nonatomic, readonly) UILabel *descriptionLabel;
@property (nonatomic, readonly) UILabel *dateTimeLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;

@end
