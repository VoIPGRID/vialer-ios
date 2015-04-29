//
//  LogInViewController.h
//  Vialer
//
//  Created by Reinier Wieringa on 06/11/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TrackedViewController.h"
#import "AnimatedImageView.h"
#import "LoginFormView.h"
#import "ConfigureFormView.h"
#import "UnlockView.h"

@interface LogInViewController : TrackedViewController <UITextFieldDelegate> {
    IBOutlet UISlider *slideToUnlock;
    IBOutlet UILabel *myLabel;
}

@property (nonatomic, strong) IBOutlet AnimatedImageView *logoView;
@property (nonatomic, strong) IBOutlet LoginFormView *loginFormView;
@property (nonatomic, strong) IBOutlet ConfigureFormView *configureFormView;
@property (strong, nonatomic) IBOutlet UnlockView *unlockView;


@property (nonatomic, strong) IBOutlet UIView *sliderView;

-(IBAction)unlockIt;
-(IBAction)fadeLabel;

@end
