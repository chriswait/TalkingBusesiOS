//
//  GetBusStopsParser.m
//  Bus
//
//  Created by Chris on 07/06/2013.
//  Copyright (c) 2013 Chris. All rights reserved.
//

#import "GetBusStops.h"
#import "SBJson.h"
#import "StopDataModel.h"

@implementation GetBusStops

@dynamic jsonParser;
@synthesize stops;

-(id)init
{
	// Initialise the parser with the get stops url
	self = [super initWithApiType:TalkingBusesAPI service:self params:nil];

	if (self) {
	}

	return self;
}

-(void)parseResponse:(NSString *)response
{
	// Create an array of the json dictionaries
	stops = [jsonParser objectWithString:response];
}

@end
