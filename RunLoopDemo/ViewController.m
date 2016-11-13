//
//  ViewController.m
//  RunLoopDemo
//
//  Created by wjc on 16/11/13.
//  Copyright © 2016年 CityFire. All rights reserved.
//

#import "ViewController.h"
#import "CFMonitorHelper.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [[CFMonitorHelper sharedInstance] beginMonitor];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        for (int i = 0; i < 100; i++) {
            sleep(0.2);
//            NSLog(@"i:%@", @(i));
        }
    });
    
    [self threadMain];
}

- (void)threadMain {
    // The application uses garbage collection, so no autorelease pool is needed.
    NSRunLoop *myRunLoop = [NSRunLoop currentRunLoop];
    
    // Create a run loop observer and attach it to the run loop.
    CFRunLoopObserverContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
    CFRunLoopObserverRef    observer = CFRunLoopObserverCreate(kCFAllocatorDefault,
                                                               kCFRunLoopAllActivities, YES, 0, &myRunLoopObserver, &context);
    
    if (observer)
    {
        CFRunLoopRef cfLoop = [myRunLoop getCFRunLoop];
        CFRunLoopAddObserver(cfLoop, observer, kCFRunLoopDefaultMode);
    }
    
    // Create and schedule the timer.
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self
                                                    selector:@selector(doFireTimer:) userInfo:nil repeats:YES];
    NSInteger loopCount = 10;
    do {
        // Run the run loop 1 times to let the timer fire.
        [myRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]]; // 设置超时时间
        loopCount--;
        NSLog(@"=========================================loop:%@", @(loopCount));
    } while (loopCount);
    
    if (loopCount <= 0) {
        [timer invalidate];
        timer = nil;
    }
}

#pragma mark - Actions

- (void)doFireTimer:(NSTimer *)timer {
    NSLog(@"doFireTimer");
}

#pragma mark - CallBack Method

void myRunLoopObserver(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info)
{
    NSLog(@"Current thread Run Loop activity: %@, currentThread:%@", printActivity(activity), [NSThread currentThread]);
}

static inline NSString* printActivity(CFRunLoopActivity activity)
{
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


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
