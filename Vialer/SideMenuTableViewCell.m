//
//  SideMenuTableViewCell.m
//  Vialer
//
//  Created by Reinier Wieringa on 4/19/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "SideMenuTableViewCell.h"

@interface SideMenuTableViewCell ()
@property (strong, nonatomic) UIImageView *iconImageView;
@property (strong, nonatomic) UILabel *titleLabel;
@end

@implementation SideMenuTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(8.f, 9.f, 23.f, 23.f)];
        self.iconImageView.contentMode = UIViewContentModeCenter;
        
        CGFloat xOffset = CGRectGetMaxX(self.iconImageView.frame) + 16.f;
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(xOffset, 0, CGRectGetWidth(self.frame) - xOffset - 16.f, CGRectGetHeight(self.frame))];
        self.titleLabel.font = [UIFont systemFontOfSize:14.f];
        
        [self.contentView addSubview:self.iconImageView];
        [self.contentView addSubview:self.titleLabel];
        self.separatorInset = UIEdgeInsetsMake(0, 31.f, 0, 0);
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return self;
}

- (void)setMenuItem:(SideMenuItem *)menuItem {
    _menuItem = menuItem;
    self.titleLabel.text = menuItem.title;
    self.iconImageView.image = menuItem.icon;
}

@end
