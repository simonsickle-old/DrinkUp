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
@import UIKit;
@import HealthKit;
#import "HKHealthStore+AAPLExtensions.h"

@interface HealthController : NSObject
+ (HealthController *) sharedManager;

- (void) requestAuthorization;
- (NSDate *) readBirthDate;
- (double) readHeight;
- (double) readWeight;
- (double) readBMI;
- (BOOL) writeBMI:(double) bmi;
- (void) writeWaterIntake:(double)intake :(HKUnit*) unit;
@end
#endif /* HealthController_h */
