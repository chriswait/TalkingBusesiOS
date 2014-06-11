//
//  StopDataModel.m
//  Bus
//
//  Created by Chris on 10/06/2013.
//  Copyright (c) 2013 Chris. All rights reserved.
//

#import "StopDataModel.h"
#import "LocationManager.h"
#import "GetTopoID.h"
#import "GetBusStops.h"
#import "LocationManager.h"
#import "WalkViewController.h"
#import "FavoriteStopsViewController.h"
#import "SearchViewController.h"
#import "Stop.h"
#import "FavoriteStop.h"
#import "Info.h"

#define kFavoriteStopsDataFilename @"favoriteStopData.plist"
#define kTopoIDFilename @"topoID.plist"

#define kNumberOfNearbyStops 8

@implementation StopDataModel

static StopDataModel *_sharedInstance;
@synthesize managedObjectContext;
@synthesize currentUpdateDelegate;
@synthesize nearbyBusStops;
@synthesize nearbyFavoriteBusStops;
@synthesize currentSearchStops;
@synthesize hasBusStops;
@synthesize lastUpdatedLocation;

+(StopDataModel *)sharedInstance
{
	if (!_sharedInstance)
		_sharedInstance = [StopDataModel new];
	return _sharedInstance;
}

-(id) init
{
	self = [super init];
	if (self) {
		// Register as the location manager's delegate so we load nearby stops when we have a location
		[[LocationManager sharedInstance] setStopDataModelDelegate:self];
		hasBusStops = NO;
		busStops = nil;
		currentSearchStops = [NSArray new];
	}
	return self;
}

-(Info *)getCurrentInfo
{
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Info" inManagedObjectContext:[self managedObjectContext]];
	NSFetchRequest *request = [NSFetchRequest new];
	[request setEntity:entity];
	[request setIncludesSubentities:NO];
	NSError *error;
	NSMutableArray *fetchResults = [[[self managedObjectContext] executeFetchRequest:request error:&error] mutableCopy];
	if (!fetchResults) {
		// Error message
		NSLog(@"Fetch error");
		return nil;
	}
	Info *info = [fetchResults firstObject];
	return info;
}

-(NSString *)getTopoID
{
	Info *currentInfo = [self getCurrentInfo];
	if (currentInfo) return currentInfo.topoID;
	else return nil;
}

-(void)storeNewTopoID:(NSString *)newTopoID
{
	Info *currentInfo = [self getCurrentInfo];
	// If we don't already have an Info
	if (!currentInfo)
		currentInfo = (Info *)[NSEntityDescription insertNewObjectForEntityForName:@"Info" inManagedObjectContext:[self managedObjectContext]];
	currentInfo.topoID = newTopoID;
	NSError *error;
	if (![[self managedObjectContext] save:&error]) {
		// Handle error
		NSLog(@"Save error");
	}
}

-(void)checkForUpdate
{
	// check our local topo ID against the one on the server
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
	        // Initialise the stop parser
	        GetTopoID *parser = [GetTopoID new];
	        [parser startRequest];
	        dispatch_async(dispatch_get_main_queue(), ^{
	            if ([parser didSucceed]) {

	                NSString *newTopoID = parser.topoID;
	                NSString *currentTopoID = [self getTopoID];

	                // If we don't have a current topo ID, or it's old
	                if (!currentTopoID || ![newTopoID isEqualToString:currentTopoID]) {
	                    // Download new bus stops
	                    [self downloadNewStopsWithNewTopoID:newTopoID];
					} else {
	                    // Otherwise, update distances
	                    hasBusStops = YES;
	                    [self updateBusStopDistancesWithLocation:nil];
	                    [self displayClosestStops];
					}

				} else {
	                if ([parser didTimeout]) {
	                    UIAlertView *timeoutAlert = [[UIAlertView alloc] initWithTitle:@"Could not download bus stop database" message:@"Request timed out, please retry" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
	                    [timeoutAlert show];
					} else if ([parser notConnected]) {
	                    UIAlertView *connectionAlert = [[UIAlertView alloc] initWithTitle:@"Could not download bus stop database" message:@"Connection failed, please check internet connection and retry" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
	                    [connectionAlert show];
					}
	                // We didn't manage to load the TOPO ID, so we don't know if we need to update
	                // We should load the stops anyway
	                hasBusStops = YES;
	                [self updateBusStopDistancesWithLocation:nil];
	                [self displayClosestStops];
				}
			});
		});
}

