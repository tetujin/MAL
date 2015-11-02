//
//  ViewController.m
//  MAL
//
//  Created by Yuuki Nishiyama on 2015/01/08.
//  Copyright (c) 2015年 tetujin. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

@synthesize loggingEnabled;
@synthesize keyPressCounter;
@synthesize leftMouseCounter;
@synthesize rightMouseCounter;

/** File name of PC's ON/OFF state history */
NSString *logFile;

/** File name of current active application's history */
NSString *activeAppLogFile;

/** File name of keybord action history */
NSString *keybordActionLogFile;

/** File name of mouse action history */
NSString *mouseActionLogFile;

/** Server URL for uploading each hitory */
NSString *serverURL;

/** Local storage key (UUID) */
NSString *uuidKey;

/** Local storage key (User Name) */
NSString *userNameKey;

/** Previous application name */
NSString *pastActiveApp;

/** Previous mouse location */
NSPoint pastMouseLocation;

/** Interval (sec.) of PC's state (Active or Unactive) */
double changeStateInterval;

/** Interval (sec.) for uploading each history */
double sendActionLogInterval;

/** Latest active timestamp（unixtime） */
double lastUpdateTime;

/** current PC's statement（boolean） */
bool userActiveState;

- (void)viewDidLoad {
    [super viewDidLoad];
    /**
     * initialization
     */
    userActiveState = true;
    lastUpdateTime = [self getCurrentUnixtime];
    uuidKey = @"uuid";
    userNameKey = @"username";
    changeStateInterval = 5.0f;
    sendActionLogInterval = 1.0f * 10.0f;
    logFile = @".mal.log";
    activeAppLogFile = @".mal.app.log";
    keybordActionLogFile = @".mal.key.log";
    mouseActionLogFile = @".mal.mouse.log";
    serverURL = @"http://www.hoge.com";
    pastActiveApp = @"";
    pastMouseLocation = [NSEvent mouseLocation];
    [self startMonitoring];
    /** Configuring Periodic upload */
//    [NSTimer scheduledTimerWithTimeInterval:sendActionLogInterval
//                                     target:self
//                                   selector:@selector(postValue)
//                                   userInfo:nil
//                                    repeats:YES];
    /** Configuring periodic user condition detection */
    [NSTimer scheduledTimerWithTimeInterval:5
                                     target:self
                                   selector:@selector(checkUserState)
                                   userInfo:nil
                                    repeats:YES];
    [NSTimer scheduledTimerWithTimeInterval:1
                                     target:self
                                   selector:@selector(checkActiveApplication)
                                   userInfo:nil
                                    repeats:YES];
    [NSTimer scheduledTimerWithTimeInterval:0.1f
                                     target:self
                                   selector:@selector(getMouseLocation)
                                   userInfo:nil
                                    repeats:YES];
    self.keyPressCounter = [NSNumber numberWithInt:0];
    self.leftMouseCounter = [NSNumber numberWithInt:0];
    self.rightMouseCounter = [NSNumber numberWithInt:0];
    NSString *userName = [self getUserName];
    if(userName.length != 0){
        [self.userNameField setStringValue:[self getUserName]];
    }
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}


- (void) checkActiveApplication
{
    NSWorkspace* ws = [NSWorkspace sharedWorkspace];
    NSString *currentActiveApp = [[ws activeApplication] objectForKey:@"NSApplicationName"];
    if (![currentActiveApp isEqualToString:pastActiveApp]) {
        double now = [self getCurrentUnixtime];
        [self saveLogToFile:[NSString stringWithFormat:@"%f,%@\n", now, currentActiveApp]
                 targetFile:activeAppLogFile];
        NSLog(@"%@", currentActiveApp );
        pastActiveApp = currentActiveApp;
    }
}


/**
 * Check user state
 */
