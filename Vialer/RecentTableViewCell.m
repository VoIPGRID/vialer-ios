//
//  ChatMessageTableViewCell.m
//  Vialer
//
//  Created by Reinier Wieringa on 13/11/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "RecentTableViewCell.h"

#import <QuartzCore/QuartzCore.h>

@interface RecentTableViewCell ()
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, strong) UILabel *dateTimeLabel;
@end

@implementation RecentTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.layer.shouldRasterize = YES;
        self.layer.rasterizationScale = [UIScreen mainScreen].scale;
        
        [self.contentView addSubview:self.nameLabel];
        [self.contentView addSubview:self.descriptionLabel];
        [self.contentView addSubview:self.dateTimeLabel];
        [self.contentView addSubview:self.iconImageView];
    }
    return self;
}

# pragma mark - properties

- (UIImageView *)iconImageView {
    if (!_iconImageView) {
        _iconImageView = [[UIImageView alloc] init];
    }
    return _iconImageView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.backgroundColor = [UIColor clearColor];
        _nameLabel.font = [UIFont systemFontOfSize:15.f];
        _nameLabel.numberOfLines = 1;
        _nameLabel.textColor = [UIColor blackColor];
        _nameLabel.opaque = YES;
    }
    return _nameLabel;
}

- (UILabel *)descriptionLabel {
    if (!_descriptionLabel) {
        _descriptionLabel = [[UILabel alloc] init];
        _descriptionLabel.backgroundColor = [UIColor clearColor];
        _descriptionLabel.font = [UIFont systemFontOfSize:10.f];
        _descriptionLabel.textColor = [UIColor colorWithRed:0x54 / 255.f green:0x58 / 255.f blue:0x6d / 255.f alpha:1.f];
        _descriptionLabel.numberOfLines = 1;
        _descriptionLabel.opaque = YES;
    }
    return _descriptionLabel;
}

- (UILabel *)dateTimeLabel {
    if (!_dateTimeLabel) {
        _dateTimeLabel = [[UILabel alloc] init];
        _dateTimeLabel.backgroundColor = [UIColor clearColor];
        _dateTimeLabel.font = [UIFont systemFontOfSize:12.f];
        _dateTimeLabel.textColor = [UIColor colorWithRed:0xb4 / 255.f green:0xb4 / 255.f blue:0xb4 / 255.f alpha:1.f];
        _dateTimeLabel.numberOfLines = 1;
        _dateTimeLabel.opaque = YES;
    }
    return _dateTimeLabel;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGSize dateTimeSize = [self.dateTimeLabel.text sizeWithAttributes:@{NSFontAttributeName: self.dateTimeLabel.font}];
    self.dateTimeLabel.frame = CGRectMake(self.contentView.frame.size.width - dateTimeSize.width, (self.contentView.frame.size.height - dateTimeSize.height) / 2.f, dateTimeSize.width, dateTimeSize.height);

    CGSize nameSize = [self.nameLabel.text sizeWithAttributes:@{NSFontAttributeName: self.nameLabel.font}];
    self.nameLabel.frame = CGRectMake(29.f, 6.f, nameSize.width, nameSize.height);
    
    CGSize phoneTypeSize = [self.descriptionLabel.text sizeWithAttributes:@{NSFontAttributeName: self.descriptionLabel.font}];
    self.descriptionLabel.frame = CGRectMake(self.nameLabel.frame.origin.x, self.contentView.frame.size.height - phoneTypeSize.height - 8.f, phoneTypeSize.width, phoneTypeSize.height);
    
    if (self.iconImageView.image) {
        CGSize imageSize = self.iconImageView.image.size;
        self.iconImageView.frame = CGRectMake((self.nameLabel.frame.origin.x - imageSize.width) / 2.f, (self.contentView.frame.size.height - imageSize.height) / 2.f, imageSize.width, imageSize.height);
    }
}

@end
