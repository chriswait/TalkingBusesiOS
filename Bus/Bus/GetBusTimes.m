//
//  GetBusTimesParser.m
//  Bus
//
//  Created by Chris on 12/06/2013.
//  Copyright (c) 2013 Chris. All rights reserved.
//

#import "GetBusTimes.h"
#import "SBJson.h"
#import "Key.h"
#define kNoDepartures @"4"
#define kNoDays @"0"

@implementation GetBusTimes
@synthesize busTimes;

-(id)initWithBusStopID:(NSString *)initBusStopID serviceRef:(NSString *)initServiceRef numberOfDays:(NSString *)initNumberOfDays
{
	NSMutableDictionary *params = [NSMutableDictionary new];
	[params setValue:initBusStopID forKey : @"stopId1"];
	[params setValue:kNoDepartures forKey:@"nb"];
	[params setValue:kNoDays forKey:@"day"];

	if (initServiceRef) [params setValue:initServiceRef forKey:@"refService1"];
	if (initNumberOfDays) [params setValue:initNumberOfDays forKey:@"day"];

	self = [super initWithApiType:MyBusTrackerAPI service:self params:params];
	if (self) {
	}
	return self;
}

-(void)parseResponse:(NSString *)response
{
	// Parse the response into a dictionary
	NSDictionary *responseDict = [jsonParser objectWithString:response];
	// Extract the array of bus time
	NSArray *responseBusTimes = [[responseDict mutableSetValueForKey:@"busTimes"] allObjects];

	// Initialise the busTimes array
	busTimes = [NSMutableArray new];
	// Check it is not empty
	if ([responseBusTimes count] == 0) return;

	// Add each bus time to our bus times
	for (NSDictionary *dict in responseBusTimes)
		[busTimes addObject:[NSMutableDictionary dictionaryWithDictionary:dict]];
}


@end
