//
//  PasteableUILabel.h
//  Vialer
//
//  Created by Bob Voorneveld on 03/11/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PasteableUILabelDelegate <NSObject>
- (void)pasteableUILabel:(UILabel *)label didReceivePastedText:(NSString *)text;
@end

@interface PasteableUILabel : UILabel
@property (nonatomic, weak) id<PasteableUILabelDelegate> delegate;

@end
