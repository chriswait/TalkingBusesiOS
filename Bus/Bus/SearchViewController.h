//
//  SearchViewController.h
//  Bus
//
//  Created by Chris on 18/02/2014.
//  Copyright (c) 2014 Chris. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DistancesUpdatedDelegate.h"

@interface SearchViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, DistancesUpdatedDelegate>
{
	IBOutlet UITableView *stopsTable;
	IBOutlet UITextField *searchField;
	NSArray *searchBusStops;
	NSString *currentSearchQuery;
}
-(void)displayStopsForCurrentSearchQuery;
- (IBAction)searchFieldEditingDidEnd:(id)sender;
- (IBAction)dismissKeyboard;
-(void)focusOnTextField;
-(void)focusOnTable;
@end
