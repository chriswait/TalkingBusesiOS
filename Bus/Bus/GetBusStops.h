//
//  GetBusStopsParser.h
//  Bus
//
//  Created by Chris on 07/06/2013.
//  Copyright (c) 2013 Chris. All rights reserved.
//

#import "Parser.h"
#import "Service.h"
@class StopDataModel;

@interface GetBusStops : Parser <Service>
{
}

@property (nonatomic) NSArray *stops;

-(id)init;

@end
