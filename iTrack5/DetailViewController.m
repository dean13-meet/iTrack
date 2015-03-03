//
//  DetailViewController.m
//  iTrack3
//
//  Created by Dean Leitersdorf on 2/13/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "DetailViewController.h"
#import "MapPin.h"

@interface DetailViewController()

@property (nonatomic) CLLocationCoordinate2D selectedLocation;
@property (nonatomic, strong) NSString* selectedAddress;//matches coordinate

@end


@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }
}

- (void)configureView {
    // Update the user interface for the detail item.
    if (self.detailItem) {
        self.detailDescriptionLabel.text = [[self.detailItem valueForKey:@"timestampStart"] description];
        self.recipientField.text = [NSString stringWithFormat:@"%@", self.detailItem.recipient];
        self.selectedLocation = CLLocationCoordinate2DMake([self.detailItem.lat doubleValue], [self.detailItem.longtitude doubleValue]);
        self.selectedAddress = self.detailItem.address;
        
        self.startTime.text = [NSString stringWithFormat:@"%@", self.detailItem.timestampStart];
        self.endTime.text = [NSString stringWithFormat:@"%@", self.detailItem.timestampEnd];
        self.recurTime.text = [NSString stringWithFormat:@"%@", self.detailItem.recur];
        
        [self.mapView removeAnnotations:self.mapView.annotations];
        MapPin* pin = [[MapPin alloc] initWithCoordinates:self.selectedLocation placeName:self.selectedAddress description:self.selectedAddress];
        pin.address = self.selectedAddress;
        [self.mapView addAnnotation: pin];
        
        [self zoomToAnnotationsBounds];
        
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.mapView.delegate = self;
    UITapGestureRecognizer* closeKeyboardsTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(closeKeyboard)] ;
    closeKeyboardsTap.numberOfTouchesRequired=1;
    [self.view addGestureRecognizer:closeKeyboardsTap];
    
    [self configureView];
}

- (void) closeKeyboard
{
    [self.view endEditing:YES];
}

- (void) mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    self.selectedLocation = view.annotation.coordinate;
    self.selectedAddress = ((MapPin*)view.annotation).address;
}

- (IBAction)createGeofence:(id)sender
{
    [self.delegate addFenceWithLong:self.selectedLocation.longitude lat:self.selectedLocation.latitude start:[self.startTime.text floatValue] stop:[self.endTime.text floatValue] recurr:[self.recurTime.text floatValue] recipient:[self.recipientField.text integerValue] address:self.selectedAddress];
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark searchbar

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    NSString* query = searchBar.text;
    [searchBar resignFirstResponder];
    CLGeocoder* geocoder = [[CLGeocoder alloc] init];
    [geocoder geocodeAddressString:query
                 completionHandler:^(NSArray* placemarks, NSError* error){
                     [self.mapView removeAnnotations:self.mapView.annotations];
                     for (CLPlacemark* aPlacemark in placemarks)
                     {
                         self.mapView.centerCoordinate = aPlacemark.location.coordinate;
                         NSArray *lines = aPlacemark.addressDictionary[ @"FormattedAddressLines"];
                         NSString *addressString = [lines componentsJoinedByString:@"\n"];
                         MapPin* annotation = [[MapPin alloc] initWithCoordinates:aPlacemark.location.coordinate placeName:addressString description:addressString];
                         annotation.address = addressString;
                         [self.mapView addAnnotation:annotation];
                     }
                     [self zoomToAnnotationsBounds];
                 }];
    
}


- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

//http://stackoverflow.com/questions/3434020/ios-mkmapview-zoom-to-show-all-markers
- (void) zoomToAnnotationsBounds{
    
    NSArray* annotations = [self.mapView annotations];
    
    CLLocationDegrees minLatitude = DBL_MAX;
    CLLocationDegrees maxLatitude = -DBL_MAX;
    CLLocationDegrees minLongitude = DBL_MAX;
    CLLocationDegrees maxLongitude = -DBL_MAX;
    
    for (MapPin *annotation in annotations) {
        double annotationLat = annotation.coordinate.latitude;
        double annotationLong = annotation.coordinate.longitude;
        minLatitude = fmin(annotationLat, minLatitude);
        maxLatitude = fmax(annotationLat, maxLatitude);
        minLongitude = fmin(annotationLong, minLongitude);
        maxLongitude = fmax(annotationLong, maxLongitude);
    }
    
    // See function below
    [self setMapRegionForMinLat:minLatitude minLong:minLongitude maxLat:maxLatitude maxLong:maxLongitude];
    
    // If your markers were 40 in height and 20 in width, this would zoom the map to fit them perfectly. Note that there is a bug in mkmapview's set region which means it will snap the map to the nearest whole zoom level, so you will rarely get a perfect fit. But this will ensure a minimum padding.
    UIEdgeInsets mapPadding = UIEdgeInsetsMake(40.0, 10.0, 0.0, 10.0);
    CLLocationCoordinate2D relativeFromCoord = [self.mapView convertPoint:CGPointMake(0, 0) toCoordinateFromView:self.mapView];
    
    // Calculate the additional lat/long required at the current zoom level to add the padding
    CLLocationCoordinate2D topCoord = [self.mapView convertPoint:CGPointMake(0, mapPadding.top) toCoordinateFromView:self.mapView];
    CLLocationCoordinate2D rightCoord = [self.mapView convertPoint:CGPointMake(0, mapPadding.right) toCoordinateFromView:self.mapView];
    CLLocationCoordinate2D bottomCoord = [self.mapView convertPoint:CGPointMake(0, mapPadding.bottom) toCoordinateFromView:self.mapView];
    CLLocationCoordinate2D leftCoord = [self.mapView convertPoint:CGPointMake(0, mapPadding.left) toCoordinateFromView:self.mapView];
    
    double latitudeSpanToBeAddedToTop = relativeFromCoord.latitude - topCoord.latitude;
    double longitudeSpanToBeAddedToRight = relativeFromCoord.latitude - rightCoord.latitude;
    double latitudeSpanToBeAddedToBottom = relativeFromCoord.latitude - bottomCoord.latitude;
    double longitudeSpanToBeAddedToLeft = relativeFromCoord.latitude - leftCoord.latitude;
    
    maxLatitude = maxLatitude + latitudeSpanToBeAddedToTop;
    minLatitude = minLatitude - latitudeSpanToBeAddedToBottom;
    
    maxLongitude = maxLongitude + longitudeSpanToBeAddedToRight;
    minLongitude = minLongitude - longitudeSpanToBeAddedToLeft;
    
    [self setMapRegionForMinLat:minLatitude minLong:minLongitude maxLat:maxLatitude maxLong:maxLongitude];
}

-(void) setMapRegionForMinLat:(double)minLatitude minLong:(double)minLongitude maxLat:(double)maxLatitude maxLong:(double)maxLongitude {
    
    MKCoordinateRegion region;
    region.center.latitude = (minLatitude + maxLatitude) / 2;
    region.center.longitude = (minLongitude + maxLongitude) / 2;
    region.span.latitudeDelta = (maxLatitude - minLatitude);
    region.span.longitudeDelta = (maxLongitude - minLongitude);
    
    // MKMapView BUG: this snaps to the nearest whole zoom level, which is wrong- it doesn't respect the exact region you asked for. See http://stackoverflow.com/questions/1383296/why-mkmapview-region-is-different-than-requested
    [self.mapView setRegion:region animated:YES];
}


@end
