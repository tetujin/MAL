//
//  ViewController.h
//  MAL
//
//  Created by Yuuki Nishiyama on 2015/01/08.
//  Copyright (c) 2015年 tetujin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>

static id monitorLeftMouseDown;
static id monitorRightMouseDown;
static id monitorKeyDown;

@interface ViewController : NSViewController <NSApplicationDelegate>

@property (readwrite) NSDateFormatter *logDateFormatter;
@property (readwrite) NSNumber *keyPressCounter;
@property (readwrite) NSNumber *leftMouseCounter;
@property (readwrite) NSNumber *rightMouseCounter;
@property (nonatomic, retain) IBOutlet NSTextField *userNameField;

@property (unsafe_unretained) IBOutlet NSTextView *logTextField;

@property (readwrite) BOOL loggingEnabled;

- (IBAction)pushedSetNameButton:(id)sender;

@end
