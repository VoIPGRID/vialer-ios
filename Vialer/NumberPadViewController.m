//
//  NumberPadViewController.m
//  Vialer
//
//  Created by Bob Voorneveld on 03/11/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "NumberPadViewController.h"

#import "NumberPadButton.h"

#import <AVFoundation/AVAudioPlayer.h>

@interface NumberPadViewController()

@property (nonatomic, strong) NSDictionary *sounds;

@end

@implementation NumberPadViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // prepare sounds
    [self.sounds count];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    self.sounds = nil;
}

- (IBAction)numberPressed:(NumberPadButton *)sender {
    [self.delegate numberPadPressedWithCharacter:sender.number];
    [self playSoundForCharacter:sender.number];
}

- (IBAction)longPressZeroButton:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        [self playSoundForCharacter:@"0"];
        [self.delegate numberPadPressedWithCharacter:@"+"];
    }
}

- (NSDictionary *)sounds {
    if (!_sounds) {
        NSMutableDictionary *sounds = [NSMutableDictionary dictionary];
        for (NSString *sound in @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"*", @"0", @"#"]) {
            NSString *dtmfFile;
            if ([sound isEqualToString:@"*"]) {
                dtmfFile = @"dtmf-s";
            } else {
                dtmfFile = [NSString stringWithFormat:@"dtmf-%@", sound];
            }
            NSURL *dtmfUrl = [[NSBundle mainBundle] URLForResource:dtmfFile withExtension:@"aif"];
            NSAssert(dtmfUrl, @"No sound available");
            NSError *error;
            AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:dtmfUrl error:&error];
            if (!error) {
                [player prepareToPlay];
            }
            sounds[sound] = player;
        }
        _sounds = [sounds copy];
    }
    return _sounds;
}

- (void)playSoundForCharacter:(NSString *)character {
    AVAudioPlayer *player = self.sounds[character];
    [player setCurrentTime:0];
    [player play];
}

@end
