//
//  SpotDetailViewController.h
//  Skate
//
//  Copyright (c) 2013 Skate App. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Spot.h"

@interface SpotDetailViewController : UIViewController

@property (strong, nonatomic) Spot *spot;
@property (strong, nonatomic) IBOutlet UILabel *usernameLabel;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UILabel *commentsLabel;
@property (strong, nonatomic) IBOutlet UIButton *commentButton;

- (id)initWithSpot:(Spot *)spot andUsername:(NSString *)username;

@end
