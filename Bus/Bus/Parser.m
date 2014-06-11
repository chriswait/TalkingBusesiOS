//
//  Parser.m
//  Bus
//
//  Created by Chris on 07/06/2013.
//  Copyright (c) 2013 Chris. All rights reserved.
//

#import "Parser.h"
#import "SBJsonParser.h"
#import "URLBuilderConstants.h"
#import "RequestBuilder.h"

#define kTimeout 10.0

@implementation Parser

@synthesize jsonParser;
@synthesize serviceRequest;
@synthesize didSucceed, didTimeout, notConnected;

-(id)initWithApiType:(APIType)api service:(id<Service>)service params:(NSDictionary *)params;
{
	self = [super init];
	if (self) {
		jsonParser = [SBJsonParser new];
		serviceRequest = [[RequestBuilder sharedInstance] getRequestForAPI:api service:service params:params];
	}
	return self;
}

-(void)startRequest
{
	didSucceed = NO;
	didTimeout = NO;
	notConnected = NO;

	// Activate the network activity indicator
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

	// Prepare URL request to download data from a web service
//	NSURLRequest *request = [NSURLRequest requestWithURL:[self serviceURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:kTimeout];

	// Perform request and get JSON back as a NSData object
	NSError        *error = nil;
	NSURLResponse  *response = nil;

	NSData *responseData = [NSURLConnection sendSynchronousRequest:serviceRequest returningResponse:&response error:&error];
	NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];

	if (error) {
		if (error.domain == NSURLErrorDomain) {
			if (error.code == -1001) didTimeout = YES;
			else if (error.code == -1009) notConnected = YES;
		} else {
			NSLog(@"Parser Error: %@", error);
		}
	} else {
		didSucceed = YES;
		// Parse the response (done by the subclass)
		[self parseResponse:responseString];
	}
	// Deactivate the network activity indicator
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

-(void)parseResponse:(NSString *)response
{
}


@end