- (void) checkUserState
{
    double now = [self getCurrentUnixtime];
    double gap = now - lastUpdateTime;
    if(gap > changeStateInterval){
        if(userActiveState != NO){
            userActiveState = NO;
            [self saveLogToFile:[NSString stringWithFormat:@"%d,off\n",(int)now]
             targetFile:logFile];
            NSLog(@"off");
        }
    }else{
        if(userActiveState != YES){
            userActiveState = YES;
            [self saveLogToFile:[NSString stringWithFormat:@"%d,on\n",(int)now]
                targetFile:logFile];
            NSLog(@"on");
        }
    }
}

/**
 * start monitoring the mouse and key action
 */
- (void) startMonitoring
{
    self.loggingEnabled = true;
    monitorKeyDown = [NSEvent addGlobalMonitorForEventsMatchingMask:NSKeyDownMask handler:^(NSEvent *evt) {
//        [self logMessageToLogView:[NSString stringWithFormat:@"Key down: %@ (key code %d)", [evt characters], [evt keyCode]]];
        self.keyPressCounter = [NSNumber numberWithInt:(1 + [self.keyPressCounter intValue])];
        lastUpdateTime = [self getCurrentUnixtime];
        [self saveLogToFile:[NSString stringWithFormat:@"%d\n", [evt keyCode]] targetFile:keybordActionLogFile];
    }];
    monitorLeftMouseDown = [NSEvent addGlobalMonitorForEventsMatchingMask:NSLeftMouseDownMask handler:^(NSEvent *evt) {
        //[self logMessageToLogView:[NSString stringWithFormat:@"Left mouse down!"]];
        self.leftMouseCounter = [NSNumber numberWithInt:(1 + [self.leftMouseCounter intValue])];
        lastUpdateTime = [self getCurrentUnixtime];
        [self saveLogToFile:[NSString stringWithFormat:@"%f,Left Mouse Down\n", [self getCurrentUnixtime]] targetFile:mouseActionLogFile];
        
    }];
    monitorRightMouseDown = [NSEvent addGlobalMonitorForEventsMatchingMask:NSRightMouseDownMask handler:^(NSEvent *evt) {
        //[self logMessageToLogView:@"Right mouse down!"];
        self.rightMouseCounter = [NSNumber numberWithInt:(1 + [self.rightMouseCounter intValue])];
        lastUpdateTime = [self getCurrentUnixtime];
        [self saveLogToFile:[NSString stringWithFormat:@"%f,Right Mouse Down\n", [self getCurrentUnixtime]] targetFile:mouseActionLogFile];
    }];
}


- (NSPoint) getMouseLocation
{
    NSPoint mouseLocation = [NSEvent mouseLocation];
    if (!NSEqualPoints(pastMouseLocation, mouseLocation)) {
        double now = [self getCurrentUnixtime];
        [self saveLogToFile:[NSString stringWithFormat:@"%f,%d,%d \n", now, (int)mouseLocation.x, (int)mouseLocation.y]
                 targetFile:mouseActionLogFile];
    }
    pastMouseLocation = mouseLocation;
    return mouseLocation;
}



/**
 * ================================
 *  Control methods of log file
 * ================================
 */

/**
 * Save history to the log file
 */
