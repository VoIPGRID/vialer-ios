//
//  AccountViewFooterView.m
//  Vialer
//
//  Created by Harold on 22/06/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "AccountViewFooterView.h"

@interface AccountViewFooterView ()
@property (nonatomic, strong)UILabel *textLabel;
@property (nonatomic, strong)UIImageView *logoView;
@end

@implementation AccountViewFooterView


- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        //NSLog(@"AccountViewFooterView frame: %@", NSStringFromCGRect(frame));

        self.textLabel = [[UILabel alloc] initWithFrame:CGRectInset(frame, 10, 8)];
        self.textLabel.text = NSLocalizedString(@"Your own number will be used to setup a normal call using your business number when there is no 4G of wifi network available.", nil);
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
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    [super layoutSubviews];
    [self sizeToFit];
    [self.textLabel sizeToFit];
    [self.logoView sizeToFit];

    //NSLog(@"%@", NSStringFromCGSize(self.textLabel.frame.size));
    self.logoView.center = CGPointMake(self.center.x, self.textLabel.frame.size.height+60);
    //NSLog(@"LogoView center: %@", NSStringFromCGPoint(self.logoView.center));
}

@end
