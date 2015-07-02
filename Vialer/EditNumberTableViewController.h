//
//  EditNumberTableViewController.h
//  Vialer
//
//  Created by Harold on 22/06/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EditNumberDelegate <NSObject>
@required
- (void)numberHasChanged:(NSString *)newNumber;
@end

@interface EditNumberTableViewController : UITableViewController <UITextFieldDelegate>
@property (nonatomic, weak) id <EditNumberDelegate> delegate;
@property (nonatomic, weak) NSString *numberToEdit;
@end
