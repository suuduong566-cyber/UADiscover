// UADiscover - v0 (chi do tim, khong sua gi trong Safari)
// 8 giay sau khi Safari mo, ghi danh sach cac method co chu "UserAgent"
// va cac class WebView vao file log de biet nen hook cai nao tren iOS 8.4.1.

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <stdlib.h>
#import <string.h>

#define LOG_PATH_1 @"/var/mobile/Library/Safari/uad_log.txt"
#define LOG_PATH_2 @"/var/mobile/Library/Caches/com.apple.mobilesafari/uad_log.txt"

static void scanMethods(Class cls, BOOL isMeta, NSMutableString *out) {
    unsigned int count = 0;
    Class target = isMeta ? object_getClass(cls) : cls;
    Method *methods = class_copyMethodList(target, &count);
    if (!methods) return;
    for (unsigned int i = 0; i < count; i++) {
        NSString *sel = NSStringFromSelector(method_getName(methods[i]));
        if ([sel rangeOfString:@"useragent" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [out appendFormat:@"%@[%s %@]\n", isMeta ? @"+" : @"-", class_getName(cls), sel];
        }
    }
    free(methods);
}

static void runScan(void) {
    @autoreleasepool {
        NSMutableString *out = [NSMutableString string];
        [out appendFormat:@"iOS: %@\n", [[NSProcessInfo processInfo] operatingSystemVersionString]];
        [out appendFormat:@"process: %@\n", [[NSProcessInfo processInfo] processName]];

        int total = objc_getClassList(NULL, 0);
        Class *classes = (Class *)malloc(sizeof(Class) * total);
        total = objc_getClassList(classes, total);
        [out appendFormat:@"classes: %d\n", total];

        [out appendString:@"--- methods with 'UserAgent' ---\n"];
        for (int i = 0; i < total; i++) {
            scanMethods(classes[i], NO, out);
            scanMethods(classes[i], YES, out);
        }

        [out appendString:@"--- classes with 'WebView' or 'WKWeb' in name ---\n"];
        for (int i = 0; i < total; i++) {
            const char *n = class_getName(classes[i]);
            if (n && (strstr(n, "WebView") || strstr(n, "WKWeb"))) {
                [out appendFormat:@"%s\n", n];
            }
        }
        free(classes);

        NSString *ua = [[NSUserDefaults standardUserDefaults] stringForKey:@"UserAgent"];
        [out appendFormat:@"NSUserDefaults UserAgent = %@\n", ua ? ua : @"(none)"];

        [out writeToFile:LOG_PATH_1 atomically:YES encoding:NSUTF8StringEncoding error:NULL];
        [out writeToFile:LOG_PATH_2 atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    }
}

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 8 * NSEC_PER_SEC),
                   dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^{ runScan(); });
}
