//
//  VAIScene.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "VIAScene.h"

#import "AnimatedImageView.h"

static NSString * const VIASceneCloudOneImageName = @"cloud";
static NSString * const VIASceneCloudTwoImageName = @"cloud-1";
static NSString * const VIASceneCloudThreeImageName = @"cloud-2";
static CGFloat const VIASceneCloudAlpha = 0.3;

@implementation VIAScene {
    UIView *_view;
}

- (instancetype)initWithView:(UIView *)view {
    self = [super init];
    if (self) {
        _view = view;
        _onStage = [NSMutableArray array];

        [self preparePlay];
        [self scriptForPlay];
    }
    return self;
}

#pragma mark - Xloud animation preparation
/* Initially position all clouds outside of the screen */
- (void)preparePlay {
    AnimatedImageView *cloud1ImageView = [[AnimatedImageView alloc] initWithImage:[UIImage imageNamed:VIASceneCloudOneImageName]];
    cloud1ImageView.alpha = VIASceneCloudAlpha;
    [cloud1ImageView setCenter:CGPointMake(0.f, CGRectGetMaxY(_view.frame) + CGRectGetHeight(cloud1ImageView.frame))];
    [_view addSubview:cloud1ImageView];
    [_view sendSubviewToBack:cloud1ImageView];
    [_onStage addObject:cloud1ImageView];

    AnimatedImageView *cloud2ImageView = [[AnimatedImageView alloc] initWithImage:[UIImage imageNamed:VIASceneCloudTwoImageName]];
    [cloud2ImageView setCenter:CGPointMake(CGRectGetMaxX(_view.frame), CGRectGetMaxY(_view.frame) + CGRectGetHeight(cloud2ImageView.frame))];
    cloud2ImageView.alpha = VIASceneCloudAlpha;
    [_view addSubview:cloud2ImageView];
    [_view sendSubviewToBack:cloud2ImageView];
    [_onStage addObject:cloud2ImageView];

    //Configure view, cloude top right
    AnimatedImageView *cloud3ImageView = [[AnimatedImageView alloc] initWithImage:[UIImage imageNamed:VIASceneCloudOneImageName]];
    [cloud3ImageView setCenter:CGPointMake(0.f, CGRectGetMaxY(_view.frame) + CGRectGetHeight(cloud3ImageView.frame))];
    cloud3ImageView.alpha = VIASceneCloudAlpha;
    [_view addSubview:cloud3ImageView];
    [_view sendSubviewToBack:cloud3ImageView];
    [_onStage addObject:cloud3ImageView];

    //Configure view, cloud top left
    AnimatedImageView *cloud4ImageView = [[AnimatedImageView alloc] initWithImage:[UIImage imageNamed:VIASceneCloudThreeImageName]];
    [cloud4ImageView setCenter:CGPointMake(CGRectGetMaxX(_view.frame), CGRectGetMaxY(_view.frame) + CGRectGetHeight(cloud4ImageView.frame))];
    cloud4ImageView.alpha = VIASceneCloudAlpha;
    [_view addSubview:cloud4ImageView];
    [_view sendSubviewToBack:cloud4ImageView];
    [_onStage addObject:cloud4ImageView];

    AnimatedImageView *cloud5ImageView = [[AnimatedImageView alloc] initWithImage:[UIImage imageNamed:VIASceneCloudTwoImageName]];
    [cloud5ImageView setCenter:CGPointMake(-60, CGRectGetMaxY(_view.frame) + CGRectGetHeight(cloud3ImageView.frame))];
    cloud5ImageView.alpha = VIASceneCloudAlpha;
    [_view addSubview:cloud5ImageView];
    [_view sendSubviewToBack:cloud5ImageView];
    [_onStage addObject:cloud5ImageView];

    AnimatedImageView *cloud6ImageView = [[AnimatedImageView alloc] initWithImage:[UIImage imageNamed:VIASceneCloudOneImageName]];
    [cloud6ImageView setCenter:CGPointMake(CGRectGetMaxX(_view.frame), CGRectGetMaxY(_view.frame) +  CGRectGetHeight(cloud4ImageView.frame))];
    cloud6ImageView.alpha = VIASceneCloudAlpha;
    [_view addSubview:cloud6ImageView];
    [_view sendSubviewToBack:cloud6ImageView];
    [_onStage addObject:cloud6ImageView];

    AnimatedImageView *cloudView = [[AnimatedImageView alloc] initWithImage:[UIImage imageNamed:VIASceneCloudThreeImageName]];
    [cloudView setCenter:CGPointMake(0, CGRectGetMaxY(_view.frame) +  CGRectGetHeight(cloudView.frame))];
    cloudView.alpha = VIASceneCloudAlpha;
    [_view addSubview:cloudView];
    [_view sendSubviewToBack:cloud6ImageView];
    [_onStage addObject:cloudView];

    //Debugging
    //    ((UIView *)_onStage[0]).backgroundColor = [UIColor blueColor];
    //    ((UIView *)_onStage[1]).backgroundColor = [UIColor redColor];
    //    ((UIView *)_onStage[2]).backgroundColor = [UIColor greenColor];
    //    ((UIView *)_onStage[3]).backgroundColor = [UIColor grayColor];
    //    ((UIView *)_onStage[4]).backgroundColor = [UIColor yellowColor];
    //    ((UIView *)_onStage[5]).backgroundColor = [UIColor purpleColor];
    //    ((UIView *)_onStage[6]).backgroundColor = [UIColor brownColor];
}


