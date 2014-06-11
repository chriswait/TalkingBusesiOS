//
//  URLBuilder.m
//  Bus
//
//  Created by Chris on 09/06/2014.
//  Copyright (c) 2014 Chris. All rights reserved.
//

#import "RequestBuilder.h"
#import "URLBuilderConstants.h"
#import "Service.h"
#import "Key.h"
#define kRequestTimeout 10.0

@implementation RequestBuilder
@synthesize contentURLsResource;
static RequestBuilder *_sharedInstance;

-(id)init
{
	self = [super init];
	if (self) {
		[self loadServiceURLsResource];
	}
	return self;
}

+(RequestBuilder *)sharedInstance
{
	if (!_sharedInstance) {
		_sharedInstance = [RequestBuilder new];
	}
	return _sharedInstance;

}

-(void)loadServiceURLsResource
{
	NSString *serviceURLsResourcePath = [[NSBundle mainBundle] pathForResource:@"ServiceURLs" ofType:@"plist"];
	[self setContentURLsResource:[NSDictionary dictionaryWithContentsOfFile:serviceURLsResourcePath]];
}

-(NSURLRequest *)getRequestForAPI:(APIType)api service:(id<Service>)service params:(NSDictionary *)params
{
	NSMutableURLRequest *theRequest = [NSMutableURLRequest new];
	[theRequest setHTTPMethod:@"GET"];
	[theRequest setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
	[theRequest setTimeoutInterval:kRequestTimeout];

	NSString *serviceName = [[service class] description];
	NSMutableDictionary *allParams = [NSMutableDictionary new];

	NSString *hostname;
	NSString *pathKey;
	NSMutableString *urlString;

	if (api == TalkingBusesAPI) {
		// Build the URL
		hostname = [contentURLsResource valueForKey:kTBHostnameKey];
		urlString = [hostname mutableCopy];
		pathKey = [serviceName stringByAppendingString:kServiceSuffix];
		NSString *servicePath = [contentURLsResource valueForKey:pathKey];
		[urlString appendString:[NSString stringWithFormat:@"/%@",servicePath]];
	} else if (api == MyBusTrackerAPI) {
		// Build the URL
		hostname = [contentURLsResource valueForKey:kMBTHostnameKey];
		urlString = [hostname mutableCopy];
		[urlString appendString:@"/"];

		// Add parameters
		// Function name
		pathKey = [serviceName stringByAppendingString:kFunctionSuffix];
		NSString *module = [contentURLsResource valueForKeyPath:kMBTModuleKey];
		[allParams setValue:module forKey:@"module"];

		// Module i.e format
		NSString *function = [contentURLsResource valueForKeyPath:pathKey];
		[allParams setValue:function forKey:@"function"];

		// API Key
		NSString *key = [Key getCurrentKey];
		[allParams setValue:key forKeyPath:@"key"];

		[allParams setValuesForKeysWithDictionary:params];

//		NSData *bodyData = [self generateBodyForParams:allParams];
//		NSString *bodyLength = [NSString stringWithFormat:@"%i", (int)bodyData.length];
//		[theRequest setValue:bodyLength forHTTPHeaderField:@"Content-Length"];
//		[theRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];

//		[theRequest setHTTPBody:bodyData];
//		[theRequest setHTTPMethod:@"POST"];
		[urlString appendString:[self generateBodyForParams:allParams]];
	}

	[theRequest setURL:[NSURL URLWithString:urlString]];

	return theRequest;
}

-(NSString *) generateBodyForParams:(NSDictionary *)params
{
	NSMutableString *bodyString = [NSMutableString new];
	NSEnumerator *keyEnumerator = [params keyEnumerator];
	NSString *prefix;
	NSString *key;
	NSString *value;
	while (key = [keyEnumerator nextObject]) {
		if (!prefix) prefix = @"?";
		else prefix = @"&";
		value = [params valueForKey:key];
		[bodyString appendString:[NSString stringWithFormat:@"%@%@=%@", prefix, key, value]];
	}
//	bodyString = [[bodyString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] mutableCopy];
//	return [bodyString dataUsingEncoding:NSUTF8StringEncoding];
	return bodyString;
}


@end
