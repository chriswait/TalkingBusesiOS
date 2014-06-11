//
//  GetTopoIDParser.h
//  Bus
//
//  Created by Chris on 19/11/2013.
//  Copyright (c) 2013 Chris. All rights reserved.
//

#import "Parser.h"
#import "Service.h"

@interface GetTopoID : Parser <Service>

@property (nonatomic) NSString *topoID;
-(id)init;

@end
