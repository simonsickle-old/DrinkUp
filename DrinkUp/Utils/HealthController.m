//
//  HealthController.m
//  DrinkUp
//
//  Created by Simon Sickle on 7/3/16.
//  Copyright © 2016 Sickle Technologies. All rights reserved.
//

#include "HealthController.h"

@interface HealthController()
@property (nonatomic, retain) HKHealthStore *healthStore;
@end

@implementation HealthController

+ (HealthController *)sharedManager {
    static dispatch_once_t pred = 0;
    static HealthController *instance = nil;
    dispatch_once(&pred, ^{
        instance = [[HealthController alloc] init];
        instance.healthStore = [[HKHealthStore alloc] init];
    });
    return instance;
}

- (BOOL)requestAuthorization {
    
    // Check if HK is avail
    if ([HKHealthStore isHealthDataAvailable] == NO) {
        return NO;
    }
    
    __block BOOL ret = NO;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    NSArray *readTypes = @[[HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth],
                           [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBiologicalSex],
                           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMassIndex],
                           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass],
                           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight],
                           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierAppleExerciseTime],
                           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryWater]];

    NSArray *writeTypes = @[[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMassIndex],
                            [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass],
                            [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight],
                            [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryWater]];
    
    [self.healthStore requestAuthorizationToShareTypes:[NSSet setWithArray:writeTypes]
                                             readTypes:[NSSet setWithArray:readTypes]
                                            completion:^(BOOL success, NSError *error) {
                                                ret = success;
                                                dispatch_semaphore_signal(semaphore);
                                                
                                                if (!success) {
                                                    NSLog(@"You didn't allow HealthKit to access these read/write data types. In your app, try to handle this error gracefully when a user decides not to provide access. The error was: %@. If you're using a simulator, try it on a device.", error);
                                                    return;
                                                }
                                            }];
    return ret;
}

// Source: https://www.umsystem.edu/newscentral/totalrewards/2014/06/19/how-to-calculate-how-much-water-you-should-drink/
// All measurements in lbs and oz
- (double)getGoalAmount:(BOOL) isPregnantOrBreastFeeding {
    double userWeight = self.readWeight;
    double goalAmount = 0;
    double minsOfExercise = self.readSumWorkoutForToday;
    
    // weight * .5 = oz of water per day
    goalAmount = userWeight * 0.5f;
    
    // Add exercise to goal
    goalAmount += ((minsOfExercise/30.0f) * 12.0f);
    
    // If pregnant add another 32 oz
    if (isPregnantOrBreastFeeding)
        goalAmount += 32;
    
    // Returns the goal in oz
    return goalAmount;
}

- (NSDate *) readBirthDate {
    NSError *error;
    NSDate *dateOfBirth = [self.healthStore dateOfBirthWithError:&error];   // Convenience method of HKHealthStore to get date of birth directly.
    
    if (!dateOfBirth) {
        NSLog(@"Either an error occured fetching the user's age information or none has been stored yet. In your app, try to handle this gracefully.");
    }
    
    return dateOfBirth;
}

- (double) readHeight {
    HKQuantityType *heightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
    __block double userHeight = 0;
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self.healthStore aapl_mostRecentQuantitySampleOfType:heightType predicate:nil completion:^(HKQuantity *mostRecentQuantity, NSError *error) {
        
        if (!mostRecentQuantity) {
            NSLog(@"Either an error occured fetching the user's height information or none has been stored yet. In your app, try to handle this gracefully.");
        }
        else {
            // Determine the weight in the required unit.
            HKUnit *heightUnit = [HKUnit inchUnit];
            userHeight = [mostRecentQuantity doubleValueForUnit:heightUnit];
        }
        
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    return userHeight;

}

- (double) readWeight {
    HKQuantityType *weightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    __block double userWeight = 0;
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self.healthStore aapl_mostRecentQuantitySampleOfType:weightType predicate:nil completion:^(HKQuantity *mostRecentQuantity, NSError *error) {
        if (!mostRecentQuantity) {
            NSLog(@"Either an error occured fetching the user's weight information or none has been stored yet. In your app, try to handle this gracefully.");
        }
        else {
            // Determine the weight in the required unit.
            HKUnit *weightUnit = [HKUnit poundUnit];
            //            double usersWeight = [mostRecentQuantity doubleValueForUnit:weightUnit];
            userWeight = [mostRecentQuantity doubleValueForUnit:weightUnit];
        }
        
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return userWeight;
}

- (double) readBMI {
    HKQuantityType *bodyMassIndex = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMassIndex];
    HKUnit *bmiUnit = [HKUnit countUnit];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    // Get height and weight for BMI calculation
    double userWeight = [self readWeight];
    double userHeight = [self readHeight];
    
    // Compare apples to apples
    __block HKQuantity *bmiQuant;
    __block double bmi = 0;
    
    // calculate a BMI
    if (userHeight != 0 && userWeight != 0) {
        bmi = (userWeight / (userHeight * userHeight)) * 703;
        bmiQuant = [HKQuantity quantityWithUnit:bmiUnit doubleValue:bmi];
    }
    
    [self.healthStore aapl_mostRecentQuantitySampleOfType:bodyMassIndex predicate:nil completion:^(HKQuantity *mostRecentQuantity, NSError *error) {
        
        // Check if there is a most recent entry
        if (mostRecentQuantity) {
            // If most recent doesn't equal calculated, write it to HK
            if ([mostRecentQuantity doubleValueForUnit:bmiUnit] != [bmiQuant doubleValueForUnit:bmiUnit]) {
                bmi = [mostRecentQuantity doubleValueForUnit:bmiUnit];
                [self writeBMI:bmi];
            }
        } else {
            // Write the BMI if it was calculated
            if (bmi != 0)
                [self writeBMI:bmi];
        }
        dispatch_semaphore_signal(semaphore);
    }];
    
    // Wait for async to complete
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    // Return the BMI
    return bmi;
}

- (double) readSumWorkoutForToday {
    __block double minsWorkout = 0;
    
    // Set date to get the exercise from
    NSDate *now = [NSDate date];
    NSCalendar *const calendar = NSCalendar.currentCalendar;
    NSCalendarUnit const preservedComponents = (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay);
    NSDateComponents *const components = [calendar components:preservedComponents fromDate:now];
    NSDate *const startOfToday = [calendar dateFromComponents:components];
    NSDateComponents *interval = [[NSDateComponents alloc] init];
    interval.day = 2;
    
    // Set query for AppleExerciseTime
    HKQuantityType *type = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierAppleExerciseTime];
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startOfToday endDate:now options:HKQueryOptionStrictStartDate];
    HKStatisticsCollectionQuery *query = [[HKStatisticsCollectionQuery alloc] initWithQuantityType:type quantitySamplePredicate:predicate options:HKStatisticsOptionCumulativeSum anchorDate:startOfToday intervalComponents:interval];
    
    // Make the code execute in order
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    // Create results handler for query
    query.initialResultsHandler = ^(HKStatisticsCollectionQuery *query, HKStatisticsCollection *results, NSError *error) {
        if (error) {
            // Perform proper error handling here
            NSLog(@"*** An error occurred while calculating the statistics: %@ ***",
                  error.localizedDescription);
            abort();
        }
        
        // Get the sum of the results
        [results enumerateStatisticsFromDate:startOfToday toDate:now
         withBlock:^(HKStatistics *result, BOOL *stop) {
             if (result.sumQuantity)
                 minsWorkout += [result.sumQuantity doubleValueForUnit:[HKUnit minuteUnit]];
         }];
        
        // Tell main thread to continue now
        dispatch_semaphore_signal(semaphore);
    };
    
    // Run the query
    [self.healthStore executeQuery:query];
    
    // Wait for async block to complete
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return minsWorkout;
}

