//
//  Meetup.m
//  Skate
//
//  Created by Corinne A Taylor on 5/5/13.
//  Copyright (c) 2013 Skate App. All rights reserved.
//

#import "Meetup.h"

static NSString *NSStringFromCoordinate (CLLocationCoordinate2D coordinate) {
    return [NSString stringWithFormat:@"(%f, %f)", coordinate.latitude, coordinate.longitude];
}

@interface Meetup ()
@property (assign, nonatomic, readwrite) CLLocationDegrees latitude;
@property (assign, nonatomic, readwrite) CLLocationDegrees longitude;
@end


@implementation Meetup
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
    _description = [attributes valueForKey:@"description"];
    _facebookid = [attributes valueForKey:@"fbid"];
    
    if ([attributes valueForKey:@"comments"]) {
        _comments = [[attributes valueForKey:@"comments"] mutableCopy];
    } else {
        _comments = [[NSMutableArray alloc] init];
    }
    _idNumber = [attributes valueForKey:@"id"];
    _timestamp = [attributes valueForKey:@"created_at"];
    return self;
}

/* This returns the description of the meetup. Required for MKAnnotation. */
- (NSString *)title {
    if ([_description isKindOfClass:[NSNull class]])
        return @"Unknown Meetup";
    else
        return _description;
}

- (NSMutableArray *)addComment:(NSDictionary *)comment {
    [_comments addObject:comment];
    return _comments;
}

/* This method uses the latitude and longitude values to return a CLLocation */
- (CLLocation *)location {
    return [[CLLocation alloc] initWithLatitude:self.latitude longitude:self.longitude];
}

- (NSString *)meetupDescription {
    if ([_description isKindOfClass:[NSNull class]])
        return @"[No description available.]";
    else
        return _description;
}

- (NSString *)idNumber {
    if ([_idNumber isKindOfClass:[NSNull class]])
        return @"";
    else
        return _idNumber;
}

- (NSString *)facebookid {
    if ([_facebookid isKindOfClass:[NSNull class]]) {
        return nil;
    } else {
        return _facebookid;
    }
}

/* returns array of NSDictionary */
- (NSMutableArray *)comments {
    NSMutableArray *commentsArray = [[NSMutableArray alloc] init];
    for (id object in _comments) {
        [commentsArray addObject:object];
    }
    return commentsArray;
}

- (NSString *)timestamp {
    if ([_timestamp isKindOfClass:[NSNull class]]) {
        return nil;
    } else {
        return _timestamp;
    }
}

- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake(self.latitude, self.longitude);
}

/* This method lets us create a new spot. Since we don't need to upload an image, we
 can use JSON which is relatively easy to work with. */
+ (void)createNewMeetupAtLocation:(CLLocation *)location
                       facebookid:(NSString *)facebookid
                      description:(NSString *)description
                            block:(void (^)(Meetup *spot, NSError *error))block
{
    NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionary];
    [mutableParameters setObject:facebookid forKey:@"fbid"];
    [mutableParameters setObject:description forKey:@"description"];
    [mutableParameters setObject:[NSNumber numberWithDouble:location.coordinate.latitude] forKey:@"lat"];
    [mutableParameters setObject:[NSNumber numberWithDouble:location.coordinate.longitude] forKey:@"lng"];
    
    NSLog(@"jsonRequest is %@", mutableParameters);
    
    NSURL *url = [NSURL URLWithString:@"https://skateappnyu.herokuapp.com/meetups"];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    /* convert our NSMutableDictionary to JSON for our POST request */
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:mutableParameters options:0 error:nil];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%d", [requestData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody: requestData];
    
    NSURLResponse *response;
    NSError *error;
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    /* for debugging */
    //NSString *content = [NSString stringWithUTF8String:[returnData bytes]];
    //NSLog(@"response is %@", content);
    
    if (!error && returnData) {
        // If successful, use the JSON response to our HTTP request to create a new Meetup class
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:returnData options:NSJSONReadingMutableLeaves error:nil];
        Meetup *meetup = [[Meetup alloc] initWithAttributes:json];
        block(meetup, nil);
    }
    else{
        block(nil, nil); // should return error
    }
}

@end
