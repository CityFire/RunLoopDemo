//
//  CFMonitorHelper.h
//  RunLoopDemo
//
//  Created by wjc on 15/10/13.
//  Copyright © 2015年 CityFire. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CFMonitorHelper : NSObject

+ (instancetype)sharedInstance;

// 开始监视卡顿
- (void)beginMonitor;
// 停止监视卡顿
- (void)endMonitor;

@end
