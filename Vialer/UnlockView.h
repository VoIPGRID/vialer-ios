//
//  UnlockView.h
//  Vialer
//
//  Created by Karsten Westra on 29/04/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UnlockView : UIView 

@property (nonatomic, strong) IBOutlet UILabel *greetingsLabel;
@property (nonatomic, strong) IBOutlet UISlider *slideToCallSlider;
@property (nonatomic, strong) IBOutlet UILabel *slideToCallText;

- (void)setupSlider;

@end
