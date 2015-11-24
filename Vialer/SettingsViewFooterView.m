//
//  SettingsViewFooterView.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "SettingsViewFooterView.h"

@interface SettingsViewFooterView ()
@property (nonatomic, strong)UILabel *textLabel;
@property (nonatomic, strong)UIImageView *logoView;
@end

@implementation SettingsViewFooterView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.textLabel = [[UILabel alloc] initWithFrame:CGRectInset(frame, 10, 8)];
        self.textLabel.text = NSLocalizedString(@"ACCOUNT_FOOTER_OWN_NUMBER_DESCRIPTION", nil);
        self.textLabel.textColor = [UIColor darkGrayColor];
        self.textLabel.font = [UIFont systemFontOfSize:12];
        self.textLabel.numberOfLines = 3;
        self.textLabel.adjustsFontSizeToFitWidth = YES;
        self.textLabel.minimumScaleFactor = 0.5;
        
        self.logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logoBlackWhite"]];
        
        [self addSubview:self.textLabel];
        [self addSubview:self.logoView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self sizeToFit];
    [self.textLabel sizeToFit];
    [self.logoView sizeToFit];

    self.logoView.center = CGPointMake(self.center.x, CGRectGetMaxY(self.textLabel.frame)+60);
}

@end
