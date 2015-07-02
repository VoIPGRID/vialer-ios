//
//  ContactTableViewCell.m
//  Vialer
//
//  Created by Johannes Nevels on 23-04-15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "ContactTableViewCell.h"

@implementation ContactTableViewCell

- (void) populateBasedOnContactDict:(NSDictionary *)contactDict {
    NSString *firstName = contactDict[@"firstName"];
    NSString *lastName = contactDict[@"lastName"];
    NSString *companyName = contactDict[@"companyName"];
    
    NSString *fullName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
    fullName = [fullName stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
    NSMutableAttributedString *fullNameAttrString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", fullName]];
    
    
    NSRange boldedRange = NSMakeRange(0, fullName.length);
    
    if (firstName.length > 0 && lastName.length > 0) {
        boldedRange = NSMakeRange(fullName.length - lastName.length, lastName.length);
    }
    
    if (fullName.length == 0) {
        boldedRange = NSMakeRange(0, companyName.length);
        fullNameAttrString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", companyName]];
    }
    
    [fullNameAttrString beginEditing];
    [fullNameAttrString addAttribute:NSFontAttributeName
                               value:[UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0]
                               range:boldedRange];
    
    self.textLabel.attributedText = fullNameAttrString;
}

@end
