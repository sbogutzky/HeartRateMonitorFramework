//

//  HeartRateMonitorManager.h
//  HeartRateMonitor
//
//  Created by Simon Bogutzky on 28.12.13.
//  Copyright (c) 2013 bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "HeartRateMonitorDevice.h"
#import "HeartRateMonitorDeviceDelegate.h"

@protocol HeartRateMonitorManagerDelegate;

typedef NS_ENUM(NSInteger, HeartRateMonitorManagerState) {
	HeartRateMonitorManagerStateUnknown = 0,
	HeartRateMonitorManagerStateResetting,
	HeartRateMonitorManagerStateUnsupported,
	HeartRateMonitorManagerStateUnauthorized,
	HeartRateMonitorManagerStatePoweredOff,
	HeartRateMonitorManagerStatePoweredOn,
};

@interface HeartRateMonitorManager : NSObject <CBCentralManagerDelegate, HeartRateMonitorDeviceDelegate>

@property (nonatomic, weak) id<HeartRateMonitorManagerDelegate> delegate;
@property (nonatomic) HeartRateMonitorManagerState state;
@property (nonatomic, readonly) BOOL hasConnection;
@property (nonatomic) HeartRateMonitorDeviceState deviceState;

- (void)scanForHeartRateMonitorDeviceWhichWereConnected:(BOOL)wereConnected;
- (void)stopScanning;
- (void)connectHeartRateMonitorDevice:(HeartRateMonitorDevice *)heartRateMonitorDevice;
- (void)disconnectHeartRateMonitorDevice;
- (void)startMonitoring;
- (void)stopMonitoring;

@end
