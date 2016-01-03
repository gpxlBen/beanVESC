//
//  ViewController.m
//  BeanVESC
//
//  Created by Ben Harraway on 03/09/2015.
//  Copyright (c) 2015 Gourmet Pixel Ltd. All rights reserved.
//

#import "ControlViewController.h"
#import "SettingsViewController.h"

@interface ControlViewController ()

@end

@implementation ControlViewController

#define CENTER_DEADZONE 100  // Number of pixels in the center deadzone (motor release)
#define SEND_SERIAL_DATA_INTERVAL 0.25 // Seconds between sending commands

// To Send 3500 RPM = 10 bytes
// 10 x 10 / 19200 = 0.005 seconds to transmit

- (void) setupDefaults {
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"controlMode"]) {
        [[NSUserDefaults standardUserDefaults] setObject:@(COMM_SET_CURRENT) forKey:@"controlMode"];
        [[NSUserDefaults standardUserDefaults] setObject:@3500 forKey:@"maxRPM"];
        [[NSUserDefaults standardUserDefaults] setObject:@3 forKey:@"maxCurrent"];
        [[NSUserDefaults standardUserDefaults] setObject:@3 forKey:@"sendMax"];
        [[NSUserDefaults standardUserDefaults] setObject:@(COMM_SET_CURRENT_BRAKE) forKey:@"reverseMode"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.title = @"BeanVESC";
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupDefaults];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Get Values" style:UIBarButtonItemStylePlain target:self action:@selector(getVESCValues)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStylePlain target:self action:@selector(showSettings)];
    
    self.aVescController = [[VescController alloc] init];
    
    self.beanManager = [[PTDBeanManager alloc] initWithDelegate:self];
    self.bean = nil;
    
    currentValue = 0;
    recievingData = [[NSMutableData alloc] init];
    
    // Disconnect Bean if app goes into background
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disconnectBean) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    // Connect Bean when app is active
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startScanningSoon) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    self.view.multipleTouchEnabled = YES;
    
    aGradientView = [[GradientView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [aGradientView setUserInteractionEnabled:NO];
    [self.view addSubview:aGradientView];
    
    
    statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, ((self.view.frame.size.height-40)/2)+20, self.view.frame.size.width-20, 30)];
    [statusLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:14]];
    [statusLabel setText:@"hello"];
    [statusLabel setTextColor:[UIColor lightGrayColor]];
    [statusLabel setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:statusLabel];
    
    UIView *middleLineViewTop = [[UIView alloc] initWithFrame:CGRectMake(0, (self.view.frame.size.height/2)-(CENTER_DEADZONE/2), self.view.frame.size.width, 1)];
    [middleLineViewTop setBackgroundColor:[UIColor colorWithRed:0.75 green:0.75 blue:0.75 alpha:0.5]];
    [self.view addSubview:middleLineViewTop];
    
    UIView *middleLineViewBottom = [[UIView alloc] initWithFrame:CGRectMake(0, (self.view.frame.size.height/2)+(CENTER_DEADZONE/2), self.view.frame.size.width, 1)];
    [middleLineViewBottom setBackgroundColor:[UIColor colorWithRed:0.75 green:0.75 blue:0.75 alpha:0.5]];
    [self.view addSubview:middleLineViewBottom];
    
    UILabel *lblBeanBot = [[UILabel alloc] initWithFrame:CGRectMake(0, ((self.view.frame.size.height-40)/2)-20, self.view.frame.size.width, 40)];
    [lblBeanBot setTextAlignment:NSTextAlignmentCenter];
    [lblBeanBot setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:30]];
    [lblBeanBot setText:@"BeanVESC"];
    [self.view addSubview:lblBeanBot];

    sendSerialDataTimer = [NSTimer scheduledTimerWithTimeInterval:SEND_SERIAL_DATA_INTERVAL target:self selector:@selector(sendCommandToBean) userInfo:nil repeats:YES];
    [self startScanningSoon];
}

