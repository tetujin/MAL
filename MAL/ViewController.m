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

/** 操作ログを保存するファイル名*/
NSString *logFile;

/** 操作ログの送信先URL*/
NSString *serverURL;

/** ローカルストレージのキー（UUID） */
NSString *uuidKey;

/** ローカルストレージのキー（ユーザ名）*/
NSString *userNameKey;

/** 操作中から操作中止（またはその逆）のインターバル（秒）*/
double changeStateInterval;

/** 操作ログを送信する間隔（秒） */
double sendActionLogInterval;

/** 最新の操作時刻（unixtime） */
double lastUpdateTime;

/** 現在のユーザの操作状態（boolean） */
bool userActiveState;

/** ユーザの状態をこ */

- (void)viewDidLoad {
    [super viewDidLoad];
    /**
     * ここは初期化処理
     */
    userActiveState = true;
    lastUpdateTime = [self getCurrentUnixtime];
    uuidKey = @"uuid";
    userNameKey = @"username";
    changeStateInterval = 5.0f;
    sendActionLogInterval = 1.0f * 10.0f;
    logFile = @".mal.log";
    serverURL = @"http://epiwork.hcii.cs.cmu.edu/~tokoshi/Attelia/server201501/index.cgi/upload_usage_data/";
    [self startMonitoring];
    /** 定期的にログを送信する設定 */
    [NSTimer scheduledTimerWithTimeInterval:sendActionLogInterval
                                     target:self
                                   selector:@selector(postValue)
                                   userInfo:nil
                                    repeats:YES];
    /** 定期的にユーザの使用状態を調査する設定 */
    [NSTimer scheduledTimerWithTimeInterval:0.1f
                                     target:self
                                   selector:@selector(checkUserState)
                                   userInfo:nil
                                    repeats:YES];
    self.keyPressCounter = [NSNumber numberWithInt:0];
    self.leftMouseCounter = [NSNumber numberWithInt:0];
    self.rightMouseCounter = [NSNumber numberWithInt:0];
    NSString *userName = [self getUserName];
    if(userName.length != 0){
        [self.userNameField setStringValue:[self getUserName]];
    }
    [self showLog];
    [self getCurrentActiveApplication];
    //[self getActiveApplicationFromMenubar];
}

- (void) getCurrentActiveApplication
{
    NSWorkspace* ws = [NSWorkspace sharedWorkspace];
    NSLog(@"%@", [ws activeApplication]);
}


- (void) getActiveApplicationFromMenubar
{
    NSWorkspace* ws = [NSWorkspace sharedWorkspace];
    NSLog(@"%@", [ws launchedApplications]);
}


- (void) showLog
{
    // 自分自身のプロセス
    ProcessSerialNumber ourPSN;
    GetCurrentProcess(&ourPSN);
    
    // 起動中のプロセスを一覧
    ProcessSerialNumber nextPSN = {kNoProcess, kNoProcess}; // 初期化
    while (GetNextProcess(&nextPSN) == noErr)
    {
        Boolean processIsUs = false;
        SameProcess(&ourPSN, &nextPSN, &processIsUs);
        if (processIsUs)
        {
            // 自分自身のプロセス
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
            
            // ローカライズされたプロセス名が取得できる
            CFStringRef name;
            if (CopyProcessName(&nextPSN, &name) == noErr)
            {
                NSLog(@"name:%@", name);
                CFRelease(name);
            }
        }
    }
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    // Update the view, if already loaded.
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}


/**
 * 値をHTTP/POSTを用いて送信するメソッド
 */
