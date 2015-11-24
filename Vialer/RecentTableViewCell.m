//
//  RecentTableViewCell.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "RecentTableViewCell.h"

#import "NSDate+RelativeDate.h"

#import <QuartzCore/QuartzCore.h>

static NSString * const RecentTableViewCellOutboundImageName = @"outbound";

@interface RecentTableViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateTimeLabel;

@end

@implementation RecentTableViewCell

#pragma mark - properties

- (void)setCallDirection:(CallDirection)callDirection {
    if (callDirection == CallDirectionOutbound) {
        self.iconImageView.image = [UIImage imageNamed:RecentTableViewCellOutboundImageName];
    } else {
        self.iconImageView.image = nil;
    }
}

- (void)setName:(NSString *)name {
    self.nameLabel.text = name;
}

- (void)setSubtitle:(NSString *)subtitle {
    self.subtitleLabel.text = subtitle;
}

- (void)setDate:(NSString *)date {
    self.dateTimeLabel.text = [[NSDate dateFromString:date] relativeDayTimeString];
}

- (void)setAnswered:(BOOL)answered {
    if (answered) {
        self.nameLabel.textColor = [UIColor blackColor];
    } else {
        self.nameLabel.textColor = [UIColor redColor];
    }
}

@end
