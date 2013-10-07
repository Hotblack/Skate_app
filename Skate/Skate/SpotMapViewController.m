//
//  SpotMapViewController.m
//  Skate
//
//  Made with the help of https://devcenter.heroku.com/articles/ios-photo-sharing-geo-location-service#create-a-photos-view-controller
//

#import "SpotMapViewController.h"
#import "Spot.h"
#import "SpotDetailViewController.h"
#import "Meetup.h"
#import "MeetupDetailViewController.h"
#import "AppDelegate.h"
#import <FacebookSDK/FacebookSDK.h>

static CLLocationDistance const kMapRegionSpanDistance = 2500;

@interface SpotMapViewController ()
@property (strong, nonatomic, readwrite) CLLocationManager *locationManager;
@property BOOL postSpot;
@property (strong, nonatomic, readwrite) NSString *facebookid;
@end

@implementation SpotMapViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    /* sets the title as it will appear in the tab bar */
    self.title = NSLocalizedString(@"Skate Map", nil);
    
    /* Gets a JSON file from the API and uses it to fill instances of the Spot class. */
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //code executed in the background
        NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://skateappnyu.herokuapp.com/spots.json"]];
        NSDictionary* json = nil;
        if (data) {
            json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            //code executed on the main queue
            [self updateUIWithDictionary: json andKind:@"spots"];
        });
    });
    
    // Check the session for a cached token to show the proper authenticated
    // UI. However, since this is not user intitiated, do not show the login UX.
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate openSessionWithAllowLoginUI:NO];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(sessionStateChanged:)
     name:SessionStateChangedNotification
     object:nil];
    
    self.spotname = [[NSString alloc] init];
    
    /* code to track user's location */
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    self.locationManager.distanceFilter = 80.0f;
    [self.locationManager startUpdatingLocation];
    
    /* buttons */
    UIBarButtonItem *currentLocationButton = [[UIBarButtonItem alloc] initWithTitle:@"Location" style:UIBarButtonItemStyleBordered target:self action:@selector(zoomToLocation:)];
    self.navigationItem.rightBarButtonItem = currentLocationButton;
    [self updateButtons];
    
    [self viewMeetups:self]; //load meetups
}

/* change toolbar and navbar to reflect login status */
- (void)updateButtons {
    if (self.username) {
        UIBarButtonItem *loginButton = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStyleBordered target:self action:@selector(loginWithFacebook:)];
        self.navigationItem.leftBarButtonItem = loginButton;
        
        UIBarButtonItem *newSpotButton = [[UIBarButtonItem alloc] initWithTitle:@"Add Current Location" style:UIBarButtonItemStyleBordered target:self action:@selector(takePhoto:)];
        UIBarButtonItem *meetupButton = [[UIBarButtonItem alloc] initWithTitle:@"Start Meetup" style:UIBarButtonItemStyleBordered target:self action:@selector(createMeetup:)];
        NSArray *items = [NSArray arrayWithObjects:newSpotButton, meetupButton, nil];
        self.toolbarItems = items;
    } else {
        UIBarButtonItem *loginButton = [[UIBarButtonItem alloc] initWithTitle:@"Login with Facebook" style:UIBarButtonItemStyleBordered target:self action:@selector(loginWithFacebook:)];
        NSArray *items = [NSArray arrayWithObjects:loginButton, nil];
        self.toolbarItems = items;
        self.navigationItem.leftBarButtonItem = nil;
    }
}

/* updates map UI with "spots" or "meetups" */
- (void)updateUIWithDictionary:(NSDictionary*)json andKind:(NSString *)spotsOrMeetups {
    @try {
        if ([spotsOrMeetups isEqualToString:@"spots"]) {
            for (id object in [json objectForKey:@"spots"]) {
                Spot *spot = [[Spot alloc] initWithAttributes:object];
                [self.mapView addAnnotation:spot];
            }
        }
        if ([spotsOrMeetups isEqualToString:@"meetups"]) {
            for (id object in [json objectForKey:@"meetups"]) {
                Meetup *meetup = [[Meetup alloc] initWithAttributes:object];
                [self.mapView addAnnotation:meetup];
            }
        }
    }
    @catch (NSException *exception) {
        [[[UIAlertView alloc] initWithTitle:@"Error"
                                    message:@"Failed to load new spots/meetups. (Could not parse the JSON feed.)"
                                   delegate:nil
                          cancelButtonTitle:@"Close"
                          otherButtonTitles: nil] show];
        NSLog(@"Exception: %@", exception);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadView {
    [super loadView];
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    [self.view addSubview:self.mapView];
}

/* Zooms in to user location after update. */
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(manager.location.coordinate, kMapRegionSpanDistance, kMapRegionSpanDistance) animated:YES];
}

