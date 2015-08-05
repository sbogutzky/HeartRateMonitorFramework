//
//  BioharnessData.m
//  FlowMeter
//
//  Created by Simon Bogutzky on 05.08.15.
//  Copyright (c) 2015 Simon Bogutzky. All rights reserved.
//

#import "BioharnessData.h"

@implementation BioharnessData

- (NSString *)heartRateUnit
{
    return @"BPM";
}

- (NSString *)timestampUnit
{
    return @"s";
}

- (NSString *)breathRateUnit
{
    return @"BPM";
}

- (NSString *)skinTemperaturUnit
{
    return @"°";
}

- (NSString *)postureUnit
{
    return @"deg";
}

- (NSString *)activityLevelUnit
{
    return @"VMU";
}
@end
