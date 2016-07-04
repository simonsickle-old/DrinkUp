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

- (void)requestAuthorization {
    
    
    if ([HKHealthStore isHealthDataAvailable] == NO) {
        // If our device doesn't support HealthKit -> return.
        return;
    }
    
    NSArray *readTypes = @[[HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth],
                           [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBiologicalSex],
                           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMassIndex],
                           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass],
                           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight],
                           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryWater]];

    NSArray *writeTypes = @[[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMassIndex],
                            [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass],
                            [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight],
                            [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryWater]];
    
    [self.healthStore requestAuthorizationToShareTypes:[NSSet setWithArray:writeTypes]
                                             readTypes:[NSSet setWithArray:readTypes]
                                            completion:^(BOOL success, NSError *error) {
                                                
                                                NSLog(@"%s",__func__);
                                                if (!success) {
                                                    NSLog(@"You didn't allow HealthKit to access these read/write data types. In your app, try to handle this error gracefully when a user decides not to provide access. The error was: %@. If you're using a simulator, try it on a device.", error);
                                                    return;
                                                }
                                                
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    // Update the user interface based on the current user's health information.
                                                    NSLog(@"=========================== %s",__func__);
                                                });
                                            }];
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
    
    NSLog(@"Height out block: %f", userHeight);
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
    NSLog(@"Weight out block: %f", userWeight);
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
        NSLog(@"Calc BMI = %f", bmi);
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

- (BOOL) writeBMI:(double) bmi {
    __block BOOL result = false;
    HKQuantityType *bodyMassIndex = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMassIndex];
    HKUnit *bmiUnit = [HKUnit countUnit];
    NSDate *now = [NSDate date];
    HKQuantitySample *bmiSample = [HKQuantitySample quantitySampleWithType:bodyMassIndex quantity:[HKQuantity quantityWithUnit:bmiUnit doubleValue:bmi]startDate:now endDate:now];
    
    [self.healthStore saveObject:bmiSample withCompletion:^(BOOL success, NSError *error) {
        if (!success) {
            NSLog(@"Error while saving intake (%f) to Health Store: %@.", bmi, error);
        }
        result = success;
    }];
    
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