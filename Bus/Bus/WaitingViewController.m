//
//  WaitingViewController.m
//  Bus
//
//  Created by Chris on 13/06/2013.
//  Copyright (c) 2013 Chris. All rights reserved.
//

#import "WaitingViewController.h"
#import "GetBusTimes.h"
#import "BusViewController.h"
#import <AudioToolbox/AudioServices.h>

#define kTitle @"Waiting for Bus"
#define kReloadIntervalFiveMinuteSeconds 300
#define kReloadIntervalTwoMinuteSeconds 120
#define kReloadIntervalMinuteSeconds 60
#define kReloadIntervalHalfMinuteSeconds 30
#define kReloadIntervalQuarterMinuteSeconds 15
#define kMissedBusIntervalMinutes 2

@interface WaitingViewController ()

@end

@implementation WaitingViewController
@synthesize busStopID, serviceRef;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.edgesForExtendedLayout = UIRectEdgeNone;


	// Initialise the bus times parser
	parser = [[GetBusTimes alloc] initWithBusStopID:busStopID serviceRef:serviceRef numberOfDays:nil];

	// Set title
	[self setTitle:kTitle];

	// Add reload button
	UIBarButtonItem *reloadBarButton =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload)];
	[reloadBarButton setAccessibilityHint:@"Double Tap to reload bus time"];
	self.navigationItem.rightBarButtonItem = reloadBarButton;

	timeoutAlert = [[UIAlertView alloc] initWithTitle:@"Could not load bus times" message:@"Request timed out, please check internet connection and retry" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
	lastBusAlert = [[UIAlertView alloc] initWithTitle:@"Bus has left" message:@"The bus you were waiting for has left the stop, did you get on it?" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Yes",@"No",nil];

}

-(void)viewWillAppear:(BOOL)animated
{
	// Custom initialization
	currentReloadIntervalSeconds = kReloadIntervalHalfMinuteSeconds;

	// Initialise the timer
	reloadTimer = [NSTimer scheduledTimerWithTimeInterval:currentReloadIntervalSeconds target:self selector:@selector(reload) userInfo:nil repeats:YES];

	lastTimeData = nil;
	[self getBusTimes];
}

-(void)reload
{
	[reloadTimer invalidate];
	reloadTimer = [NSTimer scheduledTimerWithTimeInterval:currentReloadIntervalSeconds target:self selector:@selector(reload) userInfo:nil repeats:YES];
	[self getBusTimes];
}

-(void)getBusTimes
{

	// Start a thread to load the stops
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

	        // Initialise the bus times parser
	        [parser startRequest];

	        dispatch_async(dispatch_get_main_queue(), ^{
	            if ([parser didSucceed]) {
	                if ([[parser busTimes] count] > 0) {
	                    [self processNewBusTimes:[parser busTimes]];
					} else {
	                    if (lastTimeData) {
	                        [reloadTimer invalidate];
	                        [lastBusAlert show];
						}
	                    UIAlertView *noBusesAlert = [[UIAlertView alloc] initWithTitle:@"No incoming buses" message:@"Could not find any incoming buses for this stop" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
	                    [noBusesAlert show];
					}
				} else if ([parser didTimeout]) {
	                [timeoutAlert show];
				} else if ([parser notConnected]) {
	                UIAlertView *connectionAlert = [[UIAlertView alloc] initWithTitle:@"Could not load bus times" message:@"Connection failed, please check internet connection and retry" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
	                [connectionAlert show];
				}
			});
		});
}

-(void)processNewBusTimes:(NSArray *)busTimes
{
	// We "choose" the first bus time
	chosenBusTime = [[parser busTimes] objectAtIndex:0];

	// Update our currentTimeData with the first timeData returned
	NSArray *timeDatas = [chosenBusTime objectForKey:@"timeDatas"];
	currentTimeData = [timeDatas objectAtIndex:0];

	// If we haven't updated before, just update
	if (!lastTimeData) {
		[self update]; // Update the view
	} else {
		// If we've updated before, check if the bus has left
		int minutesDiff =  (int)([[currentTimeData valueForKey:@"minutes" ] integerValue] - [[lastTimeData valueForKey:@"minutes"] integerValue]);
		// If the eta has increased by more than kMissedBusIntervalMinutes minutes
		if (minutesDiff > kMissedBusIntervalMinutes) {
			[reloadTimer invalidate]; // Pause updates
			[lastBusAlert show]; // Ask the user if they boarded the last bus
		} else {
			// Otherwise just update
			[self update]; // Update the view
		}
	}

}

-(void)update
{

	// Set the text for the bus mnemonic label
	NSString *busMnemonicLabelText = [chosenBusTime valueForKey:@"mnemoService"];
	[mnemoLabel setText:busMnemonicLabelText];
	NSString *busAccessibilityString = [NSString stringWithFormat:@"The number, %@ bus", busMnemonicLabelText];

	// Set the text for the eta label
	int minutes = (int)[[currentTimeData valueForKey:@"minutes"] integerValue];
	NSString *minutesLabelText = [NSString stringWithFormat:@"%i min", minutes];
	NSString *minutesAccessibilityString = [NSString stringWithFormat:@"Arriving in, %d minutes", minutes];
	if (minutes == 0) {
		minutesLabelText = @"Due now";
		minutesAccessibilityString = @"Due now";
		AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
	}
	[etaLabel setText:minutesLabelText];

	// Set the text for the destination label
	NSString *destinationLabelText = [[currentTimeData valueForKey:@"nameDest"]capitalizedString];
	[destLabel setText:destinationLabelText];

	NSString *nameAccessibilityString = [NSString stringWithFormat:@"Going to, %@", destinationLabelText];
	NSString *infoAccessibilityString = [NSString stringWithFormat:@"%@, %@, %@", busAccessibilityString, minutesAccessibilityString, nameAccessibilityString];
	[infoView setAccessibilityLabel:infoAccessibilityString];

	// Update the frequency of the timer based on the new eta
	[reloadTimer invalidate];
	reloadTimer = [NSTimer scheduledTimerWithTimeInterval:[self getNextReloadInterval] target:self selector:@selector(reload) userInfo:nil repeats:YES];

	lastTimeData = currentTimeData; // Update the last chosen bus time

	// Speak the announcement, by selecting the infoview
	UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, infoView);
}

