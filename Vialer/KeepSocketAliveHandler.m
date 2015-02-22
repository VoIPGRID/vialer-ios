//
//  KeepSocketAliveHandler.m
//  Vialer
//
//  Created by Reinier Wieringa on 19/02/15.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "KeepSocketAliveHandler.h"
#import "AppDelegate.h"
#import "Gossip+Extra.h"
#import "PJSIP.h"

@interface KeepSocketAliveHandler ()
@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, strong) NSMutableString *communicationLog;
@property (nonatomic) BOOL sentPing;
@end


const uint8_t pingString[] = "ping\n";
const uint8_t pongString[] = "pong\n";

@implementation KeepSocketAliveHandler

+ (KeepSocketAliveHandler *)sharedKeepSocketAliveHandler {
    static dispatch_once_t pred;
    static KeepSocketAliveHandler *_sharedKeepAliveHandler = nil;

    dispatch_once(&pred, ^{
        _sharedKeepAliveHandler = [[self alloc] init];
    });
    return _sharedKeepAliveHandler;
}

- (id)init {
    self = [super init];
    if (self != nil) {
        if (!self.inputStream)
        {
            CFReadStreamRef readStream;
            CFWriteStreamRef writeStream;
            CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)(@"ha.voys.nl"), 5060, &readStream, &writeStream);

            self.sentPing = NO;
            self.communicationLog = [[NSMutableString alloc] init];
            self.inputStream = (__bridge_transfer NSInputStream *)readStream;
            self.outputStream = (__bridge_transfer NSOutputStream *)writeStream;
            [self.inputStream setProperty:NSStreamNetworkServiceTypeVoIP forKey:NSStreamNetworkServiceType];
            [self.inputStream setDelegate:self];
            [self.outputStream setDelegate:self];
            [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [self.inputStream open];
            [self.outputStream open];

            [[UIApplication sharedApplication] setKeepAliveTimeout:600 handler:^{
                if (self.outputStream)
                {
                    [self.outputStream write:pingString maxLength:strlen((char*)pingString)];
                    [self addEvent:@"Ping sent"];
                }
            }];
        }
    }
    return self;
}

- (void)addEvent:(NSString *)event
{
    [self.communicationLog appendFormat:@"%@\n", event];
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive)
    {
        NSLog(@"App is foreground. New event: %@", event);
    }
    else
    {
        NSLog(@"App is backgrounded. New event: %@", event);
    }
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventNone:
            // do nothing.
            break;

        case NSStreamEventEndEncountered:
            [self addEvent:@"Connection Closed"];
            break;

        case NSStreamEventErrorOccurred:
            [self addEvent:[NSString stringWithFormat:@"Had error: %@", aStream.streamError]];
            break;

        case NSStreamEventHasBytesAvailable:
            if (aStream == self.inputStream)
            {
                [self addEvent:[NSString stringWithFormat:@"Bytes available"]];
                break;

                uint8_t buffer[1024];
                NSInteger bytesRead = [self.inputStream read:buffer maxLength:1024];
                NSString *stringRead = [[NSString alloc] initWithBytes:buffer length:bytesRead encoding:NSUTF8StringEncoding];
                stringRead = [stringRead stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];

                [self addEvent:[NSString stringWithFormat:@"Received: %@", stringRead]];

                if ([stringRead isEqualToString:@"notify"])
                {
                    UILocalNotification *notification = [[UILocalNotification alloc] init];
                    notification.alertBody = @"New VOIP call";
                    notification.alertAction = @"Answer";
                    [self addEvent:@"Notification sent"];
                    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                }
                else if ([stringRead isEqualToString:@"ping"])
                {
                    [self.outputStream write:pongString maxLength:strlen((char*)pongString)];
                }
            }
            break;

        case NSStreamEventHasSpaceAvailable:
            if (aStream == self.outputStream && !self.sentPing)
            {
                self.sentPing = YES;
                if (aStream == self.outputStream)
                {
                    [self.outputStream write:pingString maxLength:strlen((char*)pingString)];
                    [self addEvent:@"Ping sent"];
                }
            }
            break;

        case NSStreamEventOpenCompleted:
            if (aStream == self.inputStream)
            {
                [self addEvent:@"Connection Opened"];
            }
            break;

        default:
            break;
    }
}

@end
