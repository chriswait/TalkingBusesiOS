//
//  BusViewController.m
//  Bus
//
//  Created by Chris on 08/10/2013.
//  Copyright (c) 2013 Chris. All rights reserved.
//

#import "BusViewController.h"
#import "GetJourneyTimes.h"
#import "OffBusViewController.h"
#import "AppDelegate.h"
#import "Stop.h"

#define kTitle @"Incoming Stops"
#define kInterval 15

@interface BusViewController ()

@end

@implementation BusViewController
@synthesize busTime;
@synthesize busStopID, journeyID;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		// Custom initialization
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.edgesForExtendedLayout = UIRectEdgeNone;

	// Set the title
	[self setTitle:kTitle];

	// Add reload button
	UIBarButtonItem *reloadBarButton =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload)];
	[reloadBarButton setAccessibilityHint:@"Reloads approaching bus stops"];
	self.navigationItem.rightBarButtonItem = reloadBarButton;

	// Initialise the stop parser
	parser = [[GetJourneyTimes alloc] initWithBusStopID:busStopID journeyID:journeyID];

	// Get the closest stops
	[self getNextStops];

}
-(void)viewWillAppear:(BOOL)animated
{
	[stopsTable deselectRowAtIndexPath:[stopsTable indexPathForSelectedRow] animated:NO];
	// Initialise the timer
	reloadTimer = [NSTimer scheduledTimerWithTimeInterval:kInterval target:self selector:@selector(reload) userInfo:nil repeats:YES];
}

-(IBAction)reload
{
	[self getNextStops];
}

-(void)focusOnTable
{
	if ([(AppDelegate *)[[UIApplication sharedApplication] delegate] voiceOverIsRunning])
		UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, stopsTable);
}

-(void)getNextStops
{
	// Start a thread to load the stops
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

	        [parser startRequest];

	        dispatch_async(dispatch_get_main_queue(), ^{
	            if ([parser didSucceed]) {
	                // Get the closest stops
	                nextStops = [parser nextBusStops];
	                // Reload the table values
	                [stopsTable reloadData];
	                [self focusOnTable];
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

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	// A table row for each nearby stop`
	return [nextStops count];
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
	Stop *stop = [nextStops objectAtIndex:[indexPath row]];

	// Show the stop name
	[cell.textLabel setText:stop.name];
	// Set the VoiceOver accessibility value for this stop
	NSString *accessibilityString = [NSString stringWithFormat:@"%@, %d minutes away, facing %@ on %@", stop.name, (int)[stop.eta integerValue], stop.heading, stop.street];
	if ([indexPath row] == 0)
		accessibilityString = [NSString stringWithFormat:@"Next stop: %@", accessibilityString];
	else if ([indexPath row] == [nextStops count]-1)
		accessibilityString = [NSString stringWithFormat:@"Terminus: %@", accessibilityString];
	[cell setAccessibilityLabel:accessibilityString];
	[cell setAccessibilityHint:@"Displays off-bus information for this stop"];

	// Show the distance from the stop
	NSString *minutesDisplay = [NSString stringWithFormat:@"%d", (int)[[stop eta] integerValue]];
	[cell.detailTextLabel setText:minutesDisplay];

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
	OffBusViewController *offBusViewController = [[OffBusViewController alloc] initWithNibName:@"OffBusViewController" bundle:nil];

	// Set the chosen bus stop
	Stop *busStop = [nextStops objectAtIndex:[indexPath row]];
	[offBusViewController setBusStop:busStop];

	// Load the BusStopViewController
	[self.navigationController pushViewController:offBusViewController animated:YES];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 100.0;
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}


-(IBAction)shakeAction {
	[self reload];
}

-(void)viewWillDisappear:(BOOL)animated
{
	[reloadTimer invalidate];
}

@end
