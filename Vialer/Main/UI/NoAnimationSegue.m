//
//  NoAnimationSegue.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "NoAnimationSegue.h"

@implementation NoAnimationSegue

-(void)perform {
    [[self sourceViewController] presentViewController:[self destinationViewController] animated:NO completion:nil];
}
@end
