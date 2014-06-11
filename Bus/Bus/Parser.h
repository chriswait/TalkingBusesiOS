//
//  Parser.h
//  Bus
//
//  Created by Chris on 07/06/2013.
//  Copyright (c) 2013 Chris. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Service.h"
@class SBJsonParser;

@interface Parser : NSObject <NSURLConnectionDelegate>
{
	SBJsonParser *jsonParser;
	NSMutableData *connectionData;
}

@property (nonatomic) NSURLRequest *serviceRequest;
@property SBJsonParser *jsonParser;
@property BOOL didSucceed;
@property BOOL didTimeout;
@property BOOL notConnected;


-(id)initWithApiType:(APIType)api service:(id<Service>)service params:(NSDictionary *)params;
-(void)startRequest;
-(void)parseResponse:(NSString *)response;

@end
