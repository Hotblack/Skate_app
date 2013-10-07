//
//  MeetupDetailViewController.h
//  Skate
//
//  Copyright (c) 2013 Skate App. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Meetup.h"
#import <FacebookSDK/FacebookSDK.h>

@interface MeetupDetailViewController : UIViewController

@property (strong, nonatomic) Meetup *meetup;
@property (strong, nonatomic) IBOutlet UILabel *meetupOwnerLabel;
@property (strong, nonatomic) IBOutlet FBProfilePictureView *meetupOwnerPicture;
@property (strong, nonatomic) IBOutlet UILabel *timestampLabel;
@property (strong, nonatomic) IBOutlet UILabel *descriptionView;
@property (strong, nonatomic) IBOutlet UILabel *commentsView;
@property (strong, nonatomic) IBOutlet UIButton *commentButton;

-(id) initWithMeetup:(Meetup *) meetup andUserID:(NSString *) userID andUsername:(NSString *)userName;

@end
