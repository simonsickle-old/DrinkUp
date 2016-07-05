//
//  ViewController.h
//  DrinkUp
//
//  Created by Simon Sickle on 7/3/16.
//  Copyright © 2016 Sickle Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
// User info
@property (weak, nonatomic) IBOutlet UILabel *labelWeight;
@property (weak, nonatomic) IBOutlet UILabel *labelBMI;
@property (weak, nonatomic) IBOutlet UILabel *labelDailyGoal;
@property (weak, nonatomic) IBOutlet UILabel *labelAmountDrank;

// Add water to health kit
@property (weak, nonatomic) IBOutlet UITextField *textViewAddWater;
@property (weak, nonatomic) IBOutlet UIButton *btnLogWater;
@end

