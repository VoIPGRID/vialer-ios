//
//  AvailabilityViewController.h
//  Vialer
//
//  Created by Redmer Loen on 15-09-15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AvailabilityViewControllerDelegate <NSObject>
- (void)availabilityHasChanged;
@end

@interface AvailabilityViewController : UITableViewController

@property (nonatomic, weak) id <AvailabilityViewControllerDelegate> delegate;
@end
