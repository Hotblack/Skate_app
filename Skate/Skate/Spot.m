//
//  Spot.m
//  Skate
//
//  Created by Chris Williams on 5/1/13.
//  Made with the help of https://devcenter.heroku.com/articles/ios-photo-sharing-geo-location-service#create-a-photo-class
//

#import "Spot.h"

static CGFloat const kJPEGQuality = 0.6;

static NSString *NSStringFromCoordinate (CLLocationCoordinate2D coordinate) {
    return [NSString stringWithFormat:@"(%f, %f)", coordinate.latitude, coordinate.longitude];
}

@interface Spot ()
@property (assign, nonatomic, readwrite) CLLocationDegrees latitude;
@property (assign, nonatomic, readwrite) CLLocationDegrees longitude;
@end

@implementation Spot
@synthesize latitude = _latitude;
@synthesize longitude = _longitude;
@dynamic location;

- (id)initWithAttributes:(NSDictionary *)attributes {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    /* Since the values in attributes should match the values in the JSON from the API,
     we can use it to fill the values in this Objective-C class. */
    self.latitude = [[attributes valueForKeyPath:@"lat"] doubleValue];
    self.longitude = [[attributes valueForKeyPath:@"lng"] doubleValue];
    _name = [attributes valueForKey:@"name"];
    _imageFileURL = [attributes valueForKey:@"image_url"];
    _description = [attributes valueForKey:@"description"];
    _username = [attributes valueForKey:@"username"];
    
    if ([attributes valueForKey:@"comments"]) {
        _comments = [[attributes valueForKey:@"comments"] mutableCopy];
    } else {
        _comments = [[NSMutableArray alloc] init];
    }
    
    _idNumber = [attributes valueForKey:@"id"];
    return self;
}

/* Add comment to this Spot model. Does not add comment to web API. */
- (NSMutableArray *)addComment:(NSDictionary *)comment {
    [_comments addObject:comment];
    return _comments;
}

/* This method uses the latitude and longitude values to return a CLLocation */
- (CLLocation *)location {
    return [[CLLocation alloc] initWithLatitude:self.latitude longitude:self.longitude];
}

/* This returns the name of the spot. Required for MKAnnotation. */
- (NSString *)title {
    if ([_name isKindOfClass:[NSNull class]])
        return @"Unknown Name";
    else
        return _name;
}

- (NSString *)spotDescription {
    if ([_description isKindOfClass:[NSNull class]])
        return @"[No description available.]";
    else
        return _description;
}

- (NSString *)imageFileURL {
    if ([_imageFileURL isKindOfClass:[NSNull class]])
        return @"";
    else
        return _imageFileURL;
}

- (NSString *)idNumber {
    if ([_idNumber isKindOfClass:[NSNull class]])
        return @"";
    else
        return _idNumber;
}

- (NSString *)username {
    if ([_username isKindOfClass:[NSNull class]]) {
        return @"Unknown User";
    } else {
        return _username;
    }
}

/* Returns an array of NSDictionary */
- (NSMutableArray *)comments {
    NSMutableArray *commentsArray = [[NSMutableArray alloc] init];
    for (id object in _comments) {
        [commentsArray addObject:object];
    }
    return commentsArray;
}

- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake(self.latitude, self.longitude);
}

/* This method lets us create a new spot. In order for image uploading to
 work we need to do a multipart/form-data HTTP POST request. */
+ (void)createNewSpotAtLocation:(CLLocation *)location
                          image:(UIImage *)image
                           name:(NSString *)spotName
                       username:(NSString *)username
                          block:(void (^)(Spot *spot, NSError *error))block
{
    NSURL *url = [NSURL URLWithString:@"http://skateappnyu.herokuapp.com/spots"]; // url of API to send request to
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    NSString *boundary = @"---------------------------14737809831466499882746641449"; // boundary can be any random string
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSMutableData *body = [NSMutableData data];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Disposition: form-data; name=\"spot[image]\"; filename=\"spot.jpg\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[NSData dataWithData:UIImageJPEGRepresentation(image, kJPEGQuality)]]; // includes the image
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"spot[name]\"\r\n\r\n%@", spotName] dataUsingEncoding:NSUTF8StringEncoding]];
    
    if (username) { // username should always be true when this method is called
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"spot[username]\"\r\n\r\n%@", username] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"spot[lat]\"\r\n\r\n%@", [NSNumber numberWithDouble:location.coordinate.latitude]] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"spot[lng]\"\r\n\r\n%@", [NSNumber numberWithDouble:location.coordinate.longitude]] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [request setHTTPBody:body];
    
    /* for debugging */
    //NSString *requestString = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
    //NSLog(@"request is %@", requestString);
    
    NSURLResponse *response;
    NSError *error;
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if (!error && returnData) {
        // If successful, use the JSON response to our HTTP request to create a new Spot class
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:returnData options:NSJSONReadingMutableLeaves error:nil];
        Spot *spot = [[Spot alloc] initWithAttributes:json];
        block(spot, nil);
    }
    else{
        block(nil, nil); // should return error
    }
}

@end
