//
//  HeartRateMonitorManager.m
//  HeartRateMonitor
//
//  Created by Simon Bogutzky on 28.12.13.
//  Copyright (c) 2013 bogutzky. All rights reserved.
//

#import "HeartRateMonitorManager.h"
#import "HeartRateMonitorManagerDelegate.h"
#import "HeartRateMonitorDevice.h"

@interface HeartRateMonitorManager()

@property (nonatomic, strong) CBCentralManager *manager;
@property (nonatomic, strong) HeartRateMonitorDevice *connectedHeartRateMonitorDevice;

@end

@implementation HeartRateMonitorManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        // CHECK: no restoring
        NSDictionary *options = @{CBCentralManagerOptionShowPowerAlertKey: @(YES)};
        // CHECK: use main queue
        _manager = [[CBCentralManager alloc] initWithDelegate:self
                                                        queue:nil
                                                      options:options];
    }
    return self;
}

- (void)scanForHeartRateMonitorDeviceWhichWereConnected:(BOOL)wereConnected
{
    CBUUID *heartRateServiceUUID = [CBUUID UUIDWithString:@"180D"];
    switch (self.state) {
        case CBCentralManagerStatePoweredOn: {
            
            NSArray *peripherals;
            if (wereConnected) {
                NSMutableArray *storedHeartRateMonitorDeviceIndentifierStrings = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"storedHeartRateMonitorDeviceIndentifierStrings"]];
                NSMutableArray *heartRateMonitorDeviceIndentifiers = [[NSMutableArray alloc] initWithCapacity:[storedHeartRateMonitorDeviceIndentifierStrings count]];
                for (NSString *storedHeartRateMonitorDeviceIndentifierString in storedHeartRateMonitorDeviceIndentifierStrings) {
                    [heartRateMonitorDeviceIndentifiers addObject:[CBUUID UUIDWithString:storedHeartRateMonitorDeviceIndentifierString]];
                }
                
                peripherals = [self.manager retrievePeripheralsWithIdentifiers:heartRateMonitorDeviceIndentifiers];
                [self didDiscoverPeripherals:peripherals];
            }
            
            if (peripherals == nil || [peripherals count] == 0) {
                [self.manager scanForPeripheralsWithServices:@[heartRateServiceUUID] options:nil];
            }
        }
            break;
            
        default:
            break;
    }
}

- (void)stopScanning
{
    [self.manager stopScan];
}

- (void)connectHeartRateMonitorDevice:(HeartRateMonitorDevice *)heartRateMonitorDevice
{
    [self.manager connectPeripheral:heartRateMonitorDevice.peripheral options:@{@"CBConnectPeripheralOptionNotifyOnNotificationKey": @(YES)}];
}

- (void)disconnectHeartRateMonitorDevice
{
    if (self.connectedHeartRateMonitorDevice) {
        [self.manager cancelPeripheralConnection:self.connectedHeartRateMonitorDevice.peripheral];
    }
}

- (BOOL)hasConnection
{
    return (self.connectedHeartRateMonitorDevice != nil);
}

- (void)startMonitoring {
    if (self.connectedHeartRateMonitorDevice) {
        switch (self.connectedHeartRateMonitorDevice.state) {
            case HeartRateMonitorDeviceStatePrepared:
                [self.connectedHeartRateMonitorDevice startMonitoring];
                break;
            
            case HeartRateMonitorDeviceStateResetting:
                [self.connectedHeartRateMonitorDevice prepareForMonitoring];
                break;
                
            case HeartRateMonitorDeviceStateUnknown: {
                if ([_delegate respondsToSelector:@selector(heartRateMonitorManager:didFailToMonitorHeartrateMonitorDevice:error:)]) {
                    NSMutableDictionary *details = [NSMutableDictionary dictionary];
                    [details setValue:@"Unknown monitor error" forKey:NSLocalizedDescriptionKey];
                    NSError *error = [NSError errorWithDomain:@"de.bogutzky" code:1 userInfo:details];
                    NSLog(@"## Error: %@", [error localizedDescription]);
                    [_delegate heartRateMonitorManager:self didFailToMonitorHeartrateMonitorDevice:self.connectedHeartRateMonitorDevice error:error];
                    
                }
            }
                break;
            
            default:
                break;
        }
    } else {
        if ([_delegate respondsToSelector:@selector(heartRateMonitorManager:didFailToMonitorHeartrateMonitorDevice:error:)]) {
            NSMutableDictionary *details = [NSMutableDictionary dictionary];
            [details setValue:@"No connected heart rate monitor device" forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"de.bogutzky" code:2 userInfo:details];
            NSLog(@"## Error: %@", [error localizedDescription]);
            [_delegate heartRateMonitorManager:self didFailToMonitorHeartrateMonitorDevice:nil error:error];
            
        }
    }
}

