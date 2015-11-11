//
//  BubblingPoints.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "BubblingPoints.h"

@interface BubblingPoints()

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic) NSInteger count;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UIImage *icon;
@end

static float const BubblingPointsSpeed = .3f;
static int const BubblingPointsIconInset = 11;
static int const BubblingPointsMediumInset = 10;
static int const BubblingPointsSmallInset = 12;

// images
static NSString * const BubblingPointsConnectedIcon = @"connectedIcon";
static NSString * const BubblingPointsDisconnectedIcon = @"disconnectedIcon";

@implementation BubblingPoints

- (void)awakeFromNib {
    [self setup];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.count = 2;
    self.state = BubblingPointsStateIdle;
    self.backgroundColor = nil;
    self.opaque = FALSE;
}

- (void)setupTimer {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:BubblingPointsSpeed target:self selector:@selector(tick) userInfo:nil repeats:YES];
}

- (void)setState:(BubblingPointsState)state {
    // If state isn't changed, lets not do anything.
    if (state == _state) {
        return;
    }
    _state = state;
    if (state == BubblingPointsStateConnecting) {
        [self setupTimer];
    } else {
        [self.timer invalidate];
    }

    switch (state) {
        case BubblingPointsStateConnected:
            self.icon = [UIImage imageNamed:BubblingPointsConnectedIcon];
            break;
        case BubblingPointsStateConnectionFailed:
            self.icon = [UIImage imageNamed:BubblingPointsDisconnectedIcon];
            break;
        default:
            self.icon = nil;
            break;
    }
    [self setNeedsDisplay];
}

- (UIImageView *)iconView {
    if (!_iconView) {
        CGSize viewSize = CGSizeMake(self.bounds.size.width - BubblingPointsIconInset, self.bounds.size.width - BubblingPointsIconInset);
        _iconView = [[UIImageView alloc] initWithFrame:CGRectMake((self.bounds.size.width - viewSize.width) / 2,
                                                                  self.bounds.size.height / 2 - 0.5 * viewSize.height,
                                                                  viewSize.width,
                                                                  viewSize.height)];
        [self addSubview:_iconView];
    }
    return _iconView;
}

- (void)setIcon:(UIImage *)icon {
    self.iconView.image = icon;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGSize sizeSmall = CGSizeMake(self.bounds.size.width - BubblingPointsSmallInset, self.bounds.size.width - BubblingPointsSmallInset);
    CGSize sizeMedium = CGSizeMake(self.bounds.size.width - BubblingPointsMediumInset, self.bounds.size.width - BubblingPointsMediumInset);
    CGSize sizeLarge = CGSizeMake(self.bounds.size.width, self.bounds.size.width);

    CGPoint positions[] = {
        CGPointMake(sizeLarge.width/2, self.bounds.size.height / 2),
        CGPointMake(sizeLarge.width/2, self.bounds.size.height - (sizeMedium.height/2)),
        CGPointMake(sizeLarge.width/2, sizeMedium.height/2)
    };
    
    for (int i = 0; i < 3; i++) {
        CGSize size = sizeSmall;
        switch (self.state) {
            case BubblingPointsStateIdle:
                if (i == 0)
                    size = sizeMedium;
                break;
            case BubblingPointsStateConnecting:
                if (i == self.count)
                    size = sizeMedium;
                break;
            case BubblingPointsStateConnected:
            case BubblingPointsStateConnectionFailed:
                if (i == 0)
                    size = sizeLarge;
                break;
            default:
                break;
        }
        [self drawCirleInContext:context withPosition:positions[i] andSize:size];
    }
}

- (void)drawCirleInContext:(CGContextRef)context withPosition:(CGPoint)position andSize:(CGSize)size {
    CGContextSaveGState(context);
    UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(position.x - size.width / 2, position.y - size.height / 2, size.width, size.height)];
    [circle addClip];
    [self.color setFill];
    [circle fill];
    CGContextRestoreGState(context);
}

- (void)tick {
    self.count = (self.count + 1) % 3;
    [self setNeedsDisplay];
}

@end