-(void)getOnLastBus
{
	// We need to get hold of the PREVIOUS journey ID
	BusViewController *busViewController = [[BusViewController alloc] initWithNibName:@"BusViewController" bundle:nil];
	[busViewController setBusStopID:busStopID];
	[busViewController setJourneyID:[lastTimeData valueForKey:@"journeyId"]];
	[self.navigationController pushViewController:busViewController animated:YES];
}

-(IBAction)getOnBus
{
	BusViewController *busViewController = [[BusViewController alloc] initWithNibName:@"BusViewController" bundle:nil];
	[busViewController setBusStopID:busStopID];
	[busViewController setJourneyID:[currentTimeData valueForKey:@"journeyId"]];
	[self.navigationController pushViewController:busViewController animated:YES];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (alertView==lastBusAlert) {
		// If the user selected "yes"
		if (buttonIndex == 0) {
			[self getOnLastBus];
		} else {
			lastTimeData = nil;
			[self update];
		}
	}
}

-(int)getNextReloadInterval
{
	int minutes = (int)[[currentTimeData valueForKey:@"minutes"] integerValue];
	if (minutes >= 10) return kReloadIntervalFiveMinuteSeconds;
	else if (minutes >= 5) return kReloadIntervalTwoMinuteSeconds;
	else if (minutes >= 2) return kReloadIntervalMinuteSeconds;
	return kReloadIntervalHalfMinuteSeconds;
}


-(void)viewWillDisappear:(BOOL)animated
{
	[reloadTimer invalidate];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end

