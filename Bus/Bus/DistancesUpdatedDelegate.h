//
//  DistancesUpdatedDelegate.h
//  Bus
//
//  Created by Chris on 26/02/2014.
//  Copyright (c) 2014 Chris. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DistancesUpdatedDelegate : NSObject
@end

@protocol DistancesUpdatedDelegate
-(void)distancesUpdated;
@end
