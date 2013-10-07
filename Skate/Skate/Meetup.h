//
//  Meetup.h
//  Skate
//
//  Created by Corinne A Taylor on 5/5/13.
//  Copyright (c) 2013 Skate App. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface Meetup : NSObject <MKAnnotation>{
@private
    CLLocationDegrees _latitude;
    CLLocationDegrees _longitude;
    NSString *_description;
    NSMutableArray *_comments;
    NSString *_idNumber;
    NSString *_facebookid;
    NSString *_timestamp;
}
@property (strong, nonatomic, readonly) CLLocation *location;

- (NSString *)meetupDescription;
- (NSMutableArray *)comments;
- (NSString *)idNumber;
- (NSMutableArray *)addComment:(NSDictionary *)comment;
- (NSString *)facebookid;
- (NSString *)timestamp;

+ (void)createNewMeetupAtLocation:(CLLocation *)location
                       facebookid:(NSString *)facebookid
                      description:(NSString *)description
                            block:(void (^)(Meetup *meetup, NSError *error))block;
- (id)initWithAttributes:(NSDictionary *)attributes;

@end
