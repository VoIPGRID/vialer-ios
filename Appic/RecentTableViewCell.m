//
//  ChatMessageTableViewCell.m
//  Appic
//
//  Created by Reinier Wieringa on 13/11/13.
//  Copyright (c) 2013 Voys. All rights reserved.
//

#import "RecentTableViewCell.h"

#import <QuartzCore/QuartzCore.h>

@interface RecentTableViewCell ()
@end

@implementation RecentTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        _iconImageView = [[UIImageView alloc] init];
        
        _nameLabel = [[UILabel alloc] init];
        self.nameLabel.backgroundColor = [UIColor clearColor];
        self.nameLabel.font = [UIFont boldSystemFontOfSize:18.f];
        self.nameLabel.textColor = [UIColor blackColor];
        self.nameLabel.opaque = YES;

        _descriptionLabel = [[UILabel alloc] init];
        self.descriptionLabel.backgroundColor = [UIColor clearColor];
        self.descriptionLabel.font = [UIFont systemFontOfSize:12.f];
        self.descriptionLabel.textColor = [UIColor colorWithRed:0x54 / 255.f green:0x58 / 255.f blue:0x6d / 255.f alpha:1.f];
        self.descriptionLabel.opaque = YES;

        _dateTimeLabel = [[UILabel alloc] init];
        self.dateTimeLabel.backgroundColor = [UIColor clearColor];
        self.dateTimeLabel.font = [UIFont systemFontOfSize:14.f];
        self.dateTimeLabel.textColor = [UIColor colorWithRed:0xb4 / 255.f green:0xb4 / 255.f blue:0xb4 / 255.f alpha:1.f];
        self.dateTimeLabel.opaque = YES;

        self.layer.shouldRasterize = YES;
        self.layer.rasterizationScale = [UIScreen mainScreen].scale;
        
        [self.contentView addSubview:self.nameLabel];
        [self.contentView addSubview:self.descriptionLabel];
        [self.contentView addSubview:self.dateTimeLabel];
        [self.contentView addSubview:self.iconImageView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize dateTimeSize = [self.dateTimeLabel.text sizeWithFont:self.dateTimeLabel.font constrainedToSize:CGSizeMake(80.0f, CGFLOAT_MAX)];
    self.dateTimeLabel.frame = CGRectMake(self.contentView.frame.size.width - 7.f - dateTimeSize.width, (self.contentView.frame.size.height - dateTimeSize.height) / 2.f, dateTimeSize.width, dateTimeSize.height);

    CGSize nameSize = [self.nameLabel.text sizeWithFont:self.nameLabel.font constrainedToSize:CGSizeMake(self.dateTimeLabel.frame.origin.x, CGFLOAT_MAX)];
    self.nameLabel.frame = CGRectMake(16.f, 4.f, nameSize.width, nameSize.height);
    
    CGSize phoneTypeSize = [self.descriptionLabel.text sizeWithFont:self.descriptionLabel.font constrainedToSize:CGSizeMake(self.dateTimeLabel.frame.origin.x, CGFLOAT_MAX)];
    self.descriptionLabel.frame = CGRectMake(self.nameLabel.frame.origin.x, self.contentView.frame.size.height - phoneTypeSize.height - 4.f, phoneTypeSize.width, phoneTypeSize.height);
    
    if (self.iconImageView.image) {
        CGSize imageSize = self.iconImageView.image.size;
        self.iconImageView.frame = CGRectMake((self.nameLabel.frame.origin.x - imageSize.width) / 2.f, (self.contentView.frame.size.height - imageSize.height) / 2.f, imageSize.width, imageSize.height);
    }
}

@end
