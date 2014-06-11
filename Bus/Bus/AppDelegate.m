//
//  AppDelegate.m
//  Bus
//
//  Created by Chris on 27/02/2013.
//  Copyright (c) 2013 Chris. All rights reserved.
//

#import "AppDelegate.h"
#import "LocationManager.h"
#import "WalkViewController.h"
#import "FavoriteStopsViewController.h"
#import "SearchViewController.h"
#import "StopDataModel.h"

@implementation AppDelegate
@synthesize voiceOverIsRunning;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

	// Prevent screen dimming
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];

	// Find out if VoiceOver is already running
	voiceOverIsRunning = UIAccessibilityIsVoiceOverRunning();

	// Monitor for notifications for VoiceOver status
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(voiceOverStatusChanged) name:UIAccessibilityVoiceOverStatusChanged object:nil];

	// Fire up the location manager
	[LocationManager sharedInstance];

	// Get a shared instance of the stop data model and set the managedObjectContext
	StopDataModel *stopDataModel = [StopDataModel sharedInstance];
	[stopDataModel setManagedObjectContext:[self managedObjectContext]];
	[stopDataModel checkForUpdate];

	// Instantiate WalkViewController
	WalkViewController *walkViewController = [[WalkViewController alloc] initWithNibName:@"WalkViewController" bundle:nil];
	UINavigationController *walkNavViewController = [[UINavigationController alloc] initWithRootViewController:walkViewController];

	// Instantiate the Favorites tab
	FavoriteStopsViewController *favoritesViewController = [[FavoriteStopsViewController alloc] initWithNibName:@"FavoriteStopsViewController" bundle:nil];
	UINavigationController *favouritesNavViewController = [[UINavigationController alloc] initWithRootViewController:favoritesViewController];

	// Instantiate the Search tab
	SearchViewController *searchViewController = [[SearchViewController alloc] initWithNibName:@"SearchViewController" bundle:nil];
	UINavigationController *searchNavViewController = [[UINavigationController alloc] initWithRootViewController:searchViewController];

	// Instantiate tab bar controlller
	UITabBarController *tabBarController = [UITabBarController new];
	[tabBarController setViewControllers:@[walkNavViewController, favouritesNavViewController, searchNavViewController]];

	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	[self.window setRootViewController:tabBarController];
	[self.window makeKeyAndVisible];

	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(NSManagedObjectContext *) managedObjectContext
{
	if (managedObjectContext != nil) return managedObjectContext;
	NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
	if (coordinator != nil) {
		managedObjectContext = [NSManagedObjectContext new];
		[managedObjectContext setPersistentStoreCoordinator:coordinator];
	}
	return managedObjectContext;
}

-(NSManagedObjectModel *)managedObjectModel
{
	if (managedObjectModel != nil) return managedObjectModel;
	managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
	return managedObjectModel;
}

-(NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
	if (persistentStoreCoordinator != nil) return persistentStoreCoordinator;
	NSURL *storeUrl = [NSURL fileURLWithPath:[[self applicationDocumentsDirectory] stringByAppendingString:@"Bus.sqlite"]];
	NSError *error = nil;
	persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
	if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error]) {
		// Handle error
	}
	return persistentStoreCoordinator;
}

-(NSString *)applicationDocumentsDirectory
{
	return [NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES) lastObject];
}

- (void)voiceOverStatusChanged
{
	voiceOverIsRunning = UIAccessibilityIsVoiceOverRunning();
}

-(void)dealloc
{
}
@end
