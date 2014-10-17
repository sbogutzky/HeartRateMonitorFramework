//
//  HeartRateMonitorData.m
//  HeartRateMonitor
//
//  Created by Simon Bogutzky on 07.01.14.
//  Copyright (c) 2014 out there! communication. All rights reserved.
//

#import "HeartRateMonitorData.h"

@implementation HeartRateMonitorData

- (id)init
{
    self = [super init];
    if (self) {
        self.timestamp = [[NSDate date] timeIntervalSince1970];
    }
    return self;
}

- (NSString *)timestampUnit
{
    return @"s";
}

- (NSString *)heartRateUnit
{
    return @"BPM";
}

- (NSString *)rrIntervalUnit
{
    return @"ms";
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%.2f%@ : %d %@ (%@)", self.timestamp, self.timestampUnit, self.heartRate, self.heartRateUnit, [self.rrIntervals componentsJoinedByString:[NSString stringWithFormat:@"%@, ", self.rrIntervalUnit]]];
}

@end
