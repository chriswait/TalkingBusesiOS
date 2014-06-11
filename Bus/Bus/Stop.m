//
//  Stop.m
//  Bus
//
//  Created by Chris on 26/01/2014.
//  Copyright (c) 2014 Chris. All rights reserved.
//

#import "Stop.h"


@implementation Stop

@dynamic heading;
@dynamic name;
@dynamic stopId;
@dynamic street;
@dynamic x;
@dynamic y;
@dynamic distance;
@dynamic eta;
@dynamic serviceMnemos;

-(id)initWithEntity:(NSEntityDescription *)entity insertIntoManagedObjectContext:(NSManagedObjectContext *)context
{
    if (self = [super initWithEntity:entity insertIntoManagedObjectContext:context]) {
        [self setDistance:[NSNumber numberWithDouble:MAXFLOAT]];
    }
    return self;
}

-(void)setStop_dict:(NSDictionary *)stop_dict
{
    [self setStopId:[stop_dict valueForKey:@"stopId"]];
    [self setName:[stop_dict valueForKey:@"name"]];
    [self setHeading:[stop_dict valueForKey:@"heading"]];
    [self setStreet:[stop_dict valueForKey:@"street"]];
    [self setX:[stop_dict valueForKey:@"x"]];
    [self setY:[stop_dict valueForKey:@"y"]];
    [self setStreet:[stop_dict valueForKey:@"street"]];
    [self setServiceMnemos:[stop_dict valueForKey:@"service_mnemos"]];
}

@end
