//
//  UnlockView.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "UnlockView.h"

@interface UnlockView ()
@property (nonatomic, weak) IBOutlet UILabel *helloLabel;
@end

@implementation UnlockView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.helloLabel.text = NSLocalizedString(@"Hello", nil);
}

@end
