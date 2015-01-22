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
        
        NSData *data = characteristic.value;
        const uint8_t *reportData = [data bytes];
        uint8_t flagByte = reportData[0];
        
        // Heart Rate Value
        if ((flagByte & HeartRateValueFormatFlag) == 0) {
            NSLog(@"### Heart Rate Value Format is set to UINT8. Units: beats per minute (bpm)");
            _heartRateIs16Bit = NO;
        } else {
            NSLog(@"### Heart Rate Value Format is set to UINT16. Units: beats per minute (bpm)");
            _heartRateIs16Bit = YES;
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
            uint8_t firstRRInterval = 2;
            if (_heartRateIs16Bit) {
                firstRRInterval++;
            }
        
            if (_energyExpendedFieldIsPresent) {
                firstRRInterval++;
                firstRRInterval++;
            }
        
            NSLog(@"### First RR-Interval Byte: %d", firstRRInterval);
            
            uint8_t rrIntervalByte1 = reportData[firstRRInterval];
            uint8_t rrIntervalByte2 = reportData[firstRRInterval + 1];
            int rrInterval1 = rrIntervalByte2 << 8 | rrIntervalByte1;
            NSLog(@"### RR-Interval 1: %d", rrInterval1);
            
            
            uint8_t rrIntervalByte3 = reportData[firstRRInterval + 2];
            uint8_t rrIntervalByte4 = reportData[firstRRInterval + 3];
            int rrInterval2 = rrIntervalByte4 << 8 | rrIntervalByte3;
            NSLog(@"### RR-Interval 2: %d", rrInterval2);
            
            uint8_t rrIntervalByte5 = reportData[firstRRInterval + 4];
            uint8_t rrIntervalByte6 = reportData[firstRRInterval + 5];
            int rrInterval3 = rrIntervalByte6 << 8 | rrIntervalByte5;
            NSLog(@"### RR-Interval 3: %d", rrInterval3);
            
            uint8_t rrIntervalByte7 = reportData[firstRRInterval + 6];
            uint8_t rrIntervalByte8 = reportData[firstRRInterval + 7];
            int rrInterval4 = rrIntervalByte8 << 8 | rrIntervalByte7;
            NSLog(@"### RR-Interval 4: %d", rrInterval4);
            
            uint8_t rrIntervalByte9 = reportData[firstRRInterval + 8];
            uint8_t rrIntervalByte10 = reportData[firstRRInterval + 9];
            int rrInterval5 = rrIntervalByte10 << 8 | rrIntervalByte9;
            NSLog(@"### RR-Interval 5: %d", rrInterval5);
            
            
            NSMutableArray *rrT = [NSMutableArray arrayWithCapacity:5];
            NSMutableArray *rrI = [NSMutableArray arrayWithCapacity:5];
            if (rrInterval1 > 0) {
                double rrInterval = rrInterval1 / 1024.0;
                double rrTime = self.timestamp;
                self.timestamp = self.timestamp + rrInterval;
                [rrT addObject:[NSNumber numberWithDouble:rrTime]];
                [rrI addObject:[NSNumber numberWithDouble:rrInterval]];
            }
            
            if (rrInterval2 > 0) {
                double rrInterval = rrInterval2 / 1024.0;
                double rrTime = self.timestamp;
                self.timestamp = self.timestamp + rrInterval;
                [rrT addObject:[NSNumber numberWithDouble:rrTime]];
                [rrI addObject:[NSNumber numberWithDouble:rrInterval]];
            }
            
            if (rrInterval3 > 0) {
                double rrInterval = rrInterval3 / 1024.0;
                double rrTime = self.timestamp;
                self.timestamp = self.timestamp + rrInterval;
                [rrT addObject:[NSNumber numberWithDouble:rrTime]];
                [rrI addObject:[NSNumber numberWithDouble:rrInterval]];
            }
            
            if (rrInterval4 > 0) {
                double rrInterval = rrInterval4 / 1024.0;
                double rrTime = self.timestamp;
                self.timestamp = self.timestamp + rrInterval;
                [rrT addObject:[NSNumber numberWithDouble:rrTime]];
                [rrI addObject:[NSNumber numberWithDouble:rrInterval]];
            }
            
            if (rrInterval5 > 0) {
                double rrInterval = rrInterval5 / 1024.0;
                double rrTime = self.timestamp;
                self.timestamp = self.timestamp + rrInterval;
                [rrT addObject:[NSNumber numberWithDouble:rrTime]];
                [rrI addObject:[NSNumber numberWithDouble:rrInterval]];
            }
            
            heartRateMonitorData.rrTimes = [[NSArray alloc] initWithArray:rrT];
            heartRateMonitorData.rrIntervals = [[NSArray alloc] initWithArray:rrI];
            heartRateMonitorData.timestamp = fabs([self.monitorStartDate timeIntervalSinceNow]);
        }
        
        NSLog(@"### ---< %@ >---", heartRateMonitorData);
        
        if ([_delegate respondsToSelector:@selector(heartRateMonitorDevice:didreceiveHeartrateMonitorData:)]) {
            [_delegate heartRateMonitorDevice:self didreceiveHeartrateMonitorData:heartRateMonitorData];
        }
    }
}

@end
