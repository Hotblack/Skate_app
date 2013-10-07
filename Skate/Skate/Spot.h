//
//  Spot.h
//  Skate
//
//  Created by Chris Williams on 5/1/13.
//  Made with the help of https://devcenter.heroku.com/articles/ios-photo-sharing-geo-location-service#create-a-photo-class
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface Spot : NSObject <MKAnnotation> {
    @private
    CLLocationDegrees _latitude;
    CLLocationDegrees _longitude;
    NSString *_name;
    NSString *_imageFileURL;
    NSString *_description;
    NSMutableArray *_comments;
    NSString *_idNumber;
    NSString *_username;
}

@property (strong, nonatomic, readonly) CLLocation *location;

- (NSString *)spotDescription;
- (NSString *)imageFileURL;
- (NSMutableArray *)comments;
- (NSString *)idNumber;
- (NSMutableArray *)addComment:(NSDictionary *)comment;
- (NSString *)username;

+ (void)createNewSpotAtLocation:(CLLocation *)location
                          image:(UIImage *)image
                           name:(NSString *)newSpotName
                       username:(NSString *)username
                          block:(void (^)(Spot *spot, NSError *error))block;
- (id)initWithAttributes:(NSDictionary *)attributes;
@end
