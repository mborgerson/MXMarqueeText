//
//  AppDelegate.m
//  MXMarqueeTextDemo
//
//  Created by Matt Borgerson on 4/6/15.
//  Copyright (c) 2015 Matt Borgerson. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    self.textField.stringValue = @"Try setting a custom string using the box below, then press [Enter].";
    
    // You can use custom fonts
    self.textField.font = CFBridgingRetain([NSFont fontWithName:@"Marker Felt" size:17]);
    
    // And custom colors
    self.textField.backgroundColor = [NSColor yellowColor];
}

- (IBAction)changeString:(id)sender {
    [self.textField setStringValue:self.userString.stringValue];
}

@end
