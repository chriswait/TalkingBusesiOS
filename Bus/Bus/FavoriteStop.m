//
//  FavoriteStop.m
//  Bus
//
//  Created by Chris on 26/01/2014.
//  Copyright (c) 2014 Chris. All rights reserved.
//

#import "FavoriteStop.h"

@implementation FavoriteStop

@dynamic favorite_name;

-(void)setStop:(Stop *)stop
{
	self.stopId = stop.stopId;
	self.name = stop.name;
	self.x = stop.x;
	self.y = stop.y;
	self.street = stop.street;
	self.heading = stop.heading;
	self.serviceMnemos = stop.serviceMnemos;
}

@end
