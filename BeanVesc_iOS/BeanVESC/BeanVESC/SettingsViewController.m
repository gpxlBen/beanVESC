//
//  SettingsViewController.m
//  BeanVESC
//
//  Created by Ben Harraway on 15/09/2015.
//  Copyright (c) 2015 Gourmet Pixel Ltd. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (void) viewWillDisappear:(BOOL)animated {
    NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
    
    NSNumber *newMaxRPM = [nf numberFromString:tfMaxRPM.text];
    NSNumber *newMaxCurrent = [nf numberFromString:tfMaxCurrent.text];
    
    if (newMaxRPM) [[NSUserDefaults standardUserDefaults] setObject:newMaxRPM forKey:@"maxRPM"];
    if (newMaxCurrent) [[NSUserDefaults standardUserDefaults] setObject:newMaxCurrent forKey:@"maxCurrent"];
    
    NSNumber *controlMode = [[NSUserDefaults standardUserDefaults] objectForKey:@"controlMode"];
    if ([controlMode isEqualToNumber:@(COMM_SET_CURRENT)]) {
        [[NSUserDefaults standardUserDefaults] setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"maxCurrent"] forKey:@"sendMax"];
        
    } else if ([controlMode isEqualToNumber:@(COMM_SET_RPM)]) {
        [[NSUserDefaults standardUserDefaults] setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"maxRPM"] forKey:@"sendMax"];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Settings";
    self.view.backgroundColor = [UIColor whiteColor];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cellIdentifier"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section == 0) return 1;
    if (section == 1) return 1;
    if (section == 2) return 2;
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return @"Control Mode";
    if (section == 1) return @"Reverse Mode";
    if (section == 2) return @"Maximum Values";
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellIdentifier" forIndexPath:indexPath];

    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            UISegmentedControl *controlTypeSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Current", @"RPM"]];
            controlTypeSegmentedControl.frame = CGRectMake(20, 5, self.view.frame.size.width-40, 34);
            [controlTypeSegmentedControl addTarget:self action:@selector(changeControlType:) forControlEvents:UIControlEventValueChanged];
            [cell.contentView addSubview:controlTypeSegmentedControl];
            
            NSNumber *currentControlMode = [[NSUserDefaults standardUserDefaults] objectForKey:@"controlMode"];
            if ([currentControlMode isEqualToNumber:@(COMM_SET_CURRENT)]) {
                controlTypeSegmentedControl.selectedSegmentIndex = 0;
                
            } else if ([currentControlMode isEqualToNumber:@(COMM_SET_RPM)]) {
                controlTypeSegmentedControl.selectedSegmentIndex = 1;
            }
        }
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            UISegmentedControl *controlTypeSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Current Brakes", @"Reverse"]];
            controlTypeSegmentedControl.frame = CGRectMake(20, 5, self.view.frame.size.width-40, 34);
            [controlTypeSegmentedControl addTarget:self action:@selector(changeReverseType:) forControlEvents:UIControlEventValueChanged];
            [cell.contentView addSubview:controlTypeSegmentedControl];
            
            NSNumber *reverseMode = [[NSUserDefaults standardUserDefaults] objectForKey:@"reverseMode"];
            if ([reverseMode isEqualToNumber:@(COMM_SET_CURRENT_BRAKE)]) {
                controlTypeSegmentedControl.selectedSegmentIndex = 0;
                
            } else {
                controlTypeSegmentedControl.selectedSegmentIndex = 1;
            }
        }
        
    } else if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Max Current";
            
            tfMaxCurrent = [[UITextField alloc] initWithFrame:CGRectMake(self.view.frame.size.width-160, 0, 140, 44)];
            [tfMaxCurrent setPlaceholder:@"Maximum Current"];
            [cell.contentView addSubview:tfMaxCurrent];
            
            NSNumber *currentMaxCurrent = [[NSUserDefaults standardUserDefaults] objectForKey:@"maxCurrent"];
            tfMaxCurrent.text = [currentMaxCurrent stringValue];
            
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"Max RPM";
            
            tfMaxRPM = [[UITextField alloc] initWithFrame:CGRectMake(self.view.frame.size.width-160, 0, 140, 44)];
            [tfMaxRPM setPlaceholder:@"Maximum RPM"];
            [cell.contentView addSubview:tfMaxRPM];
            
            NSNumber *currentMaxRPM = [[NSUserDefaults standardUserDefaults] objectForKey:@"maxRPM"];
            tfMaxRPM.text = [currentMaxRPM stringValue];
        }
    }
    
    return cell;
}

- (void) changeControlType:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        [[NSUserDefaults standardUserDefaults] setObject:@(COMM_SET_CURRENT) forKey:@"controlMode"];
        
    } else if (sender.selectedSegmentIndex == 1) {
        [[NSUserDefaults standardUserDefaults] setObject:@(COMM_SET_RPM) forKey:@"controlMode"];
        
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) changeReverseType:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        [[NSUserDefaults standardUserDefaults] setObject:@(COMM_SET_CURRENT_BRAKE) forKey:@"reverseMode"];
        
    } else if (sender.selectedSegmentIndex == 1) {
        [[NSUserDefaults standardUserDefaults] setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"controlMode"] forKey:@"reverseMode"];
        
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