- (void) saveLogToFile:(NSString *)data
            targetFile:(NSString *)filePath
{
    NSFileHandle *fileHandle = [self getFileHandle:filePath];
    NSData *lineData = [NSData dataWithBytes:data.UTF8String
                                      length:[data lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:lineData];
    [fileHandle synchronizeFile];
    [fileHandle closeFile];
    
    [self addDebugMessageField:data];
}

/**
 * Clear log file from
 */
- (void) clearLogFile
{
    NSString *homeDir = NSHomeDirectory();
    NSString *filePath = [homeDir stringByAppendingPathComponent:logFile];
    NSString *line = @"";
    BOOL result;
    NSError *error;
    result = [line writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
}


/**
 * Get logs from log-file
 */
- (NSString *) getLogStr
{
    NSString *homeDir = NSHomeDirectory();
    NSString *filePath = [homeDir stringByAppendingPathComponent:logFile];
    NSError *error=nil;
    NSString *str = [NSString stringWithContentsOfFile:filePath
                                               encoding:NSUTF8StringEncoding
                                                  error:&error];
    return str;
}


/**
 * Handling method for log-files
 */
- (NSFileHandle *) getFileHandle:(NSString *) fileName
{
    // Get a home direcotry's path
    NSString *homeDir = NSHomeDirectory();
    // Generate a file path for a log file
    NSString *filePath = [homeDir stringByAppendingPathComponent:fileName];
    // Generate a file manager
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filePath]) { // yes
        // Generate null file based on the file path
        BOOL result = [fileManager createFileAtPath:filePath
                                           contents:[NSData data] attributes:nil];
        if (!result) {
            NSLog(@"Failed to create the file");
            return nil;
        }
    }
    // Make a file handler
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    if (!fileHandle) {
        NSLog(@"Fails to create the file handle");
        return nil;
    }
    return fileHandle;
}


/**
 * ================================
 *  HTTP request method
 * ================================
 */
- (void)postValue
{
    //Multi-thread HTTP request by using NSOperationQueue
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:^{
        //Set request parameters
        NSString *param = [NSString stringWithFormat:@"username=%@&devicename=%@&timestamp=%f&usage=%@",
                           [self getUserName],
                           [self getUUID],
                           [self getCurrentUnixtime],
                           [self getLogStr]];
        //Generate request
        NSMutableURLRequest *request;
        request = [[NSMutableURLRequest alloc] init];
        [request setHTTPMethod:@"POST"];
        [request setURL:[NSURL URLWithString:serverURL]];
        [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
        [request setTimeoutInterval:8];
        [request setHTTPShouldHandleCookies:FALSE];
        [request setHTTPBody:[param dataUsingEncoding:NSUTF8StringEncoding]];
        NSLog(@"%@", param);
        
        //Send HTTP request
        NSURLResponse *response = nil;
        NSError *error = nil;
        NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
        if (error != nil) {
            NSLog(@"Error!");
            return;
        }else{
            
        }
        
        /**
         * When uploade is success, the following code will clear the log file.
         */
        if ( [res statusCode] == 200 ){
            [self clearLogFile];
            NSLog(@"complate");
            [self addDebugMessageField:@"[complate] posted log to slash's server\n"];
        }else{
            NSLog(@"error");
            [self addDebugMessageField:@"[error] MAL could not post log to slash's server !!!! Please check your internet connection!\n"];
        }
    }];
}


/**
 * ========================================
 * Following methods handle user information
 * ========================================
 */

/**
 *  When "SET" button will be pushed, this method sets a user name
 */
- (IBAction)pushedSetNameButton:(id)sender {
    //userName = [self.userNameField stringValue];
    [self setUserName:[self.userNameField stringValue]];
}

/**
 * Get an User Name
 */
- (NSString *) getUserName
{
    // Do any additional setup after loading the view, typically from a nib.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *userNameStr = [defaults stringForKey:userNameKey];
    return userNameStr;
}

/**
 * Set an User Name
 */
- (void) setUserName:(NSString *) userName
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self.userNameField stringValue] forKey:userNameKey];
}


/**
 * Get UUID
 */
- (NSString *) getUUID
{
    // Do any additional setup after loading the view, typically from a nib.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *uuidStr = [defaults stringForKey:uuidKey];
    
    if ([uuidStr length] == 0) {
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        uuidStr = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid);
        CFRelease(uuid);
        [defaults setObject:uuidStr forKey:uuidKey];
    }
    return uuidStr;
}

/**
 * Get current time (unixtime)
 */
- (double) getCurrentUnixtime
{
    NSDate *now = [[NSDate alloc] init];
    return [now timeIntervalSince1970];
}


/**
 * ====================================
 *  For Debug
 * ====================================
 */

/**
 * Show debug messages on the main window
 */
