//
//  mapViewController.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 2/17/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "Geofence.h"
#import "MapPin.h"

#define mapVCFromAppDelegate ((AppDelegate*)[[UIApplication sharedApplication] delegate]).mapVC


//Map Enum
typedef enum {
	kAll, //Will show ALL pins, except for search pins
	kSearch, //Will show ONLY search pins
	kActive,
	kCompleted,
	kExpired,
	numberOfEnumItems//counts above items (because top item = 0 and we increment by 1)
} MapSetting;
//Overriding chain: Search overrides All which overrides ANY OTHER setting

/*
 Types of Pins:
 
 
 Search
 Not stored in core memory
 Only active when search bar is searching for locations
 */
#define searchPinColor MKPinAnnotationColorPurple/*

Active
Stored in memory as status:active
*/
#define activePinColor MKPinAnnotationColorGreen/*

Completed
Stored in memory as status:completed
*/
#define completedPinColor MKPinAnnotationColorRed/*

Expired
Stored in memory as status:expired
*/
#define expiredPinColor MKPinAnnotationColorRed/*


*/




@protocol geofenceCreator <NSObject>

- (void) addFenceWithLong:(float)longtitude lat:(float)lat recurr:(float)recurr recipients:(NSArray*)recs address:(NSString*)address radius:(NSInteger)radius givenFence:(Geofence*)fence arrival:(BOOL)arrival leave:(BOOL)leave shouldChangeMapSetting:(BOOL)settingChange optionalIdentifier:(NSString*)identifier arrivalMessage:(NSString*) arrivalMessage leaveMessage:(NSString*)leaveMessage arrivalsSent:(NSArray*)arrivalsSent leavesSent:(NSArray*)leavesSent forceSave:(BOOL)forceSave optionalSetSetting:(NSNumber*)setting owner:(NSString*)owner requester:(NSString*)requester optionalRequestApproved:(NSString*)requestApproved fenceWasSyncedDownFromServer:(BOOL)syncDown;

@end




@interface mapViewController : UIViewController <NSFetchedResultsControllerDelegate, CLLocationManagerDelegate, geofenceCreator, MKMapViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
- (void) deleteFence:(Geofence*) fence notifyServer:(BOOL)notify;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIView *searchBarPinBox;

- (void) setSearchBarShown:(BOOL)shown;
- (void) updateMapAnnotaions;
- (void) setSetting:(int)setting on:(BOOL)on forceAnnotationUpdate:(BOOL)force;

@property (strong, nonatomic) NSMutableArray* additionalAnnotationsToShow;//these annotations show regardless of state of map
@property (strong, nonatomic) MapPin* currentlyDraggedAnnotation;//used to make sure only 1 newly dragged pin is on at a time.

- (void) save;
- (void) dismissSignInPopup;
- (IBAction)closeSearchResults:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *logoutButton;
//mode setting:

@property (nonatomic)BOOL mode;//NO = normal, YES = request
@property (weak, nonatomic) IBOutlet UIButton *modeButton;
- (IBAction)toggleMode:(id)sender;

- (MKAnnotationView*) getMapAnnotationForGeofenceIdentifier:(NSString*)identifier orData:(NSDictionary*)data;

- (void) fetchAllGeofences;
- (void) fetchAllRequestedGeofences;

+ (NSArray*) dicsToPersons:(NSMutableArray*)recs;
+ (NSArray*) personsToDics:(NSMutableArray*)recs;
+ (NSArray*) recsFromFenceData:(NSData*)data;
@property (strong, nonatomic) IBOutlet UIView *topBar;
//Hold topBar strong - we may remove it from this view for other purposes, so make sure it's not dealloced

@property (weak, nonatomic) IBOutlet UIView *searchResultsView;

@property (strong, nonatomic) NSMutableArray* mapSettingEnums;
- (void) destoryDraggedSearchPin;
@property (weak, nonatomic) IBOutlet UITableView *tableViewForSearchResults;
@property (weak, nonatomic) IBOutlet UIButton *closeSearchButton;
@property (weak, nonatomic) IBOutlet UIButton *plusButton;
- (IBAction)plusClicked:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *zoomfitButton;
@property (weak, nonatomic) IBOutlet UIView *blackMapViewCover;
@property (weak, nonatomic) IBOutlet UIView *coverViewForTopView;

@end
