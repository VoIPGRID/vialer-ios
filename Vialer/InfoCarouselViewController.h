//
//  InfoCarouselViewController.h
//  Vialer
//
//  Created by Reinier Wieringa on 09/09/14.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfoCarouselViewController : UIViewController<UIScrollViewDelegate>
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;

- (IBAction)pageChanged:(id)sender;

@end