- (void) addDebugMessageField:(NSString *)message
{
//    NSMutableString *mString = [[NSMutableString alloc] initWithString:[self.logTextField string]];
//    [mString appendString:message];
    [self.logTextField setString:message];
    //[self.logTextField scrollLineDown:nil];
}


/**
 * ====================================
 *  Useful Method
 * ====================================
 */
- (void) getCurrentActiveApplication
{
    NSWorkspace* ws = [NSWorkspace sharedWorkspace];
    NSLog(@"%@", [ws activeApplication]);
}



/**
 * ====================================
 *  For Test
 * ====================================
 */
- (void) getActiveApplicationFromMenubar
{
    NSWorkspace* ws = [NSWorkspace sharedWorkspace];
    NSLog(@"%@", [ws launchedApplications]);
}


- (void) showLog
{
    // own process name
    ProcessSerialNumber ourPSN;
    GetCurrentProcess(&ourPSN);
    
    // Show all current process name
    ProcessSerialNumber nextPSN = {kNoProcess, kNoProcess}; // initialization
    while (GetNextProcess(&nextPSN) == noErr)
    {
        Boolean processIsUs = false;
        SameProcess(&ourPSN, &nextPSN, &processIsUs);
        if (processIsUs)
        {
            // This is own process name
        }
        else
        {
            CFDictionaryRef info;
            info = ProcessInformationCopyDictionary(&nextPSN, kProcessDictionaryIncludeAllInformationMask);
            if (info)
            {
                //                NSLog(@"PSN:%@", CFDictionaryGetValue(info, CFSTR("PSN")));
                //                NSLog(@"Flavor:%@", CFDictionaryGetValue(info, CFSTR("Flavor")));
                //                NSLog(@"Attributes:%@", CFDictionaryGetValue(info, CFSTR("Attributes")));
                //                NSLog(@"ParentPSN:%@", CFDictionaryGetValue(info, CFSTR("ParentPSN")));
                //                NSLog(@"FileType:%@", CFDictionaryGetValue(info, CFSTR("FileType")));
                //                NSLog(@"FileCreator:%@", CFDictionaryGetValue(info, CFSTR("FileCreator")));
                //                NSLog(@"pid:%@", CFDictionaryGetValue(info, CFSTR("pid")));
                //                NSLog(@"LSBackgroundOnly:%@", CFDictionaryGetValue(info, CFSTR("LSBackgroundOnly")));
                //                NSLog(@"LSUIElement:%@", CFDictionaryGetValue(info, CFSTR("LSUIElement")));
                //                NSLog(@"IsHiddenAttr:%@", CFDictionaryGetValue(info, CFSTR("IsHiddenAttr")));
                //                NSLog(@"IsCheckedInAttr:%@", CFDictionaryGetValue(info, CFSTR("IsCheckedInAttr")));
                //                NSLog(@"RequiresCarbon:%@", CFDictionaryGetValue(info, CFSTR("RequiresCarbon")));
                //                NSLog(@"LSUserQuitOnly:%@", CFDictionaryGetValue(info, CFSTR("LSUserQuitOnly")));
                //                NSLog(@"LSUIPresentationMode:%@", CFDictionaryGetValue(info, CFSTR("LSUIPresentationMode")));
                //                NSLog(@"BundlePath:%@", CFDictionaryGetValue(info, CFSTR("BundlePath")));
                //                NSLog(@"kCFBundleExecutableKey:%@", CFDictionaryGetValue(info, kCFBundleExecutableKey));
                //                NSLog(@"kCFBundleNameKey:%@", CFDictionaryGetValue(info, kCFBundleNameKey));
                //                NSLog(@"kCFBundleIdentifierKey:%@", CFDictionaryGetValue(info, kCFBundleIdentifierKey));
                CFRelease(info);
            }
            
            // show process names
            CFStringRef name;
            if (CopyProcessName(&nextPSN, &name) == noErr)
            {
                NSLog(@"name:%@", name);
                CFRelease(name);
            }
        }
    }
}



@end
