//
//  HealthController.h
//  DrinkUp
//
//  Created by Simon Sickle on 7/3/16.
//  Copyright © 2016 Sickle Technologies. All rights reserved.
//

#ifndef HealthController_h
#define HealthController_h
@import Foundation;
@import HealthKit;
#import "HKHealthStore+AAPLExtensions.h"

@interface HealthController : NSObject
+ (HealthController *) sharedManager;
- (BOOL) requestAuthorization;

// Helper functions
- (double)getGoalAmount:(BOOL) isPregnantOrBreastFeeding;

// Get user details
- (NSDate *) readBirthDate;

// Read quantity from HKStore
- (double) readHeight;
- (double) readWeight;
- (double) readBMI;
- (double) readSumWorkoutForToday;
- (double) readSumWaterIntakeForToday;

// Write to HKStore
- (BOOL) writeHeight:(double)height :(HKUnit*) unit;
- (BOOL) writeWeight:(double)weight :(HKUnit*) unit;
- (BOOL) writeBMI:(double) bmi;
- (void) writeWaterIntake:(double)intake :(HKUnit*) unit;
@end

#endif /* HealthController_h */