-(void)downloadNewStopsWithNewTopoID:(NSString *)topoID
{
	NSLog(@"Downloading bus stops");
	// Start a thread to load the stops
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
	        // Initialise the stop parser
	        GetBusStops *parser = [GetBusStops new];
	        [parser startRequest];
	        dispatch_async(dispatch_get_main_queue(), ^{
	            if ([parser didSucceed]) {
	                NSLog(@"%i stops downloaded", (int)[[parser stops] count]);

	                // Add the new stops to the database
	                [self populateStopsWithDictionaries:[parser stops]];

	                // Update topo ID and write to file
	                [self storeNewTopoID:topoID];

	                // Update distances
	                hasBusStops = YES;
	                [self updateBusStopDistancesWithLocation:nil];
	                [self displayClosestStops];

				} else if ([parser didTimeout]) {
	                UIAlertView *timeoutAlert = [[UIAlertView alloc] initWithTitle:@"Could not load bus times" message:@"Request timed out, please retry" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
	                [timeoutAlert show];
				} else if ([parser notConnected]) {
	                UIAlertView *connectionAlert = [[UIAlertView alloc] initWithTitle:@"Could not load bus times" message:@"Connection failed, please check internet connection and retry" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
	                [connectionAlert show];
				}
			});
		});
}

-(BOOL)checkForStops
{
	NSFetchRequest *request = [NSFetchRequest new];
	[request setEntity:[NSEntityDescription entityForName:@"Stop" inManagedObjectContext:[self managedObjectContext]]];
	[request setIncludesSubentities:NO];
	NSError *err;
	NSUInteger count = [[self managedObjectContext] countForFetchRequest:request error:&err];
	NSLog(@"Checking for stops, %i found", (int)count);
	return (count != 0);
}

-(NSArray *)getBusStops
{
	if (busStops && [busStops count] > 0) return busStops;
	else {
		[self loadBusStopsFromDatabase];
		return busStops;
	}
}

-(void)loadBusStopsFromDatabase;
{
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Stop" inManagedObjectContext:[self managedObjectContext]];
	NSFetchRequest *request = [NSFetchRequest new];
	[request setEntity:entity];
	[request setIncludesSubentities:NO];
	NSError *error;
	NSMutableArray *fetchResults = [[[self managedObjectContext] executeFetchRequest:request error:&error] mutableCopy];
	if (!fetchResults) {
		// Error message
		NSLog(@"Fetch error");
		return;
	}
	busStops = fetchResults;
}

-(NSArray *)getFavoriteBusStops
{
	if (favoriteStops && [favoriteStops count] > 0) return favoriteStops;
	else {
		[self loadFavoriteBusStopsFromDatabase];
		return favoriteStops;
	}
}
-(void)loadFavoriteBusStopsFromDatabase
{
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"FavoriteStop" inManagedObjectContext:[self managedObjectContext]];
	NSFetchRequest *request = [NSFetchRequest new];
	[request setEntity:entity];

	NSError *error;
	NSMutableArray *fetchResults = [[[self managedObjectContext] executeFetchRequest:request error:&error] mutableCopy];
	if (!fetchResults) {
		// Error message
		NSLog(@"Fetch error");
		return;
	}
	favoriteStops = fetchResults;
}

-(void)populateStopsWithDictionaries:(NSArray *)stop_dicts
{
	// Clear the database
	[self clearStopsDatabase];
	// Store each stop
	for (NSDictionary *stop_dict in stop_dicts) {
		Stop *stop = (Stop *)[NSEntityDescription insertNewObjectForEntityForName:@"Stop" inManagedObjectContext:[self managedObjectContext]];
		[stop setStop_dict:stop_dict];
	}
	NSError *error;
	if (![[self managedObjectContext] save:&error]) {
		// Handle error
		NSLog(@"Save error");
	}
}