- (double) readSumWaterIntakeForToday {
    __block double waterIntake = 0;
    
    // Set date to get the exercise from
    NSDate *now = [NSDate date];
    NSCalendar *const calendar = NSCalendar.currentCalendar;
    NSCalendarUnit const preservedComponents = (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay);
    NSDateComponents *const components = [calendar components:preservedComponents fromDate:now];
    NSDate *const startOfToday = [calendar dateFromComponents:components];
    NSDateComponents *interval = [[NSDateComponents alloc] init];
    interval.day = 2;
    
    // Set query for AppleExerciseTime
    HKQuantityType *type = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryWater];
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startOfToday endDate:now options:HKQueryOptionStrictStartDate];
    HKStatisticsCollectionQuery *query = [[HKStatisticsCollectionQuery alloc] initWithQuantityType:type quantitySamplePredicate:predicate options:HKStatisticsOptionCumulativeSum anchorDate:startOfToday intervalComponents:interval];
    
    // Make the code execute in order
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    // Create results handler for query
    query.initialResultsHandler = ^(HKStatisticsCollectionQuery *query, HKStatisticsCollection *results, NSError *error) {
        if (error) {
            // Perform proper error handling here
            NSLog(@"*** An error occurred while calculating the statistics: %@ ***",
                  error.localizedDescription);
            abort();
        }
        
        // Get the sum of the results
        [results enumerateStatisticsFromDate:startOfToday toDate:now
                                   withBlock:^(HKStatistics *result, BOOL *stop) {
                                       if (result.sumQuantity)
                                           waterIntake += [result.sumQuantity doubleValueForUnit:[HKUnit fluidOunceUSUnit]];
                                   }];
        
        // Tell main thread to continue now
        dispatch_semaphore_signal(semaphore);
    };
    
    // Run the query
    [self.healthStore executeQuery:query];
    
    // Wait for async block to complete
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return waterIntake;
}

- (BOOL) writeBMI:(double) bmi {
    __block BOOL result = false;
    
    // Set HK info
    HKQuantityType *bodyMassIndex = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMassIndex];
    HKUnit *bmiUnit = [HKUnit countUnit];
    NSDate *now = [NSDate date];
    HKQuantitySample *bmiSample = [HKQuantitySample quantitySampleWithType:bodyMassIndex quantity:[HKQuantity quantityWithUnit:bmiUnit doubleValue:bmi]startDate:now endDate:now];
    
    // Make the code execute in order
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self.healthStore saveObject:bmiSample withCompletion:^(BOOL success, NSError *error) {
        if (!success) {
            NSLog(@"Error while saving intake (%f) to Health Store: %@.", bmi, error);
        }
        
        result = success;
        
        // Tell main thread to continue now
        dispatch_semaphore_signal(semaphore);
    }];
    
    // Wait for async block to complete
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return result;
}

- (void) writeWaterIntake:(double)intake :(HKUnit*) unit {
    HKQuantity *waterIntake = [HKQuantity quantityWithUnit:unit doubleValue:intake];
    HKQuantityType *waterType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryWater];
    NSDate *now = [NSDate date];
    
    // For every sample, we need a sample type, quantity and a date.
    HKQuantitySample *waterSample = [HKQuantitySample quantitySampleWithType:waterType quantity:waterIntake startDate:now endDate:now];
    
    [self.healthStore saveObject:waterSample withCompletion:^(BOOL success, NSError *error) {
        if (!success) {
            NSLog(@"Error while saving intake (%f) to Health Store: %@.", intake, error);
        }
    }];
}
@end