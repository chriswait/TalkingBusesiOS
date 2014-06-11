//
//  BusViewController.h
//  Bus
//
//  Created by Chris on 08/10/2013.
//  Copyright (c) 2013 Chris. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GetJourneyTimes;

@interface BusViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
	IBOutlet UITableView *stopsTable;
	NSArray *nextStops;
	NSTimer *reloadTimer;
	GetJourneyTimes *parser;
}
@property (nonatomic) NSDictionary *busTime;
@property (nonatomic) NSString *busStopID;
@property (nonatomic) NSString *journeyID;

-(void)getNextStops;
-(IBAction)reload;
-(void)focusOnTable;

@end
