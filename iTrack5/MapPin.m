

//http://stackoverflow.com/questions/3434020/ios-mkmapview-zoom-to-show-all-markers


#import "MapPin.h"
#import "MapPinView.h"
#import "mapViewController.h"

@implementation MapPin

@synthesize coordinate;
@synthesize title;
@synthesize subtitle;

- (id)initWithCoordinates:(CLLocationCoordinate2D)location placeName:placeName description:description mapVC:(mapViewController*)mapVC{
    self = [super init];
    if (self != nil) {
        coordinate = location;
        title = placeName;
        subtitle = description;
        self.mapVC = mapVC;
    }
    return self;
}

- (void) setCoordinate:(CLLocationCoordinate2D)coord{
    coordinate = coord;
    [self updateAddressLabel];
}

- (void) updateAddressLabel
{
    CLGeocoder* geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:[[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude] completionHandler:^(NSArray *placemarks, NSError *error) {
        
        if(placemarks.count==0)return;
        CLPlacemark* aPlacemark = placemarks[0];
        NSArray *lines = aPlacemark.addressDictionary[ @"FormattedAddressLines"];
        NSString *addressString = [lines componentsJoinedByString:@"\n"];
        self.title = self.subtitle = self.address = addressString;
        //[((mapViewController*)(self.mapVC)) updateMapAnnotaions];
        [self.delegate updateCalloutView:false];
		if(self.fence.identifier)//if it has no identifier, then there is no need to save (it doesn't exist in memory yet)
			[((MapPinView*)self.delegate) saveFence];
        //[((mapViewController*)self.mapVC) updateMapAnnotaions];
        
        
        if(self.blockToRunOnceAddressUpdates){
            self.blockToRunOnceAddressUpdates(self.mapVC, self);
            self.blockToRunOnceAddressUpdates = nil;}
        [((mapViewController*)self.mapVC).mapView selectAnnotation:self animated:YES];
        
    }];
}



@end