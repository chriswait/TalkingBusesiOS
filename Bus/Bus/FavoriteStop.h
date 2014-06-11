//
//  FavoriteStop.h
//  Bus
//
//  Created by Chris on 26/01/2014.
//  Copyright (c) 2014 Chris. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Stop.h"

@interface FavoriteStop : Stop

@property (nonatomic, retain) NSString * favorite_name;
-(void)setStop:(Stop *)stop;

@end
