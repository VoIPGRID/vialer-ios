//
//  ConfigureFormView.h
//  Vialer
//
//  Created by Karsten Westra on 21/04/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ConfigTextField.h"

IB_DESIGNABLE
@interface ConfigureFormView : UIView

@property (nonatomic, strong) IBOutlet ConfigTextField *phoneNumberField;
@property (nonatomic, strong) IBOutlet ConfigTextField *outgoingNumberField;

@end
