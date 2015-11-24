//
//  SipCallingButtonViewController.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "SipCallingButtonViewController.h"

#import "Configuration.h"
#import "SipCallingButton.h"

static float const SipCallingButtonPressedAlpha = 0.5;

@interface SipCallingButtonViewController ()
@property (strong, nonatomic) IBOutletCollection(SipCallingButton) NSArray *sipCallingButtons;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *sipCallingLabels;
@property (weak, nonatomic) IBOutlet SipCallingButton *soundOffButton;
@property (weak, nonatomic) IBOutlet SipCallingButton *numbersButton;
@property (weak, nonatomic) IBOutlet SipCallingButton *pauseButton;
@property (weak, nonatomic) IBOutlet SipCallingButton *speakerButton;
@property (strong, nonatomic) UIColor *pressedColor;
@property (strong, nonatomic) UIColor *textColor;
@end

@implementation SipCallingButtonViewController

# pragma mark - properties
- (UIColor *)pressedColor {
    if (!_pressedColor) {
        _pressedColor = [[Configuration tintColorForKey:ConfigurationNumberPadButtonPressedColor] colorWithAlphaComponent:SipCallingButtonPressedAlpha];
    }
    return _pressedColor;
}

- (UIColor *)textColor {
    if (!_textColor) {
        _textColor = [Configuration tintColorForKey:ConfigurationNumberPadButtonTextColor];
    }
    return _textColor;
}

# pragma mark - button actions
- (IBAction)soundOffButton:(SipCallingButton *)sender {
    [sender setSelected:!sender.isSelected];
    [self.delegate soundOffButtonPressed:sender.isSelected];
}

- (IBAction)numbersButton:(SipCallingButton *)sender {

}

- (IBAction)pauseButton:(SipCallingButton *)sender {
    [sender setSelected:!sender.isSelected];
    [self.delegate pauseButtonPressed:sender.isSelected];
}

- (IBAction)speakerButton:(SipCallingButton *)sender {
    [sender setSelected:!sender.isSelected];
    [self.delegate speakerButtonPressed:sender.isSelected];
}

@end