-(void)clearStopsDatabase
{
	NSFetchRequest *allStops = [NSFetchRequest new];
	[allStops setEntity:[NSEntityDescription entityForName:@"Stop" inManagedObjectContext:[self managedObjectContext]]];

	NSError *fetchError = nil;
	NSArray *stops = [[self managedObjectContext] executeFetchRequest:allStops error:&fetchError];
	for (NSManagedObject *stop in stops) {
		[[self managedObjectContext] deleteObject:stop];
	}
	NSError *saveError = nil;
	[[self managedObjectContext] save:&saveError];
}

-(void)addStopToFavorites:(Stop *)newFavoriteStop withName:(NSString *)name
{
	FavoriteStop *favoriteStop = [NSEntityDescription insertNewObjectForEntityForName:@"FavoriteStop" inManagedObjectContext:[self managedObjectContext]];
	[favoriteStop setStop:newFavoriteStop];
	[favoriteStop setFavorite_name:name];
	NSError *error;
	if (![[self managedObjectContext] save:&error]) {
		// Handle error
		NSLog(@"Save error");
	}
	[self updateFavoriteBusStopDistancesWithLocation:[[LocationManager sharedInstance] averageLocation]];
}

-(void)displayClosestStops {
	[currentUpdateDelegate distancesUpdated];
}

-(Stop *)getStopWithStopID:(NSString *)stopID
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"stopId == %@", stopID];
	NSArray *results = [busStops filteredArrayUsingPredicate:predicate];
	return [results firstObject];
}

-(NSArray *)getStopsWithName:(NSString *)search_query
{
	if ([search_query isEqualToString:@""]) {
		currentSearchStops = [NSArray new];
		return nil;
	}
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(name CONTAINS[cd] %@) OR (street CONTAINS[cd] %@)", search_query, search_query];
	NSArray *stops = [busStops filteredArrayUsingPredicate:predicate];
	// Ensure found stops have distances:
	stops = [self updateDistancesForStops:stops withLocation:[[LocationManager sharedInstance] averageLocation] usingBoxing:NO];
	stops = [self getNearbyStopsFromStops:stops numberOfStops:NSIntegerMax]; // Sort by distance
	currentSearchStops = stops; // Store
	return stops;
}

-(void)removeFavoriteStop:(FavoriteStop *)favorite_stop
{
	[nearbyFavoriteBusStops removeObject:favorite_stop];
	[[self managedObjectContext] deleteObject:favorite_stop];
	NSError *error;
	if (![[self managedObjectContext] save:&error])
		NSLog(@"Save error: %@", error);
}

-(NSArray *)getNearbyStopsFromStops:(NSArray *)theStops numberOfStops:(NSInteger)numberOfStops
{
	// Creating a sorting descriptor
	NSSortDescriptor *distDescriptor = [[NSSortDescriptor alloc] initWithKey:@"distance" ascending:YES];
	NSArray *descriptors = [NSArray arrayWithObjects:distDescriptor, nil];
	// Sort the close stops
	NSArray *sortedStops = [theStops sortedArrayUsingDescriptors:descriptors];
	if ([sortedStops count] >= numberOfStops) {
		// Slice the closest kNumberOfNearbyStops
		sortedStops = [sortedStops subarrayWithRange:NSMakeRange(0, numberOfStops)];
	}
	return sortedStops;
}

-(BOOL)shouldUpdateDistancesWithLocation:(CLLocation *)location
{

	double timeSinceLastUpdate = MAXFLOAT;
	if (lastUpdatedLocation)
		timeSinceLastUpdate = [[NSDate date] timeIntervalSinceDate:lastUpdatedLocation.timestamp];

//    double accuracy = location.horizontalAccuracy;
	double speed = location.speed;
	double distance = -1;
	if (lastUpdatedLocation)
		distance = [lastUpdatedLocation distanceFromLocation:location];

//    NSLog(@"%f,%f - Distance: %f, Accuracy: %f, Speed: %f, Last update: %f",location.coordinate.latitude, location.coordinate.longitude, distance, accuracy, speed, timeSinceLastUpdate);

	// If it's been less than N seconds we shouldn't update
	if (timeSinceLastUpdate < 10) {
		// But we should schedule an update for this location at the 10 second mark
//            double timeUntilNextUpdate = 11-timeSinceLastUpdate;
//            [self performSelector:@selector(updateBusStopDistancesWithLocation:) withObject:location afterDelay:timeUntilNextUpdate];
		return NO;
	}

	// If we don't have bus stops we shoudn't update
	if (!hasBusStops) return NO;

	// If we don't have a location we shouldn't update
	if (!location) return NO;

	// If we haven't updated before we should update
	if (!lastUpdatedLocation) return YES;

	// If the accuracy is terrible we shouldn't update
//    if (accuracy > 80) return NO;

	// If the speed if greater than x m/s we should update
	if (speed > 0 || distance > 0) return YES;

	return YES;
}

