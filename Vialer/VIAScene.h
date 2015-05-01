//
//  VAIScene.h
//  Vialer
//
//  Created by Karsten Westra on 28/04/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VIAScene : NSObject

@property (nonatomic, strong) NSMutableArray *onStage;

- (instancetype)initWithView:(UIView *)view;

- (void)runActOne;
- (void)runActTwo;
- (void)runActThree;

- (void)clean;

@end