- (void)stopMonitoring {
    if (self.connectedHeartRateMonitorDevice) {
        switch (self.connectedHeartRateMonitorDevice.state) {
            case HeartRateMonitorDeviceStateMonitoring:
                [self.connectedHeartRateMonitorDevice stopMonitoring];
                break;
                
            case HeartRateMonitorDeviceStateResetting:
                [self.connectedHeartRateMonitorDevice prepareForMonitoring];
                break;
                
            case HeartRateMonitorDeviceStateUnknown: {
                if ([_delegate respondsToSelector:@selector(heartRateMonitorManager:didFailToMonitorHeartrateMonitorDevice:error:)]) {
                    NSMutableDictionary *details = [NSMutableDictionary dictionary];
                    [details setValue:@"Unknown monitor error" forKey:NSLocalizedDescriptionKey];
                    NSError *error = [NSError errorWithDomain:@"de.bogutzky" code:1 userInfo:details];
                    NSLog(@"## Error: %@", [error localizedDescription]);
                    [_delegate heartRateMonitorManager:self didFailToMonitorHeartrateMonitorDevice:self.connectedHeartRateMonitorDevice error:error];
                    
                }
            }
                break;
                
            default:
                break;
        }
    } else {
        if ([_delegate respondsToSelector:@selector(heartRateMonitorManager:didFailToMonitorHeartrateMonitorDevice:error:)]) {
            NSMutableDictionary *details = [NSMutableDictionary dictionary];
            [details setValue:@"No connected heart rate monitor device" forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"de.bogutzky" code:2 userInfo:details];
            NSLog(@"## Error: %@", [error localizedDescription]);
            [_delegate heartRateMonitorManager:self didFailToMonitorHeartrateMonitorDevice:nil error:error];
            
        }
    }
}

- (HeartRateMonitorDeviceState)deviceState
{
    return self.connectedHeartRateMonitorDevice == nil ? HeartRateMonitorDeviceStateUnknown : self.connectedHeartRateMonitorDevice.state;
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    self.state = (HeartRateMonitorManagerState) central.state;
}

- (void)didDiscoverPeripherals:(NSArray *)peripherals
{
    NSMutableArray *heartRateMonitorDevices = [[NSMutableArray alloc] initWithCapacity:[peripherals count]];
    for (CBPeripheral *peripheral in peripherals) {
        HeartRateMonitorDevice *heartRateMonitorDevice = [[HeartRateMonitorDevice alloc] initWithPeripheral:peripheral];
        NSLog(@"### Discovered %@", heartRateMonitorDevice.name);
        [heartRateMonitorDevices addObject:heartRateMonitorDevice];
    }
    
    if ([_delegate respondsToSelector:@selector(heartRateMonitorManager:didDiscoverHeartrateMonitorDevices:)]) {
        [_delegate heartRateMonitorManager:self didDiscoverHeartrateMonitorDevices:heartRateMonitorDevices];
    }
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI {
    [self didDiscoverPeripherals:@[peripheral]];
}

- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral
{
    HeartRateMonitorDevice *heartRateMonitorDevice = [[HeartRateMonitorDevice alloc] initWithPeripheral:peripheral];
    heartRateMonitorDevice.delegate = self;
    NSLog(@"### Connected %@", heartRateMonitorDevice.name);
    
    NSMutableArray *storedHeartRateMonitorDeviceIndentifierStrings = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"storedHeartRateMonitorDeviceIndentifierStrings"]];
    BOOL notIn = YES;
    for (NSString *heartRateMonitorDeviceIndentifierString in storedHeartRateMonitorDeviceIndentifierStrings) {
        NSLog(@"### %@ == %@", heartRateMonitorDeviceIndentifierString, [peripheral.identifier UUIDString]);
        if ([heartRateMonitorDeviceIndentifierString isEqualToString:[peripheral.identifier UUIDString]]) {
            notIn = NO;
        }
    }
    if (notIn) {
        [storedHeartRateMonitorDeviceIndentifierStrings addObject:[peripheral.identifier UUIDString]];
        [[NSUserDefaults standardUserDefaults] setObject:storedHeartRateMonitorDeviceIndentifierStrings forKey:@"storedHeartRateMonitorDeviceIndentifierStrings"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    self.connectedHeartRateMonitorDevice = heartRateMonitorDevice;
    [heartRateMonitorDevice prepareForMonitoring];
    if ([_delegate respondsToSelector:@selector(heartRateMonitorManager:didConnectHeartrateMonitorDevice:)]) {
        [_delegate heartRateMonitorManager:self didConnectHeartrateMonitorDevice:heartRateMonitorDevice];
    }
}

- (void)centralManager:(CBCentralManager *)central
didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error {
    HeartRateMonitorDevice *heartRateMonitorDevice = [[HeartRateMonitorDevice alloc] initWithPeripheral:peripheral];
    NSLog(@"### Disconnected %@", heartRateMonitorDevice.name);
    if (error) {
        NSLog(@"### Error: %@", [error localizedDescription]);
    }
    if ([_delegate respondsToSelector:@selector(heartRateMonitorManager:didDisconnectHeartrateMonitorDevice:error:)]) {
        [_delegate heartRateMonitorManager:self didDisconnectHeartrateMonitorDevice:heartRateMonitorDevice error:error];
    }
    self.connectedHeartRateMonitorDevice = nil;
}

- (void)centralManager:(CBCentralManager *)central
didFailToConnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    HeartRateMonitorDevice *heartRateMonitorDevice = [[HeartRateMonitorDevice alloc] initWithPeripheral:peripheral];
    NSLog(@"### Error: %@", [error localizedDescription]);
    if ([_delegate respondsToSelector:@selector(heartRateMonitorManager:didFailToConnectHeartrateMonitorDevice:error:)]) {
        [_delegate heartRateMonitorManager:self didFailToConnectHeartrateMonitorDevice:heartRateMonitorDevice error:error];
    }
}

- (void)heartRateMonitorDevice:(HeartRateMonitorDevice *)device didreceiveHeartrateMonitorData:(HeartRateMonitorData *)data {
    if ([_delegate respondsToSelector:@selector(heartRateMonitorManager:didReceiveHeartrateMonitorData:fromHeartRateMonitorDevice:)]) {
        [_delegate heartRateMonitorManager:self didReceiveHeartrateMonitorData:data fromHeartRateMonitorDevice:device];
    }
}

@end
