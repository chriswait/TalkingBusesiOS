//
//  GetJourneyTimesParser.m
//  Bus
//
//  Created by Chris on 20/11/2013.
//  Copyright (c) 2013 Chris. All rights reserved.
//

#import "GetJourneyTimes.h"
#import "Key.h"
#import "SBJson.h"
#import "LocationManager.h"
#import "StopDataModel.h"
#import "Stop.h"

@implementation GetJourneyTimes
@synthesize nextBusStops;

-(id)initWithBusStopID:(NSString *)initBusStopID journeyID:(NSString *)initJourneyID
{
	NSDictionary *params = @{@"stopId":initBusStopID, @"journeyId":initJourneyID};

	// Initialise the parser with the get stops url
	self = [super initWithApiType:MyBusTrackerAPI service:self params:params];
	if (self) {
	}
	return self;
}

-(void)parseResponse:(NSString *)response
{

	// Get the list of journeyTimeDatas from the JSON response
	NSDictionary *responseDict = [jsonParser objectWithString:response];
	NSDictionary *firstJourneyTime = [[responseDict valueForKey:@"journeyTimes"] firstObject];
	NSArray *journeyTimeDatas = [firstJourneyTime valueForKey:@"journeyTimeDatas"];

	// clear the current nextBusStops
	nextBusStops = [NSMutableArray new];
	int firstStopMinutes = -1;

	// For each bus stop in the journey
	for (NSDictionary *journeyTimeData in journeyTimeDatas) {
		int minutes = (int)[[journeyTimeData valueForKey:@"minutes"] integerValue];

		// If minutes is -1, the bus has already passed this stop
		if (minutes == -1) { // We can ignore it
		} else {
			// If the bus hasn't reached our url stop ID yet:
			// We must correct the ETAs
			if (firstStopMinutes == -1) { // If this is the next stop
				// Store the number of minutes until this stop is reached
				firstStopMinutes = minutes;
			} else {
				// Use our stored firstETA to calculate the actual eta for this stop
				minutes += firstStopMinutes;
			}

			// Get the bus stop dictionary for this stop
			Stop *busStop = [[StopDataModel sharedInstance] getStopWithStopID:[journeyTimeData valueForKey:@"stopId"]];
			if (busStop) {
				busStop.eta = [NSNumber numberWithInt:minutes];
				[self.nextBusStops addObject:busStop];
			} else {
				NSLog(@"FAILED TO FIND STOP WITH stopID: %@", [journeyTimeData valueForKey:@"stopId"]);
			}
		}
	}
}

@end