- (void) showSettings {
    SettingsViewController *aSettingsViewController = [[SettingsViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:aSettingsViewController animated:YES];
}

- (void) startScanningSoon {
    [self performSelector:@selector(startScanning) withObject:nil afterDelay:1.5];
}

- (void) startScanning {
    if(self.beanManager.state == BeanManagerState_PoweredOn) {
        NSError *err;
        [self.beanManager startScanningForBeans_error:&err];
        statusLabel.text = @"Scanning";
        if (err) {
            statusLabel.text = [err localizedDescription];
        }
    } else {
        statusLabel.text = @"Bean Manager not powered on. Reload app to try again";
    }
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint touchPoint = [[touches anyObject] locationInView:self.view];
    [self calculateMovement:touchPoint];
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint touchPoint = [[touches anyObject] locationInView:self.view];
    [self calculateMovement:touchPoint];
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    currentValue = 0;
    
    aGradientView.inputY = nil;
    [aGradientView setNeedsDisplay];
}

- (void) calculateMovement:(CGPoint)touchPoint {
    int maxY = 0;
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"sendMax"]) {
        maxY = [[[NSUserDefaults standardUserDefaults] objectForKey:@"sendMax"] intValue];
    }
    
    float screenMaxY = ((self.view.frame.size.height)/2)-(CENTER_DEADZONE/2);
    
    int calcValue = maxY - (floor(((touchPoint.y-70) / screenMaxY) * maxY));
    
    // Change Gradients
    aGradientView.inputY = [NSNumber numberWithFloat:touchPoint.y];
    [aGradientView setNeedsDisplay];

    // Don't send data if inside the deadzone
    if ((touchPoint.y < (self.view.frame.size.height/2)-(CENTER_DEADZONE/2)) ||
        touchPoint.y > (self.view.frame.size.height/2)+(CENTER_DEADZONE/2)) {

        // Safety check
        if (calcValue > maxY) calcValue = maxY;
        if (calcValue < -maxY) calcValue = -maxY;
        
        currentValue = calcValue;
    } else {
        currentValue = 0;
    }
}

- (void) getVESCValues {
    NSData *dataToSend = [self.aVescController dataForGetValues:COMM_GET_VALUES val:0];
    NSLog(@"getVESCValues: %@", dataToSend);
    [self.bean sendSerialData:dataToSend];
}

- (void) sendCommandToBean  {
    NSData *dataToSend = nil;

    NSNumber *controlMode = [[NSUserDefaults standardUserDefaults] objectForKey:@"controlMode"];
    dataToSend = [self.aVescController dataForCommand:[controlMode intValue] val:currentValue];

    if (currentValue < 0) {
        NSNumber *reverseMode = [[NSUserDefaults standardUserDefaults] objectForKey:@"reverseMode"];
        if ([reverseMode isEqualToNumber:@(COMM_SET_CURRENT_BRAKE)]) {
            controlMode = @(COMM_SET_CURRENT_BRAKE);
            dataToSend = [self.aVescController dataForCommand:COMM_SET_CURRENT_BRAKE val:currentValue];
        }
    }
    
    NSLog(@"dataToSend: %@.  Mode %@, value %d", dataToSend, controlMode, currentValue);
    
    [self.bean sendSerialData:dataToSend];
}

// bean discovered
- (void)BeanManager:(PTDBeanManager*)beanManager didDiscoverBean:(PTDBean*)aBean error:(NSError*)error{
    if (error) {
        statusLabel.text = [error localizedDescription];
        return;
    }
    statusLabel.text = [NSString stringWithFormat:@"Bean found: %@",[aBean name]];
    [self.beanManager connectToBean:aBean error:nil];
}

// bean connected
- (void)BeanManager:(PTDBeanManager*)beanManager didConnectToBean:(PTDBean*)bean error:(NSError*)error{
    if (error) {
        statusLabel.text = [error localizedDescription];
        return;
    }
    // do stuff with your bean
    statusLabel.text = @"Bean connected!";
    self.bean = bean;
    self.bean.delegate = self;
    
    sendSerialDataTimer = [NSTimer scheduledTimerWithTimeInterval:SEND_SERIAL_DATA_INTERVAL target:self selector:@selector(sendCommandToBean) userInfo:nil repeats:YES];
}

- (void)beanManagerDidUpdateState:(PTDBeanManager *)beanManager {
    NSLog(@"Bean Manager beanManagerDidUpdateState: %lu", beanManager.state);
}

- (void)BeanManager:(PTDBeanManager*)beanManager didDisconnectBean:(PTDBean*)bean error:(NSError*)error {
    statusLabel.text = @"Bean disconnected.";
    if (sendSerialDataTimer) {
        [sendSerialDataTimer invalidate];
        sendSerialDataTimer = nil;
    }
}

- (void) disconnectBean {
    NSError *err;
    [self.beanManager disconnectBean:self.bean error:&err];
    if (err) statusLabel.text = [err localizedDescription];
}

- (void)bean:(PTDBean *)bean error:(NSError *)error {
    NSLog(@"!!!! BEAN ERROR !!!! %@", error.localizedDescription);
}

-(void)bean:(PTDBean *)bean serialDataReceived:(NSData *)data {
    NSString* newStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"Bean says: %@", newStr);
}

- (BOOL) prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