- (void)postValue
{
    //NSOperationQueueを使ってマルチスレッドでリクエスト
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:^{
        //////////////////////////////////////
        //リクエスト用のパラメータを設定
        NSString *param = [NSString stringWithFormat:@"username=%@&devicename=%@&timestamp=%f&usage=%@",
                                                        [self getUserName],
                                                        [self getUUID],
                                                        [self getCurrentUnixtime],
                                                        [self getLogStr]];
        //リクエストを生成
        NSMutableURLRequest *request;
        request = [[NSMutableURLRequest alloc] init];
        [request setHTTPMethod:@"POST"];
        [request setURL:[NSURL URLWithString:serverURL]];
        [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
        [request setTimeoutInterval:8];
        [request setHTTPShouldHandleCookies:FALSE];
        [request setHTTPBody:[param dataUsingEncoding:NSUTF8StringEncoding]];
        NSLog(@"%@", param);
        
        //同期通信で送信
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
         * 送信が成功した場合は、ログファイルをクリアする
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
 * ユーザの操作状態をチェックするメソッド
 */
- (void) checkUserState
{
    double now = [self getCurrentUnixtime];
    double gap = now - lastUpdateTime;
    if(gap > changeStateInterval){
        if(userActiveState != NO){
            userActiveState = NO;
            [self saveLogToFile:[NSString stringWithFormat:@"%d,off\n",(int)now]];
            NSLog(@"off");
        }
    }else{
        if(userActiveState != YES){
            userActiveState = YES;
            [self saveLogToFile:[NSString stringWithFormat:@"%d,on\n",(int)now]];
            NSLog(@"on");
        }
    }
}




/**
 * キーとマウスのモニタリングを開始するメソッド
 */
- (void) startMonitoring
{
    self.loggingEnabled = true;
    monitorKeyDown = [NSEvent addGlobalMonitorForEventsMatchingMask:NSKeyDownMask handler:^(NSEvent *evt) {
//        [self logMessageToLogView:[NSString stringWithFormat:@"Key down: %@ (key code %d)", [evt characters], [evt keyCode]]];
        self.keyPressCounter = [NSNumber numberWithInt:(1 + [self.keyPressCounter intValue])];
        //[self saveLogToFile:[NSString stringWithFormat:@"%d", [evt keyCode]]];
        lastUpdateTime = [self getCurrentUnixtime];
    }];
    monitorLeftMouseDown = [NSEvent addGlobalMonitorForEventsMatchingMask:NSLeftMouseDownMask handler:^(NSEvent *evt) {
        //[self logMessageToLogView:[NSString stringWithFormat:@"Left mouse down!"]];
        self.leftMouseCounter = [NSNumber numberWithInt:(1 + [self.leftMouseCounter intValue])];
        lastUpdateTime = [self getCurrentUnixtime];
    }];
    monitorRightMouseDown = [NSEvent addGlobalMonitorForEventsMatchingMask:NSRightMouseDownMask handler:^(NSEvent *evt) {
        //[self logMessageToLogView:@"Right mouse down!"];
        self.rightMouseCounter = [NSNumber numberWithInt:(1 + [self.rightMouseCounter intValue])];
        lastUpdateTime = [self getCurrentUnixtime];
    }];
}


/**
 * ログファイルにメッセージを保存するメソッド
 */
- (void) saveLogToFile:(NSString *)data
{
    NSFileHandle *fileHandle = [self getFileHandle:logFile];
    // ファイルに書き込むデータ1を作成
    NSString *line = [NSString stringWithFormat:@"%@", data];
    NSData *lineData = [NSData dataWithBytes:line.UTF8String
                                   length:line.length];
    // ファイルに書き込む
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:lineData];
    [fileHandle synchronizeFile];
    [fileHandle closeFile];
    
    //[self.logTextField setString:data];
    [self addDebugMessageField:data];
}

/**
 * ログファイルの中身をクリアするメソッド
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
 * ログファイルの中身を取得するメソッド
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
 * ログファイルのハンドラを取得するメソッド
 */
- (NSFileHandle *) getFileHandle:(NSString *) fileName
{
    // ホームディレクトリを取得
    NSString *homeDir = NSHomeDirectory();
    // 書き込みたいファイルのパスを作成
    NSString *filePath = [homeDir stringByAppendingPathComponent:fileName];
    // ファイルマネージャを作成
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filePath]) { // yes
        // 空のファイルを作成する
        BOOL result = [fileManager createFileAtPath:filePath
                                           contents:[NSData data] attributes:nil];
        if (!result) {
            NSLog(@"ファイルの作成に失敗");
            return nil;
        }
    }
    // ファイルハンドルを作成する
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    if (!fileHandle) {
        NSLog(@"ファイルハンドルの作成に失敗");
        return nil;
    }
    return fileHandle;
}


/**
 * 「set」ボタンが押された場合に、ユーザ名を設定するメソッド
 */
- (IBAction)pushedSetNameButton:(id)sender {
    //userName = [self.userNameField stringValue];
    [self setUserName:[self.userNameField stringValue]];
}

/**
 * ユーザ名の取得
 */
- (NSString *) getUserName
{
    // Do any additional setup after loading the view, typically from a nib.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *userNameStr = [defaults stringForKey:userNameKey];
    return userNameStr;
}

/**
 * ユーザ名の設定
 */
- (void) setUserName:(NSString *) userName
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self.userNameField stringValue] forKey:userNameKey];
}


/**
 * UUIDの取得
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
 * 現在時刻（unixtime）の取得
 */
- (double) getCurrentUnixtime
{
    NSDate *now = [[NSDate alloc] init];
    return [now timeIntervalSince1970];
}

/**
 * ウィンドウでのデバッグメッセージの表示
 */
- (void) addDebugMessageField:(NSString *)message
{
//    NSMutableString *mString = [[NSMutableString alloc] initWithString:[self.logTextField string]];
//    [mString appendString:message];
    [self.logTextField setString:message];
    //[self.logTextField scrollLineDown:nil];
}

//-(void)logMessageToLogView:(NSString*)message {
//    [logView setString: [ [logView string] stringByAppendingFormat:@"%@: %@\n", [self.logDateFormatter stringFromDate:[NSDate date]],  message]];
//}

@end
