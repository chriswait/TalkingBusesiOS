//
//  LocationManager.m
//  Bus
//
//  Created by Chris on 10/06/2013.
//  Copyright (c) 2013 Chris. All rights reserved.
//

#import "LocationManager.h"
#import "StopDataModel.h"
#define kAcceptableAccuracy 80
#define kNumberOfLocationsAveragedWalking 10
#define kNumberOfLocationsAveragedBus 5

@implementation LocationManager
static LocationManager *_sharedInstance;
@synthesize stopDataModelDelegate;
@synthesize averageLocation;

-(id)init
{
	self = [super init];

	if (self) {
		// Initialise the location manager
		locationManager = [CLLocationManager new];
		locationManager.delegate = self;
//        [locationManager setDesiredAccuracy:kCLLocationAccuracyBest];

		desiredLocationsListLength = kNumberOfLocationsAveragedWalking;
		locationsFIFOQueue = [[NSMutableArray alloc] initWithCapacity:desiredLocationsListLength];
		averageLocation = nil;

		// Start getting location updates
		[locationManager startUpdatingLocation];

		// Start a timer to purge old points
		[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(purgeOldPoint) userInfo:nil repeats:YES];
	}

	return self;
}

+(LocationManager *)sharedInstance
{
	if (!_sharedInstance) {
		_sharedInstance = [LocationManager new];
	}
	return _sharedInstance;
}

-(void)purgeOldPoint
{
	// If we have multiple points
	if ([locationsFIFOQueue count] > 1) {
		// SPECIAL CASE:
		// If we have exactly 2 left
		if ([locationsFIFOQueue count] == 2) {
			// We only want to remove the older one if it's less accurate or nor recent
			CLLocation *old = [locationsFIFOQueue objectAtIndex:0];
			CLLocation *new = [locationsFIFOQueue objectAtIndex:1];
			BOOL lessAccurate = old.horizontalAccuracy > new.horizontalAccuracy;
			BOOL notRecent = [old.timestamp timeIntervalSinceDate:new.timestamp] > 10.0;
			if (lessAccurate || notRecent) {
				[locationsFIFOQueue removeObjectAtIndex:0];
			}
		} else {
			// Remove oldest location
			[locationsFIFOQueue removeObjectAtIndex:0];
		}
	}
}

-(void)addLocations:(NSArray *)newLocations
{
	// The newest locations are at the end of the list
	[locationsFIFOQueue addObjectsFromArray:newLocations];
	for (CLLocation *location in newLocations) {
		if (location.horizontalAccuracy < kAcceptableAccuracy)
			[locationsFIFOQueue addObject:location];
	}
	while ([locationsFIFOQueue count] > desiredLocationsListLength) {
		// Trim the list, removing oldest locations
		[locationsFIFOQueue removeObjectAtIndex:0];
	}
}


-(void)updateAverageLocation
{

	double latitudeSum = 0.0;
	double longitudeSum = 0.0;
	double accuracySum = 0.0;

	for (CLLocation *location in locationsFIFOQueue) {
		latitudeSum += location.coordinate.latitude;
		longitudeSum += location.coordinate.longitude;
		accuracySum += location.horizontalAccuracy;
	}

	// Average the lat, long and accuracy
	double latitude = latitudeSum / [locationsFIFOQueue count];
	double longitude = longitudeSum / [locationsFIFOQueue count];
	double accuracy = accuracySum / [locationsFIFOQueue count];

	// Take the last speed and course
	double speed = [(CLLocation *)[locationsFIFOQueue lastObject] speed];
	double course = [(CLLocation *)[locationsFIFOQueue lastObject] course];

	// While we're at it, adjust the list size for current speed
	if (speed > 5) desiredLocationsListLength = kNumberOfLocationsAveragedBus;
	else desiredLocationsListLength = kNumberOfLocationsAveragedWalking;

	averageLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude) altitude:0 horizontalAccuracy:accuracy verticalAccuracy:0 course:course speed:speed timestamp:[NSDate date]];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{

	// Add the new locations to our list
	[self addLocations:locations];

	// Get the average location and pdate our stored current location
	[self updateAverageLocation];

	if ([[StopDataModel sharedInstance] shouldUpdateDistancesWithLocation:averageLocation]) {
		[[StopDataModel sharedInstance] updateFavoriteBusStopDistancesWithLocation:averageLocation];
		[[StopDataModel sharedInstance] updateBusStopDistancesWithLocation:averageLocation];
		[[StopDataModel sharedInstance] updateSearchBusStopDistancesWithLocation:averageLocation];

		// Update the last update details
		[[StopDataModel sharedInstance] setLastUpdatedLocation:averageLocation];
	}
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
}

@end
