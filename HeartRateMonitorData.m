//
//  HeartRateMonitorData.m
//  HeartRateMonitor
//
//  Created by Simon Bogutzky on 07.01.14.
//  Copyright (c) 2014 out there! communication. All rights reserved.
//

#import "HeartRateMonitorData.h"

@implementation HeartRateMonitorData

- (NSString *)heartRateUnit
{
    return @"BPM";
}

- (NSString *)timestampUnit
{
    return @"s";
}

- (NSString *)rrIntervalUnit
{
    return @"s";
}

@end
