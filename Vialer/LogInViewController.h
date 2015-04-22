//
//  LogInViewController.h
//  Vialer
//
//  Created by Reinier Wieringa on 06/11/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TrackedViewController.h"
#import "LoginFormView.h"
#import "ConfigureFormView.h"

@interface LogInViewController : TrackedViewController

@property (nonatomic, strong) IBOutlet UIImageView *logoView;
@property (nonatomic, strong) IBOutlet LoginFormView *loginFormView;
@property (nonatomic, strong) IBOutlet ConfigureFormView *configureFormView;

@end
