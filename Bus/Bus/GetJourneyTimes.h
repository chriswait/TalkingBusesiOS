//
//  GetJourneyTimesParser.h
//  Bus
//
//  Created by Chris on 20/11/2013.
//  Copyright (c) 2013 Chris. All rights reserved.
//

#import "Parser.h"
#import "Service.h"

@class LocationManager;
@interface GetJourneyTimes : Parser <Service>
{
	LocationManager *locationManager;
	NSString *busStopID;
	NSString *journeyID;
}
@property (nonatomic) NSMutableArray *nextBusStops;
-(id)initWithBusStopID:(NSString *)initBusStopID journeyID:(NSString *)initJourneyID;

@end
