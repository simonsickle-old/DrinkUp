//
//  ViewController.m
//  DrinkUp
//
//  Created by Simon Sickle on 7/3/16.
//  Copyright © 2016 Sickle Technologies. All rights reserved.
//

#import "ViewController.h"
#import "Utils/HealthController.h"

@interface ViewController ()
@property (nonatomic, retain) HealthController *hc;
@property (nonatomic, retain) NSUserDefaults *prefs;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Daily goal is in oz
    NSInteger dailyGoal = 0;
    
    // Set class variables
    self.hc = [HealthController sharedManager];
    self.prefs = [NSUserDefaults standardUserDefaults];
    
    // Request authorization from user
    [[HealthController sharedManager] requestAuthorization];

    // Set the daily goal from prefs
    if ([self.prefs objectForKey:@"dailyGoal"] != nil)
        dailyGoal = [self.prefs integerForKey:@"dailyGoal"];
    
    // Get goal amount takes BOOL isPregnantOrBreastFeeding
    NSInteger calcDailyGoal = [self.hc getGoalAmount:NO];
    if (dailyGoal != calcDailyGoal) {
        [self.prefs setInteger:calcDailyGoal forKey:@"dailyGoal"];
        dailyGoal = calcDailyGoal;
        [self.prefs synchronize];
    }
    
    // Set the Weight
    NSString *textForWeight = [[NSString alloc] initWithFormat:@"Weight: %ld lbs", (long)[self.hc readWeight]];
    [_labelWeight setText:textForWeight];
    
    // Set the BMI
    NSString *textForBMI = [[NSString alloc] initWithFormat:@"BMI: %.2f", [self.hc readBMI]];
    [_labelBMI setText:textForBMI];
    
    // Set the Daily Goal
    NSString *textForDailyGoal = [[NSString alloc] initWithFormat:@"Daily Goal: %ld oz", (long)dailyGoal];
    [_labelDailyGoal setText:textForDailyGoal];
    
    // Set the Amount Drank
    NSString *textForAmountDrank = [[NSString alloc] initWithFormat:@"Amount Drank Today: %ld oz", (long)[self.hc readSumWaterIntakeForToday]];
    [_labelAmountDrank setText:textForAmountDrank];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)addWater:(id)sender {
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber *number = [f numberFromString:_textViewAddWater.text];
    
    [self.hc writeWaterIntake:[number doubleValue] :[HKUnit fluidOunceUSUnit]];
    
    // Reset the Amount Drank
    NSString *textForAmountDrank = [[NSString alloc] initWithFormat:@"Amount Drank Today: %ld oz", (long)[self.hc readSumWaterIntakeForToday]];
    [_labelAmountDrank setText:textForAmountDrank];
}

@end