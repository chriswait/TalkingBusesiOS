//
//  SearchViewController.m
//  Bus
//
//  Created by Chris on 18/02/2014.
//  Copyright (c) 2014 Chris. All rights reserved.
//

#import "SearchViewController.h"
#import "AppDelegate.h"
#import "BusStopViewController.h"
#import "StopDataModel.h"
#import "Stop.h"

#define kTitle @"Search"
#define kTabBarImageTitle @"Search.png"

@interface SearchViewController ()

@end

@implementation SearchViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		// Custom initialization
		searchBusStops = [NSArray new];
		currentSearchQuery = @"";

		// Set the title and tab bar item
		[self setTitle:kTitle];
		[self.tabBarItem setImage:[UIImage imageNamed:kTabBarImageTitle]];

	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	// Do any additional setup after loading the view from its nib.
	[searchField setReturnKeyType:UIReturnKeySearch];

	stopsTable.contentInset = UIEdgeInsetsZero;
	UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
	gestureRecognizer.cancelsTouchesInView = NO;
	[stopsTable addGestureRecognizer:gestureRecognizer];
}

-(void)viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
	stopsTable.contentInset = UIEdgeInsetsMake(0, 0, 100, 0);
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[[StopDataModel sharedInstance] setCurrentUpdateDelegate:self];
	// Deselect the selected row
	[stopsTable deselectRowAtIndexPath:[stopsTable indexPathForSelectedRow] animated:NO];
}

- (IBAction)dismissKeyboard
{
	[searchField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	currentSearchQuery = [textField text]; // Store the current search
	[self displayStopsForCurrentSearchQuery];
	[textField resignFirstResponder];
	return YES;
}

-(void)searchFieldEditingDidEnd:(id)sender {
}

-(void)distancesUpdated
{
	[self displayStopsForCurrentSearchQuery];
}

-(void)displayStopsForCurrentSearchQuery
{
	// Get the bus stops for the search
	NSArray *search_stops = [[StopDataModel sharedInstance] getStopsWithName:currentSearchQuery];
	if (!search_stops || [search_stops count] == 0) {
		NSString *accessibilityString = [NSString stringWithFormat:@"No bus stops found"];
		[stopsTable setAccessibilityLabel:accessibilityString];
	}
	searchBusStops = search_stops;
	[stopsTable reloadData];
	[self performSelector:@selector(focusOnTable) withObject:nil afterDelay:0.5];
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	// A table row for each nearby stops
	return [searchBusStops count];
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
	Stop *stop = [searchBusStops objectAtIndex:[indexPath row]];

	// Show the stop name
	[cell.textLabel setText:stop.name];
	// Set the VoiceOver accessibility value for this stop

	NSString *accessibilityString = [NSString stringWithFormat:@"%@, %d meters away, facing %@ on %@, services %@", stop.name, (int)[stop.distance integerValue], stop.heading, stop.street, stop.serviceMnemos];
	[cell setAccessibilityLabel:accessibilityString];
	[cell setAccessibilityHint:@"Shows departures from this stop"];

	[cell.detailTextLabel setText:[NSString stringWithFormat:@"%i",(int)[stop.distance integerValue]]];

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
	Stop *busStop = [searchBusStops objectAtIndex:[indexPath row]];
	[busStopViewController setBusStop:busStop];

	// Load the BusStopViewController
	[self.navigationController pushViewController:busStopViewController animated:YES];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 100.0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 0.0;
}
-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return 0.0;
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

-(void)focusOnTextField
{
	if ([(AppDelegate *)[[UIApplication sharedApplication] delegate] voiceOverIsRunning])
		UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, searchField);
}

-(void)focusOnTable
{
	if ([(AppDelegate *)[[UIApplication sharedApplication] delegate] voiceOverIsRunning])
		UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, stopsTable);
}

-(void)viewWillDisappear:(BOOL)animated
{
	[[StopDataModel sharedInstance] setCurrentUpdateDelegate:nil];
	[super viewWillDisappear:animated];
}

@end
