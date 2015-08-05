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

@property (nonatomic, strong) NSMutableArray *characteristics;
@property (nonatomic, assign) NSTimeInterval timestamp;
@property (nonatomic, assign) BOOL first;

@end

@implementation HeartRateMonitorDevice

- (id)initWithPeripheral:(CBPeripheral *)peripheral
{
    self = [super init];
    if (self) {
        _peripheral = peripheral;
        _characteristics = [@[] mutableCopy];
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
        CBUUID *heartRateServiceUUID = [CBUUID UUIDWithString:@"180D"];
        CBUUID *bioharness3ServiceUUID = [CBUUID UUIDWithString:@"BEFDFF20-C979-11E1-9B21-0800200C9A66"];
        self.peripheral.delegate = self;
        [self.peripheral discoverServices:@[heartRateServiceUUID, bioharness3ServiceUUID]];
    }
}

- (void)startMonitoring
{
    if (self.state == HeartRateMonitorDeviceStatePrepared) {
        self.first = YES;
        self.monitorStartDate = [NSDate date];
        self.timestamp = 0.0;
        self.state = HeartRateMonitorDeviceStateMonitoring;
        for (CBCharacteristic *characteristic in self.characteristics) {
            [self.peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

- (void)stopMonitoring
{
    if (self.state == HeartRateMonitorDeviceStateMonitoring) {
        for (CBCharacteristic *characteristic in self.characteristics) {
            [self.peripheral setNotifyValue:NO forCharacteristic:characteristic];
        }
    }
    self.state = HeartRateMonitorDeviceStatePrepared;
}

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverServices:(NSError *)error {
    for (CBService *service in peripheral.services) {
        NSLog(@"### Discovered services %@", service.UUID.description);
        
        if ([service.UUID.description isEqualToString:@"BEFDFF20-C979-11E1-9B21-0800200C9A66"]) {
            CBUUID *bioharness3CharacteristicUUID = [CBUUID UUIDWithString:@"BEFDFF60-C979-11E1-9B21-0800200C9A66"];
            [peripheral discoverCharacteristics:@[bioharness3CharacteristicUUID] forService:service];
        }
        
        if ([service.UUID.description isEqualToString:@"Heart Rate"]) {
            CBUUID *heartRateCharacteristicUUID = [CBUUID UUIDWithString:@"2A37"];
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
//        NSLog(@"### Characteristic: %@", characteristic.UUID);
        if ([characteristic.UUID.description isEqualToString:@"2A37"]) {
            self.state = HeartRateMonitorDeviceStatePrepared;
        }
        [self.characteristics addObject:characteristic];
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
        
//        NSLog(@"Characteristic: %@", characteristic.UUID);
        
        if (self.first) {
            self.timestamp = fabs([self.monitorStartDate timeIntervalSinceNow]);
            self.first = NO;
        }
        
        NSData *data = characteristic.value;
        NSUInteger dataSize = data.length;
//        NSLog(@"### Size: %lu", dataSize);
        const uint8_t *reportData = [data bytes];
        
        if ([characteristic.UUID.description isEqualToString:@"2A37"]) {
            uint8_t flagByte = reportData[0];
            
            // Heart Rate Value
            if ((flagByte & HeartRateValueFormatFlag) == 0) {
                // NSLog(@"### Heart Rate Value Format is set to UINT8. Units: beats per minute (bpm)");
                _heartRateIs16Bit = NO;
            } else {
                // NSLog(@"### Heart Rate Value Format is set to UINT16. Units: beats per minute (bpm)");
                _heartRateIs16Bit = YES;
            }
            
            // Sensor Contact Status
            _sensorContactIsPresent = NO;
            switch ((flagByte & SensorContactStatusFlag)) {
                case 0:
                    // NSLog(@"### Sensor Contact feature is not supported in the current connection");
                    break;
                    
                case 2:
                    // NSLog(@"### Sensor Contact feature is not supported in the current connection");
                    break;
                    
                case 4 :
                    // NSLog(@"### Sensor Contact feature is supported, but contact is not detected");
                    break;
                    
                case 6:
                    // NSLog(@"### Sensor Contact feature is supported and contact is detected");
                    _sensorContactIsPresent = YES;
                    break;
                    
                default:
                    break;
            }
            
            // Energy Expended Status
            if ((flagByte & EnergyExpendedStatusFlag) == 0) {
                // NSLog(@"### Energy Expended field is not present");
                _energyExpendedFieldIsPresent = NO;
            } else {
                // NSLog(@"### Energy Expended field is present. Units: kilo Joules");
                _energyExpendedFieldIsPresent = YES;
            }
            
            // One or more RR-Interval values are present. Units: 1/1024 seconds
            if ((flagByte & RRIntervalFlag) == 0) {
                // NSLog(@"### RR-Interval values are not present.");
                _rrIntervalsArePresent = NO;
            } else {
                // NSLog(@"### One or more RR-Interval values are present. Units: 1/1024 seconds");
                _rrIntervalsArePresent = YES;
            }
            
            int heartRate = -1;
            if (_heartRateIs16Bit) {
                uint8_t heartRateByte1 = reportData[1];
                uint8_t heartRateByte2 = reportData[2];
                heartRate = heartRateByte2 << 8 | heartRateByte1;
//                NSLog(@"### Heart rate (16 bit): %d", heartRate);
            } else {
                heartRate = reportData[1];
//                NSLog(@"### Heart rate ( 8 bit): %d", heartRate);
            }
            
            HeartRateMonitorData *heartRateMonitorData = [[HeartRateMonitorData alloc] init];
            heartRateMonitorData.heartRate = heartRate;
            
            if (_rrIntervalsArePresent) {
                uint8_t offset = 2;
                if (_heartRateIs16Bit) {
                    offset++;
                }
                
                if (_energyExpendedFieldIsPresent) {
                    offset += 2;
                }
                
                // NSLog(@"### First RR-Interval Byte: %d", offset);
                NSUInteger rrIntervalCount = (dataSize - offset) / 2;
                
//                NSLog(@"### RR-Interval Count: %d", rrIntervalCount);
                
                NSMutableArray *rrT = [NSMutableArray arrayWithCapacity:rrIntervalCount];
                NSMutableArray *rrI = [NSMutableArray arrayWithCapacity:rrIntervalCount];
                
                for (int i = 0; i < rrIntervalCount; i++) {
                    uint8_t rrIntervalByte1 = reportData[offset];
                    uint8_t rrIntervalByte2 = reportData[offset + 1];
                    int rrIntervalInMillis = rrIntervalByte2 << 8 | rrIntervalByte1;
//                    NSLog(@"### RR-Interval %d: %d", i, rrIntervalInMillis);
                    if (rrIntervalInMillis > 0) {
                        double rrIntervalInSeconds = rrIntervalInMillis / 1024.0;
                        double rrTime = self.timestamp;
                        self.timestamp = self.timestamp + rrIntervalInSeconds;
                        [rrT addObject:[NSNumber numberWithDouble:rrTime]];
                        [rrI addObject:[NSNumber numberWithDouble:rrIntervalInSeconds]];
                    }
                    
                    offset += 2;
                }
                
                heartRateMonitorData.rrTimes = [[NSArray alloc] initWithArray:rrT];
                heartRateMonitorData.rrIntervals = [[NSArray alloc] initWithArray:rrI];
                heartRateMonitorData.timestamp = fabs([self.monitorStartDate timeIntervalSinceNow]);
            }
            
            // NSLog(@"### ---< %@ >---", heartRateMonitorData);
            
            if ([_delegate respondsToSelector:@selector(heartRateMonitorDevice:didreceiveHeartrateMonitorData:)]) {
                [_delegate heartRateMonitorDevice:self didreceiveHeartrateMonitorData:heartRateMonitorData];
            }
        }
        
        if ([characteristic.UUID.description isEqualToString:@"BEFDFF60-C979-11E1-9B21-0800200C9A66"]) {
            // 3 ist Heartrate
            // 4 ist Respiration Rate 2 Bytes
            // 6 ist Skintemperatur 2 Bytes
            
//            NSLog(@"### Heartrate: %d", [self get8BitNumberWithPos:3 fromPlayload:[data bytes]]);
//            NSLog(@"### Respiration rate: %.1f", [self get16BitNumberWithPos:4 fromPlayload:[data bytes]] / 10.0);
//            NSLog(@"### Skintemperatur: %.1f", [self get16BitNumberWithPos:6 fromPlayload:[data bytes]] / 10.0);
            
            NSLog(@"Tested Pos %d ( 8 bit): %d", self.testByte, [self get8BitNumberWithPos:self.testByte fromPlayload:[data bytes]]);
            NSLog(@"Tested Pos %d (16 bit): %d", self.testByte, [self get16BitNumberWithPos:self.testByte fromPlayload:[data bytes]]);
        }
    }
}

- (int)get8BitNumberWithPos:(int)pos fromPlayload:(const uint8_t *)payload
{
    return (int)(payload[pos]);
}

- (int)get16BitNumberWithPos:(int)pos fromPlayload:(const uint8_t *)payload
{
    int _1x = (int)(payload[pos + 1] << 8);
    int _x1 = (int)(payload[pos]);
    return (int)(_1x | _x1);
}

@end