-(NSArray *)updateDistancesForStops:(NSArray *)stops withLocation:(CLLocation *) location usingBoxing:(BOOL)boxing
{
	NSDate *startUpdate = [NSDate date];
	int updated = 0;
	double currentDistance;

	// For each stop
	for (Stop *stop in stops) {
		if (!boxing || (fabs([stop.x doubleValue] - location.coordinate.latitude) < 0.05 &&
		    fabs([stop.y doubleValue] - location.coordinate.longitude) < 0.05)) {
			currentDistance = [location distanceFromLocation:[[CLLocation alloc] initWithLatitude:[stop.x doubleValue] longitude:[stop.y doubleValue]]];
			stop.distance = [NSNumber numberWithDouble:currentDistance];
			updated += 1;
		}
	}

	NSLog(@"Updating %i/%i stops took: %f seconds", updated, (int)[stops count], [[NSDate date]timeIntervalSinceDate:startUpdate]);
	return stops;
}

-(void)updateBusStopDistancesWithLocation:(CLLocation *)location
{
	if (!location) location = [[LocationManager sharedInstance] averageLocation]; // Ensure we have a location
	if (!location) return; // Can't update without a location
	NSLog(@"Updating stop distances");

	// Update stop distances and nearby stops
	[self updateDistancesForStops:[self getBusStops] withLocation:location usingBoxing:YES];
	nearbyBusStops = [self getNearbyStopsFromStops:[self getBusStops] numberOfStops:kNumberOfNearbyStops];

	NSLog(@"%i nearby stops", (int)[nearbyBusStops count]);
//   if (currentUpdateDelegate && [(DistancesUpdatedDelegate*) currentUpdateDelegate class] == [WalkViewController class])
//        [currentUpdateDelegate distancesUpdated];
}

-(void)updateFavoriteBusStopDistancesWithLocation:(CLLocation *)location
{
	if (!location) location = [[LocationManager sharedInstance] averageLocation]; // Ensure we have a location
	if (!location) return; // Can't update without a location
	NSArray *favorites = [self getFavoriteBusStops];
	if ([favorites count] == 0) return;

	favorites = [self updateDistancesForStops:favorites withLocation:location usingBoxing:NO]; // Update the distances
	favorites = [self getNearbyStopsFromStops:favorites numberOfStops:NSIntegerMax]; // Sort

	nearbyFavoriteBusStops = [NSMutableArray arrayWithArray:favorites];
	NSLog(@"%i nearby favorite stops", (int)[nearbyFavoriteBusStops count]);
//    if (currentUpdateDelegate && [(DistancesUpdatedDelegate*) currentUpdateDelegate class] == [FavoriteStopsViewController class])
//        [currentUpdateDelegate distancesUpdated];
}

-(void)updateSearchBusStopDistancesWithLocation:(CLLocation *)location
{
	if (!location) location = [[LocationManager sharedInstance] averageLocation]; // Ensure we have a location
	if (!location) return; // Can't update without a location
	if (!currentSearchStops || [currentSearchStops count] == 0) return; // If we dont have a current search, return
	// Update the distances
	currentSearchStops = [self updateDistancesForStops:[self currentSearchStops] withLocation:location usingBoxing:NO];
	currentSearchStops = [NSMutableArray arrayWithArray:[self getNearbyStopsFromStops:[self currentSearchStops] numberOfStops:NSIntegerMax]];
	NSLog(@"%i nearby search stops", (int)[currentSearchStops count]);
//    if (currentUpdateDelegate && [(DistancesUpdatedDelegate *) currentUpdateDelegate class] == [SearchViewController class])
//        [currentUpdateDelegate distancesUpdated];
}

-(void)setCurrentUpdateDelegate:(id<DistancesUpdatedDelegate>)newUpdateDelegate
{
	currentUpdateDelegate = newUpdateDelegate;
}

@end