/** Then add points which form a path*/
- (void)scriptForPlay {
    /** Act 1 */
    AnimatedImageView *firstCloud = _onStage[0];
    [firstCloud addPoint:CGPointMake(0.f, 100.f)];///4.f * CGRectGetHeight(_view.frame))];
    [firstCloud addPoint:CGPointMake(0.f, - CGRectGetHeight(firstCloud.frame))];

    AnimatedImageView *cloudOne = _onStage[1];
    [cloudOne addPoint:CGPointMake(CGRectGetMaxX(_view.frame), 0.f)];
    [cloudOne addPoint:CGPointMake(CGRectGetMaxX(_view.frame), -CGRectGetHeight(cloudOne.frame))];

    AnimatedImageView *cloudThree = _onStage[2];
    [cloudThree addPoint:CGPointMake(0.f, 4.f/5.f * CGRectGetHeight(_view.frame))];
    [cloudThree addPoint:CGPointMake(0.f, -CGRectGetHeight(cloudThree.frame))];

    AnimatedImageView *cloudFour = _onStage[3];
    [cloudFour addPoint:CGPointMake(CGRectGetMaxX(_view.frame), 6.f / 7.f * CGRectGetMaxY(_view.frame))];
    [cloudFour addPoint:CGPointMake(CGRectGetMaxX(_view.frame), 1.f / 7.f * CGRectGetMaxY(_view.frame))];
    [cloudFour addPoint:CGPointMake(CGRectGetMaxX(_view.frame), -CGRectGetHeight(cloudFour.frame))];

    AnimatedImageView *cloudFive = _onStage[4];
    [cloudFive addPoint:CGPointMake(-55, 1.5f/5.f * CGRectGetMaxY(_view.frame))];
    [cloudFive addPoint:CGPointMake(-55, -CGRectGetHeight(cloudFive.frame))];

    AnimatedImageView *cloudSix = _onStage[5];
    [cloudSix addPoint:CGPointMake(CGRectGetMaxX(_view.frame) + 10.f, 0.85f * CGRectGetMaxY(_view.frame))];
    [cloudSix addPoint:CGPointMake(CGRectGetMaxX(_view.frame), 1.f / 7.f * CGRectGetMaxY(_view.frame))];

    // 6 higher
    AnimatedImageView *cloudSeven = _onStage[6];
    [cloudSeven addPoint:CGPointMake(0.f, CGRectGetMidY(_view.bounds) - 10.0f)];
}

- (void)runActOneInstantly {
    [_onStage[0] animateToNextWithDuration:0.f delay:0.f];
    [_onStage[1] animateToNextWithDuration:0.f delay:0.f];
    [_onStage[2] animateToNextWithDuration:0.f delay:0.f];
    [_onStage[3] animateToNextWithDuration:0.f delay:0.f];
}

- (void) runActOne {
    [_onStage[0] animateToNextWithDuration:1.8 delay:0.2f];
    [_onStage[1] animateToNextWithDuration:1.8 delay:0.2f];
    [_onStage[2] animateToNextWithDuration:1.4 delay:0.6f];
    [_onStage[3] animateToNextWithDuration:1.4 delay:0.6f];
}

- (void)runActTwo {
    [_onStage[0] animateToNextWithDuration:1.8 delay:0.2f];
    [_onStage[1] animateToNextWithDuration:1.8 delay:0.2f];
    [_onStage[2] animateToNextWithDuration:1.4 delay:0.6f];
    [_onStage[3] animateToNextWithDuration:1.4 delay:0.6f];
    [_onStage[4] animateToNextWithDuration:1.4 delay:0.6f];
    [_onStage[5] animateToNextWithDuration:1.4 delay:0.6f];
}

- (void)runActThree {
    [_onStage[3] animateToNextWithDuration:1.4 delay:0.6f];
    [_onStage[4] animateToNextWithDuration:1.4 delay:0.6f];
    [_onStage[5] animateToNextWithDuration:1.4 delay:0.6f];
    [_onStage[6] animateToNextWithDuration:1.4 delay:0.6f];
}

- (void)clean {
    [_onStage makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_onStage removeAllObjects];
}

- (void)animateCloudsOutOfViewWithDuration:(NSTimeInterval)duration {
    AnimatedImageView * cloudView = _onStage[0];
    CGPoint nextPosition = CGPointMake(cloudView.center.x -55, cloudView.center.y);
    [cloudView moveToPoint:nextPosition withDuration:duration delay:0 andRemoveWhenOffScreen:NO];

    //Top right in ConfigureView
    cloudView = _onStage[3];
    nextPosition = CGPointMake(cloudView.center.x + 65, cloudView.center.y);
    [cloudView moveToPoint:nextPosition withDuration:duration delay:0 andRemoveWhenOffScreen:NO];

    //    //Top left in ConfigureView
    //    cloudView = _onStage[4];
    //    nextPosition = CGPointMake(cloudView.center.x - 60, cloudView.center.y);
    //    [cloudView moveToPoint:nextPosition withDuration:duration delay:0 andRemoveWhenOffScreen:NO];
}

- (void)animateCloudsIntoViewWithDuration:(NSTimeInterval)duration {
    AnimatedImageView * cloudView = _onStage[0];
    CGPoint nextPosition = CGPointMake(0, cloudView.center.y);
    [_onStage[0] moveToPoint:nextPosition withDuration:duration delay:0 andRemoveWhenOffScreen:NO];

    //Top right in ConfigureView
    cloudView = _onStage[3];
    nextPosition = CGPointMake(CGRectGetMaxX(_view.frame), cloudView.center.y);
    [cloudView moveToPoint:nextPosition withDuration:duration delay:0 andRemoveWhenOffScreen:NO];

    //Top left in ConfigureView
    cloudView = _onStage[4];
    nextPosition = CGPointMake(-60, cloudView.center.y);
    [cloudView moveToPoint:nextPosition withDuration:duration delay:0 andRemoveWhenOffScreen:NO];
}

@end
