//
//  OffBusViewController.h
//  Bus
//
//  Created by Chris on 08/10/2013.
//  Copyright (c) 2013 Chris. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Stop;

@interface OffBusViewController : UIViewController
{
    IBOutlet UILabel *stopNameLabel;
    IBOutlet UILabel *streetNameLabel;
    IBOutlet UILabel *headingLabel;
    __weak IBOutlet UIView *infoView;
}

-(void)updateDisplay;
-(IBAction)returnHome;
@property (nonatomic) Stop *busStop;
@end
