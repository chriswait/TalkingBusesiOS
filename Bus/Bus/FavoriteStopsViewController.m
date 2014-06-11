//
//  FavoriteStopsViewController.m
//  Bus
//
//  Created by Chris on 10/11/2013.
//  Copyright (c) 2013 Chris. All rights reserved.
//

#import "FavoriteStopsViewController.h"
#import "BusStopViewController.h"
#import "StopDataModel.h"
#import "FavoriteStop.h"

#define kTitle @"Favorite Stops"
#define kTabBarImageTitle @"Favorites.png"
#define kInterval 30

@interface FavoriteStopsViewController ()

@end

@implementation FavoriteStopsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		// Custom initialization
		favoriteStops = [NSMutableArray new];

		// Set the title and tab bar item
		[self.tabBarItem setImage:[UIImage imageNamed:kTabBarImageTitle]];
		[self setTitle:kTitle];
	}
	return self;
}

- (void)viewDidLoad
{
	self.edgesForExtendedLayout = UIRectEdgeNone;
	[super viewDidLoad];

	// Add reload button
	UIBarButtonItem *reloadBarButton =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload)];
	[reloadBarButton setAccessibilityHint:@"Reloads favorite bus stops"];
	self.navigationItem.rightBarButtonItem = reloadBarButton;

	// Initialise the timer
	reloadTimer = [NSTimer scheduledTimerWithTimeInterval:kInterval target:self selector:@selector(reload) userInfo:nil repeats:YES];

	[self favoriteStopsDidUpdate];
}

-(void)viewWillAppear:(BOOL)animated
{
	[[StopDataModel sharedInstance] setCurrentUpdateDelegate:self];
	[self favoriteStopsDidUpdate];
}

-(IBAction)reload
{
	if ([reloadTimer isValid]) {
		[reloadTimer invalidate];
		reloadTimer = [NSTimer scheduledTimerWithTimeInterval:kInterval target:self selector:@selector(reload) userInfo:nil repeats:YES];
	}
	[self favoriteStopsDidUpdate];
}

-(void)distancesUpdated
{
	[self favoriteStopsDidUpdate];
}

-(void) favoriteStopsDidUpdate {
	favoriteStops = [[StopDataModel sharedInstance] nearbyFavoriteBusStops];
	if (!favoriteStops || [favoriteStops count]==0)
		[stopsTable setAccessibilityLabel:@"No favorite stops. Add favorites using the 'Add to favorites' button after selecting a bus stop"];
	[stopsTable reloadData];
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	// A table row for each nearby stops
	return [favoriteStops count];
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

	static NSString *CellIdentifier = @"Cell";
	UITableViewCell * cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
	}

	// Get the stop for this row
	FavoriteStop *stop = [favoriteStops objectAtIndex:[indexPath row]];

	// Show the stop favorite name
	NSString *stopDisplayName = nil;
	if (stop.favorite_name) stopDisplayName = stop.favorite_name;
	else stopDisplayName = stop.name;
	[cell.textLabel setText:stopDisplayName];

	// Show the distance from the stop
	NSString *distanceDisplay = [NSString stringWithFormat:@"%im", (int)[stop.distance integerValue]];
	[cell.detailTextLabel setText:distanceDisplay];

	NSString *accessibilityString = [NSString stringWithFormat:@"%@, %d meters away, facing %@ on %@, services %@", stopDisplayName, (int) [stop.distance integerValue], stop.heading, stop.street, stop.serviceMnemos];
	[cell setAccessibilityLabel:accessibilityString];
	[cell setAccessibilityHint:@"Shows departures from this bus stop"];

	// Handle the large display for visually impaired users
	BOOL userIsVisuallyImpaired = YES;
	if (userIsVisuallyImpaired) {
		[cell.textLabel setFont:[UIFont boldSystemFontOfSize:30]];
		[cell.textLabel setLineBreakMode:NSLineBreakByWordWrapping];
		[cell.textLabel setNumberOfLines:2];
		CGRect frame = cell.textLabel.frame;
		[cell.textLabel setFrame:frame];
		[cell.detailTextLabel setFont:[UIFont boldSystemFontOfSize:22.0]];
		[cell.detailTextLabel setTextColor:[UIColor blackColor]];
	}


	return cell;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Initialise a BusStopViewController
	BusStopViewController *busStopViewController = [[BusStopViewController alloc] initWithNibName:@"BusStopViewController" bundle:nil];

	// Set the chosen bus stop
	Stop *busStop = [favoriteStops objectAtIndex:[indexPath row]];
	[busStopViewController setBusStop:busStop];

	// Load the BusStopViewController
	[self.navigationController pushViewController:busStopViewController animated:YES];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 100.0;
}

-(void)viewWillDisappear:(BOOL)animated
{
	[reloadTimer invalidate];
	[[StopDataModel sharedInstance] setCurrentUpdateDelegate:nil];
	[super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
