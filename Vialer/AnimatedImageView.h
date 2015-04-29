//
//  AnimatedImageView.h
//  Vialer
//
//  Created by Karsten Westra on 28/04/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AnimatedImageView : UIImageView

- (void)addPoint:(CGPoint)point;
- (void)animateToNextWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay;

@end
