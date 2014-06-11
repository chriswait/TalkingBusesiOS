//
//  WaitingViewController.h
//  Bus
//
//  Created by Chris on 13/06/2013.
//  Copyright (c) 2013 Chris. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GetBusTimes;

@interface WaitingViewController : UIViewController <UIAlertViewDelegate>
{
	GetBusTimes *parser;

	__weak IBOutlet UILabel *mnemoLabel;
	__weak IBOutlet UILabel *etaLabel;
	__weak IBOutlet UILabel *destLabel;
	__weak IBOutlet UIView *infoView;

	NSTimer *reloadTimer;
	UIAlertView *timeoutAlert;
	UIAlertView *lastBusAlert;

	NSDictionary *currentTimeData;
	NSDictionary *lastTimeData;

	int currentReloadIntervalSeconds;
	NSDictionary *chosenBusTime;

}
@property (nonatomic) NSString *busStopID;
@property (nonatomic) NSString *serviceRef;

-(void)reload;
-(void)getBusTimes;
-(void)update;
-(IBAction)getOnBus;
-(void)getOnLastBus;
-(int)getNextReloadInterval;
@end
