//
//  Key.m
//  Bus
//
//  Created by Chris on 12/06/2013.
//  Copyright (c) 2013 Chris. All rights reserved.
//

#import "Key.h"
#import <CommonCrypto/CommonDigest.h>
#define kBustrackerAPIKey @"XILE2BXT513X9D4ESWL39JLNA"


@implementation Key

+(NSString *)getCurrentKey
{
	// Get the required string representation of the current date/time
	NSDate *now = [NSDate date];
	NSDateFormatter *formatter = [NSDateFormatter new];
	[formatter setDateFormat:@"yyyyMMddHH"];
	NSString *dateString = [formatter stringFromDate:now];

	// Add the bustracker API key and hash using md5
	NSString *key = [NSString stringWithFormat:@"%@%@", kBustrackerAPIKey, dateString];
	NSString *hashedKey = [self md5:key];

	// Return the hashed key
	return hashedKey;
}

// Used to hash with md5, credit to http://stackoverflow.com/a/7632207
+(NSString *)md5:(NSString *)input
{
	const char *cStr = [input UTF8String];
	unsigned char digest[16];
	CC_MD5( cStr, (int)strlen(cStr), digest ); // This is the md5 call

	NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];

	for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
		[output appendFormat:@"%02x", digest[i]];

	return output;
}

@end
