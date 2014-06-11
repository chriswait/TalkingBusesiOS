//
//  WalkViewController.m
//  Bus
//
//  Created by Chris on 31/03/2013.
//  Copyright (c) 2013 Chris. All rights reserved.
//


#import "WalkViewController.h"
#import "StopDataModel.h"
#import "AppDelegate.h"
#import "BusStopViewController.h"
#import "Stop.h"

#define kTitle @"Nearby Stops"
#define kTabBarImageTitle @"Location.png"
#define kInterval 30

@interface WalkViewController ()

@end

@implementation WalkViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		// Custom initialization
		closestStops = NULL;

		// Set the title and tab bar item
		[self setTitle:kTitle];
		[self.tabBarItem setImage:[UIImage imageNamed:kTabBarImageTitle]];
	}
	return self;
}

- (void)viewDidLoad
{

	[super viewDidLoad];
	self.edgesForExtendedLayout = UIRectEdgeNone;

	// Add reload button
	UIBarButtonItem *reloadBarButton =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload)];
	[reloadBarButton setAccessibilityHint:@"Reloads nearby bus stops"];
	self.navigationItem.rightBarButtonItem = reloadBarButton;

}

-(void)focusOnTable
{
	// If voiceover isn't running, return
	if (![(AppDelegate *)[[UIApplication sharedApplication] delegate] voiceOverIsRunning]) return;

	// Scroll the table to the first row
	[stopsTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
	// Focus voiceover on the first row
//        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, [stopsTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]);
	// Focus VoiceOver on the table
	UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, stopsTable);
}

-(void)distancesUpdated
{
	[self nearbyStopsDidUpdate];
}

-(void)nearbyStopsDidUpdate
{
	[reloadTimer invalidate];
	reloadTimer = [NSTimer scheduledTimerWithTimeInterval:kInterval target:self selector:@selector(nearbyStopsDidUpdate) userInfo:nil repeats:YES];

	// Get the closest stops
	NSArray *newClosestStops = [[StopDataModel sharedInstance] nearbyBusStops];
	if ([self newClosestStopsAreDifferent:newClosestStops]) {
		closestStops = newClosestStops;
		// Reload the table values
		[stopsTable reloadData];
		[self performSelector:@selector(focusOnTable) withObject:nil afterDelay:0.5];
	} else {
		NSLog(@"Same Stops");
	}
}

-(BOOL)newClosestStopsAreDifferent:(NSArray *)newClosestStops
{
	if ([closestStops count] != [newClosestStops count]) return YES;
	for (int i = 0; i < [newClosestStops count]; i++) {
		if ([newClosestStops objectAtIndex:i]!=[closestStops objectAtIndex:i]) return YES;
	}
	return NO;
}

-(void)viewWillAppear:(BOOL)animated
{
	// Get a shared instance of the stop data model
	[[StopDataModel sharedInstance] setCurrentUpdateDelegate:self];

	// Deselect the selected row
	[stopsTable deselectRowAtIndexPath:[stopsTable indexPathForSelectedRow] animated:NO];

	// Initialise the timer
	reloadTimer = [NSTimer scheduledTimerWithTimeInterval:kInterval target:self selector:@selector(nearbyStopsDidUpdate) userInfo:nil repeats:YES];
}

-(IBAction)reload
{
	[self nearbyStopsDidUpdate];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	// A table row for each nearby stops
	return [closestStops count];
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
	Stop *stop = [closestStops objectAtIndex:[indexPath row]];

	// Show the stop name
	[cell.textLabel setText:stop.name];
	// Set the VoiceOver accessibility value for this stop
	NSString *accessibilityString = [NSString stringWithFormat:@"%d meters away, facing %@ on %@, services %@", (int) [stop.distance integerValue], stop.heading, stop.street, stop.serviceMnemos];
	if ([indexPath row] == 0)
		accessibilityString = [NSString stringWithFormat:@"Closest stop: %@", accessibilityString];
	[cell setAccessibilityValue:accessibilityString];
	[cell setAccessibilityLabel:stop.name];
	[cell setAccessibilityHint:@"Shows departures from this stop"];

	[cell.detailTextLabel setText:[NSString stringWithFormat:@"%i",(int)[stop.distance integerValue]]];
	[cell.detailTextLabel setTextColor:[UIColor blackColor]];

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
	Stop *busStop = [closestStops objectAtIndex:[indexPath row]];
	[busStopViewController setBusStop:busStop];

	// Load the BusStopViewController
	[self.navigationController pushViewController:busStopViewController animated:YES];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 100.0;
}

-(IBAction)shakeAction
{
	[self reload];
}


-(void)viewWillDisappear:(BOOL)animated
{
	[reloadTimer invalidate];
	[[StopDataModel sharedInstance] setCurrentUpdateDelegate:nil];
	[super viewWillDisappear:animated];
}

-(void)dealloc
{
}

@end
