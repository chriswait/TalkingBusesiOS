//
//  BusStopViewController.m
//  Bus
//
//  Created by Chris on 31/03/2013.
//  Copyright (c) 2013 Chris. All rights reserved.
//

#import "BusStopViewController.h"
#import "GetBusTimes.h"
#import "StopDataModel.h"
#import "WaitingViewController.h"
#import "Stop.h"
#import "FavoriteStop.h"

#define kTitle @"Next Buses"
#define kInterval 30

@interface BusStopViewController ()

@end

@implementation BusStopViewController
@synthesize busStop;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		// Custom initialization
	}
//    UIAlertView *favoriteNameAlertView = nil;
	return self;
}


- (void)viewDidLoad
{
	[super viewDidLoad];
	self.edgesForExtendedLayout = UIRectEdgeNone;

	// Set title
	[self setTitle:kTitle];

	// Initialise the bus times parser
	parser = [[GetBusTimes alloc] initWithBusStopID:busStop.stopId serviceRef:nil numberOfDays:nil];
}


-(void)viewWillAppear:(BOOL)animated
{
	// Deselect the selected row
	[busesTable deselectRowAtIndexPath:[busesTable indexPathForSelectedRow] animated:NO];

	// Initialise the timer
	reloadTimer = [NSTimer scheduledTimerWithTimeInterval:kInterval target:self selector:@selector(reload) userInfo:nil repeats:YES];

	[self updateFavoritesButton];

	// Fetch the bus times
	[self getBusTimes];
}


