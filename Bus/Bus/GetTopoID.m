//
//  GetTopoIDParser.m
//  Bus
//
//  Created by Chris on 19/11/2013.
//  Copyright (c) 2013 Chris. All rights reserved.
//

#import "GetTopoID.h"


@implementation GetTopoID
@synthesize topoID;
@dynamic jsonParser;

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
	topoID = response;
}


@end
