//
//  Stop.h
//  Bus
//
//  Created by Chris on 26/01/2014.
//  Copyright (c) 2014 Chris. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface Stop : NSManagedObject

@property (nonatomic, retain) NSString *heading;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *stopId;
@property (nonatomic, retain) NSString *street;
@property (nonatomic, retain) NSNumber *x;
@property (nonatomic, retain) NSNumber *y;
@property (nonatomic, retain) NSNumber *distance;
@property (nonatomic, retain) NSNumber *eta;
@property (nonatomic, retain) NSString *serviceMnemos;

-(void)setStop_dict:(NSDictionary *)stop_dict;

@end
