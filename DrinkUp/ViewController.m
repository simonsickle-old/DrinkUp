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
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hc = [HealthController sharedManager];
    // Do any additional setup after loading the view, typically from a nib.
    [[HealthController sharedManager] requestAuthorization];
    [_textViewBMI setText: [[NSString alloc] initWithFormat:@"%.2f", [self.hc readBMI]]];
    [_textViewWeight setText:[[NSNumber numberWithDouble:[self.hc readWeight]] stringValue]];
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
}

@end