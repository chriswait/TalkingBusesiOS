//
//  GetBusTimesParser.h
//  Bus
//
//  Created by Chris on 12/06/2013.
//  Copyright (c) 2013 Chris. All rights reserved.
//

#import "Parser.h"
#import "Service.h"
@class Stop;

@interface GetBusTimes : Parser <Service>
{
}

@property (nonatomic) NSMutableArray *busTimes;
-(id)initWithBusStopID:(NSString *)initBusStopID serviceRef:(NSString *)initServiceRef numberOfDays:(NSString *)initNumberOfDays;
@end
