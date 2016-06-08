//
//  ReachabilityBarViewController.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ReachabilityManager.h"

@class ReachabilityBarViewController;

@protocol ReachabilityBarViewControllerDelegate <NSObject>
/**
 *  This method will be called when the reachability status has changed.
 *
 *  @param status The new ReachabilityStatus
 */
- (void)reachabilityBar:(ReachabilityBarViewController *)reachabilityBar statusChanged:(ReachabilityManagerStatusType)status;

@optional

/**
 *  This method will be called if the bar should be hidden or shown.
 *
 *  @param reachabilityBar ReachabilityBarViewController instance that wants to resize.
 *  @param visible         BOOL that will tell to show or hide.
 */
- (void)reachabilityBar:(ReachabilityBarViewController *)reachabilityBar shouldBeVisible:(BOOL)visible;
@end

@interface ReachabilityBarViewController : UIViewController
/**
 *  Set this as the delegate of this controller to receive updates from the ReachabilityStatus.
 */
@property (weak, nonatomic) id<ReachabilityBarViewControllerDelegate> delegate;

/**
 *  Readonly property indicating whether or not the bar should be displayed.
 */
@property (readonly) BOOL shouldBeVisible;
@end
