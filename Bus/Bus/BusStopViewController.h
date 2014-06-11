//
//  BusStopViewController.h
//  Bus
//
//  Created by Chris on 31/03/2013.
//  Copyright (c) 2013 Chris. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GetBusTimes;
@class Stop;

@interface BusStopViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UITextFieldDelegate>
{
	IBOutlet UITableView *busesTable;
	NSArray *busTimes;
	GetBusTimes *parser;
	NSTimer *reloadTimer;
	UIAlertView *favoriteNameAlertView;
}

@property (nonatomic) Stop *busStop;

-(BOOL) busStopIsFavorite;
- (IBAction)favoritesButtonPressed;
-(void)getBusTimes;
-(IBAction)reload;
-(void)updateFavoritesButton;
-(void)loadTomorrowsBuses;
@end
