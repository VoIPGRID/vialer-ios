//
//  VAIScene.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

@import UIKit;

typedef NS_ENUM(NSInteger, VIASceneActs) {
    VIASceneActNone,
    VIASceneActOne,
    VIASceneActOneAndHalf,
    VIASceneActTwo,
    VIASceneActThree
};

@interface VIAScene : NSObject

@property (strong, nonatomic) NSMutableArray *onStage;
@property (nonatomic) VIASceneActs currentAct;

- (instancetype)initWithView:(UIView *)view;

- (void)runActOne;
- (void)runActOneInstantly;
- (void)runActOneAndHalf;
- (void)runActTwo;
- (void)runActThree;

- (void)clean;

- (void)animateCloudsOutOfViewWithDuration:(NSTimeInterval)duration;
- (void)animateCloudsIntoViewWithDuration:(NSTimeInterval)duration;

@end
