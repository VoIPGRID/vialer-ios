//
//  SelectRecentsFilterViewController.h
//  Vialer
//
//  Created by Reinier Wieringa on 18/12/13.
//  Copyright (c) 2013 Voys. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    RecentsFilterSelf,
    RecentsFilterNone,
} RecentsFilter;

#define RECENTS_FILTER_UPDATED_NOTIFICATION @"recents.filter.updated"

@class SelectRecentsFilterViewController;

@protocol SelectRecentsFilterViewControllerDelegate <NSObject>
- (void)selectRecentsFilterViewController:(SelectRecentsFilterViewController *)selectRecentsFilterViewController didFinishWithRecentsFilter:(RecentsFilter)recentsFilter;
@end

@interface SelectRecentsFilterViewController : UIViewController<UIPickerViewDataSource, UIPickerViewDelegate>
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (nonatomic, assign) RecentsFilter recentsFilter;
@property (nonatomic, assign) id <SelectRecentsFilterViewControllerDelegate> delegate;
@end
