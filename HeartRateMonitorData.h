//
//  HeartRateMonitorData.h
//  HeartRateMonitor
//
//  Created by Simon Bogutzky on 07.01.14.
//  Copyright (c) 2014 out there! communication. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HeartRateMonitorData : NSObject

@property (nonatomic) double timestamp;
@property (nonatomic, strong, readonly) NSString *timestampUnit;
@property (nonatomic) int heartRate;
@property (nonatomic, strong, readonly) NSString *heartRateUnit;
@property (nonatomic, strong) NSArray *rrIntervals;
@property (nonatomic, strong, readonly) NSString *rrIntervalUnit;

@end
