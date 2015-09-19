//
//  BioharnessData.h
//  FlowMeter
//
//  Created by Simon Bogutzky on 05.08.15.
//  Copyright (c) 2015 Simon Bogutzky. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BioharnessData : NSObject

@property (nonatomic, assign) double timestamp;
@property (nonatomic, strong, readonly) NSString *timestampUnit;
@property (nonatomic) int heartRate;
@property (nonatomic, strong, readonly) NSString *heartRateUnit;
@property (nonatomic) double breathRate;
@property (nonatomic, strong, readonly) NSString *breathRateUnit;
@property (nonatomic) double skinTemperature;
@property (nonatomic, strong, readonly) NSString *skinTemperatureUnit;
@property (nonatomic) int posture;
@property (nonatomic, strong, readonly) NSString *postureUnit;
@property (nonatomic) double activityLevel;
@property (nonatomic, strong, readonly) NSString *activityLevelUnit;

@end
