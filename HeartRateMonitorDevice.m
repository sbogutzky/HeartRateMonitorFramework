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
        CBUUID *heartRateServiceUUID = [CBUUID UUIDWithString:@"180D"];
        [self.peripheral discoverServices:@[heartRateServiceUUID]];
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
        CBUUID *heartRateCharacteristicUUID = [CBUUID UUIDWithString:@"2A37"];
        [peripheral discoverCharacteristics:@[heartRateCharacteristicUUID] forService:service];
    }
    
    if (error) {
        NSLog(@"### Error: %@", [error localizedDescription]);
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
        NSLog(@"### Error: %@", [error localizedDescription]);
        self.state = HeartRateMonitorDeviceStateResetting;
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"### Error: %@", [error localizedDescription]);
        self.state = HeartRateMonitorDeviceStateResetting;
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (!error) {
        
        if (self.first) {
            self.timestamp = abs([self.monitorStartDate timeIntervalSinceNow]);
            self.first = NO;
        }
        
        int offset = 0;
        NSData *data = characteristic.value;
        const uint8_t *reportData = [data bytes];
        uint8_t flagByte = reportData[offset];
        offset++;
        
        // Heart Rate Value
        if ((flagByte & HeartRateValueFormatFlag) == 0) {
            NSLog(@"### Heart Rate Value Format is set to UINT8. Units: beats per minute (bpm)");
            _heartRateIs16Bit = NO;
            offset++;
        } else {
            NSLog(@"### Heart Rate Value Format is set to UINT16. Units: beats per minute (bpm)");
            _heartRateIs16Bit = YES;
            offset +=2;
        }
        
        // Sensor Contact Status
        _sensorContactIsPresent = NO;
        switch ((flagByte & SensorContactStatusFlag)) {
            case 0:
                NSLog(@"### Sensor Contact feature is not supported in the current connection");
                break;
            
            case 2:
                NSLog(@"### Sensor Contact feature is not supported in the current connection");
                break;
            
            case 4 :
                NSLog(@"### Sensor Contact feature is supported, but contact is not detected");
                break;
            
            case 6:
                NSLog(@"### Sensor Contact feature is supported and contact is detected");
                _sensorContactIsPresent = YES;
                break;
                
            default:
                break;
        }
        
        // Energy Expended Status
        if ((flagByte & EnergyExpendedStatusFlag) == 0) {
            NSLog(@"### Energy Expended field is not present");
            _energyExpendedFieldIsPresent = NO;
        } else {
            NSLog(@"### Energy Expended field is present. Units: kilo Joules");
            _energyExpendedFieldIsPresent = YES;
            offset += 2;
        }
        
        // One or more RR-Interval values are present. Units: 1/1024 seconds
        if ((flagByte & RRIntervalFlag) == 0) {
            NSLog(@"### RR-Interval values are not present.");
            _rrIntervalsArePresent = NO;
        } else {
            NSLog(@"### One or more RR-Interval values are present. Units: 1/1024 seconds");
            _rrIntervalsArePresent = YES;
        }
        
        int heartRate = -1;
        if (_heartRateIs16Bit) {
            uint8_t heartRateByte1 = reportData[1];
            uint8_t heartRateByte2 = reportData[2];
            heartRate = heartRateByte2 << 8 | heartRateByte1;
            NSLog(@"### Heart rate: %d", heartRate);
        } else {
            heartRate = reportData[1];
            NSLog(@"### Heart rate: %d", heartRate);
        }
        
        HeartRateMonitorData *heartRateMonitorData = [[HeartRateMonitorData alloc] init];
        heartRateMonitorData.heartRate = heartRate;
        
        if (_rrIntervalsArePresent) {
            int count = (sizeof(reportData) - offset) / 2;
            NSLog(@"### RR-Count: %d", count);
            
            NSMutableArray *rrT = [NSMutableArray arrayWithCapacity:count];
            NSMutableArray *rrI = [NSMutableArray arrayWithCapacity:count];

            for (int i = count - 1; i >= 0; i--)
            {
                uint8_t rrIntervalByte1 = reportData[offset];
                uint8_t rrIntervalByte2 = reportData[offset + 1];
                int rrInterval = rrIntervalByte2 << 8 | rrIntervalByte1;
                NSLog(@"### RR-Interval %d: %d", i, rrInterval);
                double rrIntervalS = rrInterval / 1024.0;
                double rrTime = self.timestamp;
                self.timestamp = self.timestamp + rrIntervalS;
                [rrT addObject:[NSNumber numberWithDouble:rrTime]];
                [rrI addObject:[NSNumber numberWithDouble:rrIntervalS]];
                
                offset += 2;
            }
            heartRateMonitorData.rrTimes = [[NSArray alloc] initWithArray:rrT];
            heartRateMonitorData.rrIntervals = [[NSArray alloc] initWithArray:rrI];
        }
        NSLog(@"### ---< %@ >---", heartRateMonitorData);
        
        if ([_delegate respondsToSelector:@selector(heartRateMonitorDevice:didreceiveHeartrateMonitorData:)]) {
            [_delegate heartRateMonitorDevice:self didreceiveHeartrateMonitorData:heartRateMonitorData];
        }
    }
}

@end
