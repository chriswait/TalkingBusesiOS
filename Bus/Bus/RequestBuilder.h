//
//  URLBuilder.h
//  Bus
//
//  Created by Chris on 09/06/2014.
//  Copyright (c) 2014 Chris. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Service.h"

@interface RequestBuilder : NSObject

@property (nonatomic, strong) NSDictionary *contentURLsResource;
-(NSURLRequest *)getRequestForAPI:(APIType)api service:(id<Service>)service params:(NSDictionary *)params;
+(RequestBuilder *)sharedInstance;
@end
