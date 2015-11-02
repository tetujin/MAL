//
//  AppDelegate.m
//  MAL
//
//  Created by Yuuki Nishiyama on 2015/01/09.
//  Copyright (c) 2015年 tetujin. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self enableLoginItem];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


/**
 * Auto Login
 */
- (void)enableLoginItem
{
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath: [[NSBundle mainBundle] bundlePath]];
    
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemLast, NULL, NULL, url, NULL, NULL);
    if (item)
    {
        CFRelease(item);
    }
    CFRelease(loginItems);
}

@end
