//
//  EditNumberViewController.h
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EditNumberViewControllerDelegate
- (void)numberHasChanged:(NSString *)newNumber;
@end

@interface EditNumberViewController : UIViewController
@property (weak, nonatomic) NSString *numberToEdit;
@property (weak, nonatomic) id<EditNumberViewControllerDelegate> delegate;
@end
