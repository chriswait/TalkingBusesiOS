//
//  StopDataModel.h
//  Bus
//
//  Created by Chris on 10/06/2013.
//  Copyright (c) 2013 Chris. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "DistancesUpdatedDelegate.h"

@class LocationManager;
@class WalkViewController;
@class Stop;
@class FavoriteStop;

@interface StopDataModel : NSObject
{
	NSManagedObjectContext *managedObjectContext;
	NSArray *busStops;
	NSArray *favoriteStops;
}

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, weak) id <DistancesUpdatedDelegate> currentUpdateDelegate;
@property (nonatomic) NSArray *nearbyBusStops;
@property (nonatomic) NSMutableArray *nearbyFavoriteBusStops;
@property (nonatomic) NSArray *currentSearchStops;
@property (nonatomic) BOOL hasBusStops;

@property (nonatomic) CLLocation *lastUpdatedLocation;

+(StopDataModel *)sharedInstance;

// TOPO ID
-(void)checkForUpdate;

// CHECK
-(BOOL)checkForStops;

// ADD
-(void)populateStopsWithDictionaries:(NSArray *)stop_dicts;
-(void)addStopToFavorites:(Stop *)newFavoriteStop withName:(NSString *)name;

// GET
-(NSArray *)getBusStops;
-(void)loadBusStopsFromDatabase;
-(NSArray *)getFavoriteBusStops;
-(NSArray *)getNearbyStopsFromStops:(NSArray *)theStops numberOfStops:(NSInteger)numberOfStops;
-(Stop *)getStopWithStopID:(NSString *)stopID;
-(NSArray *)getStopsWithName:(NSString *)name;

// REMOVE
-(void)removeFavoriteStop:(FavoriteStop *)favorite_stop;
-(void)clearStopsDatabase;

// UPDATE
-(NSArray *)updateDistancesForStops:(NSArray *)stops withLocation:(CLLocation *) location usingBoxing:(BOOL)boxing;
-(void)updateBusStopDistancesWithLocation:(CLLocation *)location;
-(void)updateFavoriteBusStopDistancesWithLocation:(CLLocation *)location;;
-(void)updateSearchBusStopDistancesWithLocation:(CLLocation *)location;;
-(BOOL)shouldUpdateDistancesWithLocation:(CLLocation *)location;


-(void)downloadNewStopsWithNewTopoID:(NSString *)topoID;
-(void)displayClosestStops;


@end
