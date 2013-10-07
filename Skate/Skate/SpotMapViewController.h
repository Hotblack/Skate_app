//
//  SpotMapViewController.h
//  Skate
//
//  Made with the help of https://devcenter.heroku.com/articles/ios-photo-sharing-geo-location-service#create-a-photos-view-controller
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface SpotMapViewController : UIViewController <CLLocationManagerDelegate, MKMapViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
@private
    CLLocationManager *_locationManager;
    UIActivityIndicatorView *_activityIndicatorView;
}
@property (strong, nonatomic) NSString *spotname;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) NSString *username;

@end
