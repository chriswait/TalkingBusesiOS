//
//  OffBusViewController.m
//  Bus
//
//  Created by Chris on 08/10/2013.
//  Copyright (c) 2013 Chris. All rights reserved.
//

#import "OffBusViewController.h"
#import "Stop.h"

@interface OffBusViewController ()

@end

@implementation OffBusViewController
@synthesize busStop;

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

	[self updateDisplay];

}

-(void)updateDisplay
{
	NSString *stopNameText = [NSString stringWithFormat:@"You are at %@", busStop.name];
	[stopNameLabel setText:stopNameText];

	NSString *streetNameText = [NSString stringWithFormat:@"On %@", busStop.street];
	[streetNameLabel setText:streetNameText];

	NSString *headingText = [NSString stringWithFormat:@"Heading %@", busStop.heading];
	[headingLabel setText:headingText];

	NSString *accessibilityString = [NSString stringWithFormat:@"%@, %@, %@", stopNameText, streetNameText, headingText];
	[infoView setAccessibilityLabel:accessibilityString];

	// Speak the announcement, by selecting the infoview
	UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, infoView);
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}


-(IBAction)returnHome
{
	[self.tabBarController setSelectedIndex:0];
	[self.navigationController popToRootViewControllerAnimated:YES];
	UINavigationController *firstNavController = (UINavigationController *)[self.tabBarController selectedViewController];
	[firstNavController popToRootViewControllerAnimated:YES];
}

@end
