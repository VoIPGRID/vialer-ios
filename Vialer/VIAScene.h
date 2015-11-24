//
//  VAIScene.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VIAScene : NSObject

@property (nonatomic, strong) NSMutableArray *onStage;

- (instancetype)initWithView:(UIView *)view;

- (void)runActOne;
- (void)runActOneInstantly;
- (void)runActTwo;
- (void)runActThree;

- (void)clean;

- (void)animateCloudsOutOfViewWithDuration:(NSTimeInterval)duration;
- (void)animateCloudsIntoViewWithDuration:(NSTimeInterval)duration;

@end
