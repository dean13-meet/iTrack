


//http://stackoverflow.com/questions/3434020/ios-mkmapview-zoom-to-show-all-markers

#import <MapKit/MapKit.h>
#import "Geofence.h"

@interface MapPin : NSObject<MKAnnotation> {
    CLLocationCoordinate2D coordinate;
    NSString *title;
    NSString *subtitle;
}

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *subtitle;
@property (nonatomic) NSString* address;//matches coordinates
@property (nonatomic) NSNumber* setting;
@property (nonatomic) Geofence* fence;

- (id)initWithCoordinates:(CLLocationCoordinate2D)location placeName:(NSString *)placeName description:(NSString *)description;

@end