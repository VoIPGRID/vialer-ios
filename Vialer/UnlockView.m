//
//  UnlockView.m
//  Vialer
//
//  Created by Karsten Westra on 29/04/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "UnlockView.h"

@interface UnlockView ()
@property (nonatomic, weak) IBOutlet UILabel *helloLabel;
@end

@implementation UnlockView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.helloLabel.text = NSLocalizedString(@"Hello", nil);
    [self.letsGoButton setTitle:NSLocalizedString(@"Lets get started", nil) forState:UIControlStateNormal];
    
    // Load the styling colors
    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"]];
    NSAssert(config != nil, @"Config.plist not found!");
    NSArray *currentTintColor = [[config objectForKey:@"Tint colors"] objectForKey:@"TabBar"];
    NSAssert(currentTintColor != nil && currentTintColor.count == 3, @"Tint colors - TabBar not found in Config.plist!");
    
    [self.letsGoButton setTitleColor:[UIColor colorWithRed:[currentTintColor[0] intValue] / 255.f green:[currentTintColor[1] intValue] / 255.f blue:[currentTintColor[2] intValue] / 255.f alpha:1.f]
                            forState:UIControlStateNormal];
}

@end
