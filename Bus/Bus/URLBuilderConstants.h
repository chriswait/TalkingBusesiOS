//
//  URLBuilderConstants.h
//  Bus
//
//  Created by Chris on 09/06/2014.
//  Copyright (c) 2014 Chris. All rights reserved.
//

#ifndef Bus_URLBuilderConstants_h
#define Bus_URLBuilderConstants_h

/*
   API and corresponding hostnames
 */

typedef enum
{
	TalkingBusesAPI,
	MyBusTrackerAPI

} APIType;

static NSString *const kTBHostnameKey = @"TB_Hostname";
static NSString *const kMBTHostnameKey = @"MBT_Hostname";


static NSString *const kMBTModuleKey = @"MBT_Module";

static NSString *const kServiceSuffix = @"Service";
static NSString *const kFunctionSuffix = @"Function";

#endif
