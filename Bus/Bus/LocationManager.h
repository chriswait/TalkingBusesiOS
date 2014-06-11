//
//  LocationManager.h
//  Bus
//
//  Created by Chris on 10/06/2013.
//  Copyright (c) 2013 Chris. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <AudioToolbox/AudioServices.h>
@class StopDataModel;

@interface LocationManager : NSObject <CLLocationManagerDelegate>
{
	CLLocationManager *locationManager;
	NSMutableArray *locationsFIFOQueue;
	int desiredLocationsListLength;
}

@property (nonatomic, retain) StopDataModel *stopDataModelDelegate;
@property (nonatomic, retain) CLLocation *averageLocation;

+(LocationManager *)sharedInstance;
-(void)purgeOldPoint;
-(void)addLocations:(NSArray *)newLocations;
-(void)updateAverageLocation;

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation;
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;

@end