/* Sets the appearance for annotations (pins) on the map. Also adds the buttons next to the titles. */
- (MKAnnotationView *)mapView:(MKMapView *)mapView
            viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ( !( [annotation isKindOfClass:[Spot class]] || [annotation isKindOfClass:[Meetup class]] ) ) {
        return nil;
    }
    
    static NSString *AnnotationIdentifier = @"Pin";
    MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:AnnotationIdentifier];
    annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationIdentifier];
    
    /* this code handles annotation button clicks */
    annotationView.canShowCallout = YES;
    UIButton *detailButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    annotationView.rightCalloutAccessoryView = detailButton;
    annotationView.enabled = YES;
    
    /* Spots are red. Meetups are blue. */
    if ([annotation isKindOfClass:[Spot class]]) {
        annotationView.image = [UIImage imageNamed:@"pinRed.png"];
    } else if ([annotation isKindOfClass:[Meetup class]]) {
        annotationView.image = [UIImage imageNamed:@"pinBlue.png"];
    }
    /* alignment for pin images */
    annotationView.centerOffset = CGPointMake(9, -16);
    annotationView.calloutOffset = CGPointMake(-8, 0);
    
    annotationView.annotation = annotation;
    return annotationView;
}

/* This method lets us choose what to do when a button for a Spot or Meetup is pressed. */
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    id<MKAnnotation> selectedAnn = view.annotation;
    
    if ([selectedAnn isKindOfClass:[Spot class]]) {
        Spot *spot = (Spot *)selectedAnn;
        [[self navigationController] pushViewController:[[SpotDetailViewController alloc] initWithSpot:spot andUsername:self.username] animated:YES];
    }
    else if ([selectedAnn isKindOfClass:[Meetup class]]) {
        Meetup *meetup = (Meetup *)selectedAnn;
        [[self navigationController] pushViewController:[[MeetupDetailViewController alloc] initWithMeetup:meetup andUserID:@"testID" andUsername:self.username] animated:YES];
    } else {
        NSLog(@"selected annotation (not a Spot or Meetup) = %@", selectedAnn);
    }
}

#pragma mark - Actions

- (void)viewMeetups:(id)sender {
    /* Gets a JSON file from the API and uses it to fill instances of the Spot class. */
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //code executed in the background
        NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://skateappnyu.herokuapp.com/meetups.json"]];
        NSDictionary* json = nil;
        if (data) {
            json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            //code executed on the main queue
            [self updateUIWithDictionary:json andKind:@"meetups"];
        });
        
    });
}

/* Open LoginViewController to login with Facebook */
- (void)loginWithFacebook:(id)sender {
    
    AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    if (FBSession.activeSession.isOpen) {
        [appDelegate closeSession];
    } else {
        // The person has initiated a login, so call the openSession method
        // and show the login UX if necessary.
        [appDelegate openSessionWithAllowLoginUI:YES];
    }
}

/* Lets the user take a photo if the camera is available, 
 otherwise open saved photo album. Then create a spot. */
- (void)takePhoto:(id)sender {
    self.postSpot = YES;
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Spot Name" message:@"Enter a name for the spot:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView show];
}

/* Create meetup instead of spot */
- (void)createMeetup:(id)sender {
    self.postSpot = NO;
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Meetup Description" message:@"Enter a description for the meetup:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex != 0 && self.postSpot)
    {
        self.spotname = [alertView textFieldAtIndex:0].text;
        UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
         sourceType = UIImagePickerControllerSourceTypeCamera;
         }
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.delegate = self;
        imagePickerController.sourceType = sourceType;
        imagePickerController.allowsEditing = YES;
        [self presentViewController:imagePickerController animated:NO completion:nil];
    } else if (buttonIndex != 0) {
        self.spotname = [alertView textFieldAtIndex:0].text;
        [Meetup createNewMeetupAtLocation:self.locationManager.location facebookid:self.facebookid description:[alertView textFieldAtIndex:0].text block:^(Meetup *meetup, NSError *error) {
            if (error) {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Upload Failed", nil) message:[error localizedFailureReason] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil] show];
            } else {
                [self.mapView addAnnotation:meetup];
            }
        }];
    }
}

#pragma mark - UIImagePickerControllerDelegate

/* Create new spot after image was chosen */
- (void)imagePickerController:(UIImagePickerController *)imagePickerController
        didFinishPickingImage:(UIImage *)image
                  editingInfo:(NSDictionary *)editingInfo
{
    [imagePickerController dismissModalViewControllerAnimated:YES];
    [Spot createNewSpotAtLocation:self.locationManager.location image:image name:self.spotname username:self.username block:^(Spot *spot, NSError *error) {
        if (error) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Upload Failed", nil) message:[error localizedFailureReason] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil] show];
        } else {
            [self.mapView addAnnotation:spot];
        }
    }];
}

- (void)loginFailed
{
    // User switched back to the app without authorizing
}

-(void)zoomToLocation:(id)sender
{
    
    [self.mapView setCenterCoordinate:self.mapView.userLocation.location.coordinate animated:YES];
    
}

- (void)sessionStateChanged:(NSNotification*)notification {
    if (FBSession.activeSession.isOpen) {
        [FBRequestConnection
         startForMeWithCompletionHandler:^(FBRequestConnection *connection,
                                           id<FBGraphUser> user,
                                           NSError *error) {
             if (!error) {
                 /* do username update */
                 self.username = user.name;
                 [self updateButtons]; // update UI
                 
                 [FBRequestConnection startForMeWithCompletionHandler:
                  ^(FBRequestConnection *connection, id result, NSError *error)
                  {
                      if ([result isKindOfClass:[NSDictionary class]]) {
                          self.facebookid = [(NSDictionary *)result objectForKey:@"id"];
                      }
                  }];
             }
         }];
    } else {
        /* set username and facebook id to nil after logout */
        self.username = nil;
        self.facebookid = nil;
        [self updateButtons]; // update UI
    }
}

@end
