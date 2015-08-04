//
//  HeartRateMonitorDevice.m
//  HeartRateMonitor
//
//  Created by Simon Bogutzky on 02.01.14.
//  Copyright (c) 2014 out there! communication. All rights reserved.
//

#import "HeartRateMonitorDevice.h"
#import "HeartRateMonitorDeviceDelegate.h"
#import "HeartRateMonitorData.h"

#define HeartRateValueFormatFlag    0x01
#define SensorContactStatusFlag     0x06
#define EnergyExpendedStatusFlag    0x08
#define RRIntervalFlag              0x10

@interface HeartRateMonitorDevice ()

@property (nonatomic, strong) CBCharacteristic *characteristic;
@property (nonatomic, assign) NSTimeInterval timestamp;
@property (nonatomic, assign) BOOL first;

@end

@implementation HeartRateMonitorDevice

- (id)initWithPeripheral:(CBPeripheral *)peripheral
{
    self = [super init];
    if (self) {
        _peripheral = peripheral;
    }
    return self;
}

- (NSString *)name
{
    if (self.peripheral.name == nil) {
        return [self.peripheral.identifier UUIDString];
    }
    return self.peripheral.name;
}

- (void)prepareForMonitoring
{
    if (self.peripheral) {
        self.peripheral.delegate = self;
        [self.peripheral discoverServices:nil];
    }
}

- (void)startMonitoring
{
    if (self.state == HeartRateMonitorDeviceStatePrepared) {
        self.first = YES;
        self.monitorStartDate = [NSDate date];
        self.timestamp = 0.0;
        self.state = HeartRateMonitorDeviceStateMonitoring;
        [self.peripheral setNotifyValue:YES forCharacteristic:self.characteristic];
    }
}

- (void)stopMonitoring
{
    if (self.state == HeartRateMonitorDeviceStateMonitoring) {
        [self.peripheral setNotifyValue:NO forCharacteristic:self.characteristic];
    }
    self.state = HeartRateMonitorDeviceStatePrepared;
}

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverServices:(NSError *)error {
    for (CBService *service in peripheral.services) {
        NSLog(@"### Discovered services %@", service.UUID);
        if ([service.UUID.description isEqualToString:@"BEFDFF20-C979-11E1-9B21-0800200C9A66"]) {
            CBUUID *heartRateCharacteristicUUID = [CBUUID UUIDWithString:@"BEFDFF60-C979-11E1-9B21-0800200C9A66"];
            [peripheral discoverCharacteristics:@[heartRateCharacteristicUUID] forService:service];
        }
    }
    
    if (error) {
        // NSLog(@"### Error: %@", [error localizedDescription]);
        self.state = HeartRateMonitorDeviceStateResetting;
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error {
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSLog(@"### Characteristic: %@", characteristic.UUID);
        self.characteristic = characteristic;
        self.state = HeartRateMonitorDeviceStatePrepared;
    }
    
    if (error) {
        // NSLog(@"### Error: %@", [error localizedDescription]);
        self.state = HeartRateMonitorDeviceStateResetting;
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        // NSLog(@"### Error: %@", [error localizedDescription]);
        self.state = HeartRateMonitorDeviceStateResetting;
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (!error) {
        
        NSLog(@"CBCharacteristic", characteristic);
        
        if (self.first) {
            self.timestamp = fabs([self.monitorStartDate timeIntervalSinceNow]);
            self.first = NO;
        }
        
        NSData *data = characteristic.value;
        NSUInteger dataSize = data.length;
        NSLog(@"### Size: %lu", dataSize);
        
        int p = [self getRespirationRate:[data bytes]];
        NSLog(@"### Respiration Rate: %d", p);
        
        if ([_delegate respondsToSelector:@selector(heartRateMonitorDevice:didreceiveHeartrateMonitorData:)]) {
            [_delegate heartRateMonitorDevice:self didreceiveHeartrateMonitorData:nil];
        }
    }
}

- (double)getRespirationRate:(const uint8_t *)payload
{
//    for (int i = 0; i < 23; i++) {
//        short posture = (short)(payload[i]);
//        NSLog(@"%d %d", i, posture);
//    }
//    // 3 ist Heartrate
        // 4 ist Respiration Rate 2 Bytes
        // 6 ist Skintemperatur
    int i = self.testByte;
    NSLog(@"### Tested Byte %d", self.testByte);
    short respRate1x = (short)(payload[i + 1] << 8);
    short respRate11 = (short)(payload[i]);
    double respirationRate = (double)(respRate1x | respRate11) / 10.0;
    
    return respRate11;
}

@end
