//
//  HeartRateMonitorDevice.h
//  HeartRateMonitor
//
//  Created by Simon Bogutzky on 02.01.14.
//  Copyright (c) 2014 out there! communication. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>

@protocol HeartRateMonitorDeviceDelegate;

typedef NS_ENUM(NSInteger, HeartRateMonitorDeviceState) {
	HeartRateMonitorDeviceStateUnknown = 0,
	HeartRateMonitorDeviceStateResetting,
	HeartRateMonitorDeviceStatePrepared,
	HeartRateMonitorDeviceStateMonitoring
};

@interface HeartRateMonitorDevice : NSObject <CBPeripheralDelegate>

@property (nonatomic, weak) id<HeartRateMonitorDeviceDelegate> delegate;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) CBPeripheral *peripheral;
@property (nonatomic) HeartRateMonitorDeviceState state;
@property (nonatomic, readonly) BOOL heartRateIs16Bit;
@property (nonatomic, readonly) BOOL energyExpendedFieldIsPresent;
@property (nonatomic, readonly) BOOL sensorContactIsPresent;
@property (nonatomic, readonly) BOOL rrIntervalsArePresent;

- (id)initWithPeripheral:(CBPeripheral *)peripheral;
- (void)prepareForMonitoring;
- (void)startMonitoring;
- (void)stopMonitoring;

@end