-(void)getBusTimes
{
	// Start a thread to load the bus times
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

	        // start the request
	        [parser startRequest];

	        dispatch_async(dispatch_get_main_queue(), ^{
	            if ([parser didSucceed]) {

	                // Get the bus times from the parser
	                busTimes = [parser busTimes];
	                int noBusTimes = (int)[busTimes count];

	                if (noBusTimes == 0) {
	                    // If there are no more bus times, we need to refresh the request with day=1
	                    [self loadTomorrowsBuses];
					} else {
	                    // Speak a voiceover announcement
	                    NSString *accessibilityString = [NSString stringWithFormat:@"%i incoming buses found", noBusTimes];
	                    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, accessibilityString);

	                    // Reload the bus times table
	                    [busesTable reloadData];
					}
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

-(void)loadTomorrowsBuses
{
	// Initialise the bus times parser
	parser = [[GetBusTimes alloc] initWithBusStopID:busStop.stopId serviceRef:nil numberOfDays:@"1"];
	[self getBusTimes];
}

-(void)reload
{
	[reloadTimer invalidate];
	reloadTimer = [NSTimer scheduledTimerWithTimeInterval:kInterval target:self selector:@selector(reload) userInfo:nil repeats:YES];
	[self getBusTimes];
}

- (IBAction)favoritesButtonPressed
{
	if ([self busStopIsFavorite]) {
		[[StopDataModel sharedInstance] removeFavoriteStop:(FavoriteStop *)busStop];
		[self.navigationController popToRootViewControllerAnimated:YES];
	} else {
		[self updateFavoritesButton];

		// Display naming alertview
		favoriteNameAlertView = [UIAlertView new];
		[favoriteNameAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
		[favoriteNameAlertView setTitle:@"Enter a name for this stop"];
		[favoriteNameAlertView addButtonWithTitle:@"Cancel"];
		[favoriteNameAlertView addButtonWithTitle:@"Enter"];
		[favoriteNameAlertView setDelegate:self];
		UITextField *textField = [favoriteNameAlertView textFieldAtIndex:0];
		[textField setDelegate:self];
		[textField setClearButtonMode:UITextFieldViewModeAlways];
		[textField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
		textField.text = busStop.name;
		[favoriteNameAlertView show];
	}
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 1) {
		UITextField *nameField = [alertView textFieldAtIndex:0];
		NSString *name = nameField.text;
		[[StopDataModel sharedInstance] addStopToFavorites:busStop withName:name];
		[self updateFavoritesButton];
	}
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
	NSString *name = textField.text;
	[[StopDataModel sharedInstance] addStopToFavorites:busStop withName:name];
	[self updateFavoritesButton];
	[favoriteNameAlertView dismissWithClickedButtonIndex:1 animated:YES];
	return NO;
}


-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	// One row for each bus time
	return [busTimes count];
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

	// Get the bus time for this row
	NSDictionary *busTime = [busTimes objectAtIndex:[indexPath row]];
	NSString *busNo = [busTime valueForKey:@"mnemoService"];

	NSArray *timeDatas = [busTime objectForKey:@"timeDatas"];
	NSDictionary *firstTimeData = [timeDatas objectAtIndex:0];
	NSString *nameDest = [[firstTimeData valueForKey:@"nameDest"] capitalizedString];

	NSString *firstTime = [NSString stringWithFormat:@"%@", [firstTimeData valueForKey:@"minutes"]];
	NSString *times = firstTime;
	for (int i = 1; i < [timeDatas count]; i++) {
		NSDictionary *timeData = [timeDatas objectAtIndex:i];
		// If we're on the last item, use an "and"
		if (i == [timeDatas count] - 1 && [timeDatas count] > 1)
			times = [NSString stringWithFormat:@"%@ and %@", times, [timeData valueForKey:@"minutes"]];
		else
			times = [NSString stringWithFormat:@"%@, %@", times, [timeData valueForKey:@"minutes"]];
	}

	// Show the bus number and destination
	NSString *busDest = [NSString stringWithFormat:@"%@  %@", busNo, nameDest];
	[cell.textLabel setText:busDest];

	// Show the expected arrival time
	[cell.detailTextLabel setText:firstTime];
	[cell.detailTextLabel setFont:[UIFont boldSystemFontOfSize:30]];

	// Set the accessibility string for VoiceOver
	[cell setAccessibilityLabel:[NSString stringWithFormat:@"Number %@ bus", busNo]];
	NSString *accessibilityString = [NSString stringWithFormat:@"Arriving in %@ minutes, going to %@", times, nameDest];
	[cell setAccessibilityValue:accessibilityString];
	[cell setAccessibilityHint:@"Provides updates of arrival times for this service"];

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
	// Get the bus time for this row
	NSDictionary *chosenBusTime = [busTimes objectAtIndex:[indexPath row]];
	NSString *serviceRef = [chosenBusTime valueForKey:@"refService"];

	// Initialise the WaitingViewController
	WaitingViewController *waitingViewController = [[WaitingViewController alloc] initWithNibName:@"WaitingViewController" bundle:nil];
	// Update the parser to fetch only bus times for this service
	[waitingViewController setServiceRef:serviceRef];
	[waitingViewController setBusStopID:busStop.stopId];
	// Show the WaitingViewController
	[self.navigationController pushViewController:waitingViewController animated:YES];

}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 100.0;
}

-(BOOL) busStopIsFavorite
{
	return [busStop isKindOfClass:[FavoriteStop class]];
}


-(void)updateFavoritesButton
{
	// Add reload button
	UIBarButtonItem *reloadBarButton =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload)];
	[reloadBarButton setAccessibilityHint:@"Reloads incoming bus information"];
	UIBarButtonItem *favoritesBarButton = NULL;
	// Add favorites button
	if ([self busStopIsFavorite]) {
		favoritesBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(favoritesButtonPressed)];
		[favoritesBarButton setAccessibilityValue:@"Remove favourite bus stop"];
		[favoritesBarButton setAccessibilityHint:@"Removes this bus stop from favorites"];
	} else {
		favoritesBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(favoritesButtonPressed)];
		[favoritesBarButton setAccessibilityValue:@"Add favourite bus stop"];
		[favoritesBarButton setAccessibilityHint:@"Adds this bus stop to favorites"];
	}
	self.navigationItem.rightBarButtonItems = @[reloadBarButton,favoritesBarButton];

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
