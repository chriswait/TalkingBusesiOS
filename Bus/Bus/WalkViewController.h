//
//  WalkViewController.h
//  Bus
//
//  Created by Chris on 31/03/2013.
//  Copyright (c) 2013 Chris. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DistancesUpdatedDelegate.h"

@interface WalkViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, DistancesUpdatedDelegate>
{
	IBOutlet UITableView *stopsTable;
	NSArray *closestStops;
	NSTimer *reloadTimer;
}

-(IBAction)reload;
-(void)focusOnTable;
-(BOOL)newClosestStopsAreDifferent:(NSArray *)newClosestStops;
@end
