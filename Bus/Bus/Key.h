//
//  Key.h
//  Bus
//
//  Created by Chris on 12/06/2013.
//  Copyright (c) 2013 Chris. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Key : NSObject

+(NSString *)getCurrentKey;
+(NSString *)md5:(NSString *)input;

@end
