//
//  FavoriteStopsViewController.h
//  Bus
//
//  Created by Chris on 10/11/2013.
//  Copyright (c) 2013 Chris. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DistancesUpdatedDelegate.h"

@interface FavoriteStopsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, DistancesUpdatedDelegate>
{
	IBOutlet UITableView *stopsTable;
	NSArray *favoriteStops;
	NSTimer *reloadTimer;
}
-(IBAction)reload;

@end
