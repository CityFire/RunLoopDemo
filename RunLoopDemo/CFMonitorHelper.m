//
//  CFMonitorHelper.m
//  RunLoopDemo
//
//  Created by wjc on 15/10/13.
//  Copyright © 2015年 CityFire. All rights reserved.
//  参考多线程编程指南和blog

#import "CFMonitorHelper.h"
#import <CrashReporter/CrashReporter.h>

@interface CFMonitorHelper () {
    // runloop观察者
    CFRunLoopObserverRef runLoopObserver;
    // runloop活动
    CFRunLoopActivity runLoopActivity;
    // 信号量
    dispatch_semaphore_t signalSemaphore;
    // 卡顿循环次数
    NSInteger timeoutCount;
}

@end

@implementation CFMonitorHelper

+ (instancetype)sharedInstance {
    static CFMonitorHelper *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[CFMonitorHelper alloc] init];
    });
    return _instance;
}

// 开始监控
- (void)beginMonitor {
    if (runLoopObserver) {
        return;
    }
    
    signalSemaphore = dispatch_semaphore_create(0); // 创建同步信号量，保证线程同步
    // 创建一个runloop观察者并附属到runloop上
    CFRunLoopObserverContext context = {0, (__bridge void *)self, NULL, NULL, NULL};
    CFRunLoopObserverRef observer = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, &myRunLoopObserverCallBack, &context);
    if (observer) {
        // 将观察者添加到主线程runloop的Common模式下进行观察
        CFRunLoopAddObserver(CFRunLoopGetMain(), observer, kCFRunLoopCommonModes);
    }
    runLoopObserver = observer;
    
    // 创建子线程监控
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 子线程开启一个持续的loop进行监控
        while (YES) {
            // 等待信号量
            long semaphoreWait = dispatch_semaphore_wait(signalSemaphore, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_MSEC)); // <= 0 阻塞当前线程 >= 0 唤醒线程到就绪队列
            if (semaphoreWait != 0) {
                if (!runLoopObserver) {
                    timeoutCount = 0;
                    signalSemaphore = 0;
                    runLoopActivity = 0;
                    return;
                }
                // 在BeforeSources和AfterWaiting这两个状态时间段检测卡顿
                if (runLoopActivity == kCFRunLoopBeforeSources || runLoopActivity == kCFRunLoopAfterWaiting) {
                    if (++timeoutCount < 3) {
                        continue;
                    }
                    
                    // 生成实时崩溃日志上报二进制文件
                    NSData *logData = [[[PLCrashReporter alloc] initWithConfiguration:[[PLCrashReporterConfig alloc] initWithSignalHandlerType:PLCrashReporterSignalHandlerTypeBSD symbolicationStrategy:PLCrashReporterSymbolicationStrategyAll]] generateLiveReport];
                    PLCrashReport *logReport = [[PLCrashReport alloc] initWithData:logData error:NULL];
                    NSString *logReportString = [PLCrashReportTextFormatter stringValueForCrashReport:logReport withTextFormat:PLCrashReportTextFormatiOS];
                    // 上传服务器
                    NSLog(@"logReportString: %@", logReportString);
                }
            }
            timeoutCount = 0;
        }
    });
    
}

// 结束监控
- (void)endMonitor {
    if (!runLoopObserver) {
        return;
    }
    CFRunLoopRemoveObserver(CFRunLoopGetMain(), runLoopObserver, kCFRunLoopCommonModes);
    CFRelease(runLoopObserver);
    runLoopObserver = NULL;
}

#pragma mark - Private Method 

static void myRunLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity,void *info) {
    NSLog(@"Current thread RunLoop activity: %@", printActivity(activity));
    
    CFMonitorHelper *logMonitor = (__bridge CFMonitorHelper *)(info);
    logMonitor->runLoopActivity = activity;
    
    dispatch_semaphore_t semphore = logMonitor->signalSemaphore;
    // 发送信号量
    dispatch_semaphore_signal(semphore);
}

static inline NSString *printActivity(CFRunLoopActivity activity) {
    NSString *activityDescription;
    switch (activity) {
        case kCFRunLoopEntry:
            activityDescription = @"kCFRunLoopEntry";
            break;
        case kCFRunLoopBeforeTimers:
            activityDescription = @"kCFRunLoopBeforeTimers";
            break;
        case kCFRunLoopBeforeSources:
            activityDescription = @"kCFRunLoopBeforeSources";
            break;
        case kCFRunLoopBeforeWaiting:
            activityDescription = @"kCFRunLoopBeforeWaiting";
            break;
        case kCFRunLoopAfterWaiting:
            activityDescription = @"kCFRunLoopAfterWaiting";
            break;
        case kCFRunLoopExit:
            activityDescription = @"kCFRunLoopExit";
            break;
        default:
            break;
    }
    return activityDescription;
}

@end
