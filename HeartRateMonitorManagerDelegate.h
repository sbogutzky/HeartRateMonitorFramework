//
//  HeartRateMonitorManagerDelegate.h
//  HeartRateMonitor
//
//  Created by Simon Bogutzky on 02.01.14.
//  Copyright (c) 2014 out there! communication. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HeartRateMonitorManager;
@class HeartRateMonitorDevice;
@class HeartRateMonitorData;

@protocol HeartRateMonitorManagerDelegate<NSObject>

@optional

- (void)heartRateMonitorManager:(HeartRateMonitorManager *)manager didDiscoverHeartrateMonitorDevices:(NSArray *)heartRateMonitorDevices;
- (void)heartRateMonitorManager:(HeartRateMonitorManager *)manager didConnectHeartrateMonitorDevice:(HeartRateMonitorDevice *)heartRateMonitorDevice;
- (void)heartRateMonitorManager:(HeartRateMonitorManager *)manager didDisconnectHeartrateMonitorDevice:(HeartRateMonitorDevice *)heartRateMonitorDevice error:(NSError *)error;
- (void)heartRateMonitorManager:(HeartRateMonitorManager *)manager didFailToConnectHeartrateMonitorDevice:(HeartRateMonitorDevice *)heartRateMonitorDevice error:(NSError *)error;
- (void)heartRateMonitorManager:(HeartRateMonitorManager *)manager didFailToMonitorHeartrateMonitorDevice:(HeartRateMonitorDevice *)heartRateMonitorDevice error:(NSError *)error;
- (void)heartRateMonitorManager:(HeartRateMonitorManager *)manager didReceiveHeartrateMonitorData:(HeartRateMonitorData *)data fromHeartRateMonitorDevice:(HeartRateMonitorDevice *)device;
@end
