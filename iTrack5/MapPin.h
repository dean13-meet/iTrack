


//http://stackoverflow.com/questions/3434020/ios-mkmapview-zoom-to-show-all-markers

#import <MapKit/MapKit.h>
#import "Geofence.h"


@protocol MapPinDelegate <NSObject>

- (void) updateCalloutView:(BOOL)force;

@end



@interface MapPin : NSObject<MKAnnotation> {
    CLLocationCoordinate2D coordinate;
    NSString *title;
    NSString *subtitle;
}

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *subtitle;
@property (nonatomic) NSString* address;//matches coordinates
@property (nonatomic) NSNumber* setting;
@property (nonatomic) Geofence* fence;
@property (nonatomic) UIViewController* mapVC;
@property (nonatomic) id<MapPinDelegate> delegate;//MapPinView*

- (id)initWithCoordinates:(CLLocationCoordinate2D)location placeName:(NSString *)placeName description:(NSString *)description mapVC:(UIViewController*)mapVC;
- (void) setCoordinate:(CLLocationCoordinate2D)coord;

typedef void (^mapPinUpdateAddressCompletionBlock)(UIViewController* mapVC, MapPin* annotation);
@property (strong, nonatomic) mapPinUpdateAddressCompletionBlock blockToRunOnceAddressUpdates;//once address updates, this block will execute and then be destroyed

@property (strong, nonatomic)MKPinAnnotationView* pinView;
@end

