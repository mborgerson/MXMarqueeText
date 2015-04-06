//
//  AppDelegate.h
//  MXMarqueeTextDemo
//
//  Created by Matt Borgerson on 4/6/15.
//  Copyright (c) 2015 Matt Borgerson. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MXMarqueeText.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSWindow *window;
@property IBOutlet MXMarqueeText *textField;
@property IBOutlet NSTextField *userString;
- (IBAction)changeString:(id)sender;

@end

