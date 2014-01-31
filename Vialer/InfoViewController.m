//
//  InfoViewController.m
//  Vialer
//
//  Created by Reinier Wieringa on 11/12/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "InfoViewController.h"

@interface InfoViewController ()

@end

@implementation InfoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Information", nil);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"]];
    NSAssert(config != nil, @"Config.plist not found!");

    NSString *howItWorks = [[config objectForKey:@"URLS"] objectForKey:@"How it works"];
    NSAssert(howItWorks != nil, @"URLS - How it works not found in Config.plist!");

    NSData *htmlData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"info" ofType:@"html"]];
    if (htmlData) {
        NSString *body = [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
        body = [body stringByReplacingOccurrencesOfString:@"<#URLS - How it works#>" withString:howItWorks];

        NSString *htmlString = [NSString stringWithFormat:@"<html>\n"
                                "<head>\n"
                                "<style type=\"text/css\">\n"
                                "body {color:#000; background-color:transparent; font-family: \"HelveticaNeue-Light\", \"Helvetica Neue Light\", \"Helvetica Neue\", Helvetica; font-size: 17px;}\n"
                                "h1 {font-family: \"HelveticaNeue-Medium\", \"Helvetica Neue Medium\", \"Helvetica Neue\", Helvetica; font-weight: normal;}\n"
                                "</style>\n"
                                "</head>\n"
                                "<body>%@</body>\n"
                                "</html>", body];
        [self.webView loadHTMLString:htmlString baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
    }
    
    id scrollview = [self.webView.subviews objectAtIndex:0];
    for (UIView *subview in [scrollview subviews]) {
        if ([subview isKindOfClass:[UIImageView class]]) {
            subview.hidden = YES;
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Web View Delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
    
    return YES;
}

@end
