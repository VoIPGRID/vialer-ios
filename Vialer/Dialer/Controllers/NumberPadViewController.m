//
//  NumberPadViewController.m
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
    [self setupSounds];
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

- (void)setupSounds {
    if (!self.sounds) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
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
            self.sounds = [sounds copy];
        });
    }
}

- (void)playSoundForCharacter:(NSString *)character {
    AVAudioPlayer *player = self.sounds[character];
    [player setCurrentTime:0];
    [player play];
}

@end
