//
//  VescController.h
//  BeanVESC
//
//  Created by Ben Harraway on 13/09/2015.
//  Copyright (c) 2015 Gourmet Pixel Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VescController : NSObject {
    
}

- (void) SetCurrent:(double)val;
- (void) SetRpm:(double)val;
- (void) SetDuty:(double)val;
- (void) SetBrake:(double)val;
- (void) Release;
- (void) FullBrake;
- (void) GetValues;

- (NSString *) stringForCommand:(int)command val:(double)val;
- (NSData *) dataForCommand:(int)command val:(double)val;

- (NSData *)dataForGetValues:(int)command val:(double)val;

@end
