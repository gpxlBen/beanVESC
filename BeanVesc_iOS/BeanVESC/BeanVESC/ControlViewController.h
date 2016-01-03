//
//  ViewController.h
//  BeanVESC
//
//  Created by Ben Harraway on 03/09/2015.
//  Copyright (c) 2015 Gourmet Pixel Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GradientView.h"

#import "PTDBean.h"
#import "PTDBeanManager.h"
#import "PTDBeanRadioConfig.h"

#import "VescController.h"

@interface ControlViewController : UIViewController <PTDBeanDelegate, PTDBeanManagerDelegate> {
    UILabel *statusLabel;
    
    GradientView *aGradientView;
    
    NSTimer *sendSerialDataTimer;
    int currentValue;
    
    NSMutableData *recievingData;
}

@property (nonatomic, retain) VescController *aVescController;

@property (nonatomic, retain) PTDBean *bean;
@property (nonatomic, retain) PTDBeanManager *beanManager;


@end

