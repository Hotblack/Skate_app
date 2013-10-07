//
//  UserViewController.m
//  Skate
//
//  Created by Midground on 5/3/13.
//  Copyright (c) 2013 Skate App. All rights reserved.
//

#import "UserViewController.h"
#import "AppDelegate.h"
#import <FacebookSDK/FacebookSDK.h>

@interface UserViewController ()

<UITableViewDataSource,
UITableViewDelegate, FBFriendPickerDelegate>

@property (strong, nonatomic) IBOutlet FBProfilePictureView *userProfileImage;
@property (strong, nonatomic) IBOutlet UILabel *userNameLabel;
@property (strong, nonatomic) IBOutlet UITableView *menuTableView;
@property (strong, nonatomic) FBFriendPickerViewController *friendPickerController;
@property (strong, nonatomic) NSArray* selectedFriends;

@end



@implementation UserViewController

@synthesize friendPickerController = _friendPickerController;
@synthesize selectedFriends = _selectedFriends;

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
    // Do any additional setup after loading the view from its nib.
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(sessionStateChanged:)name:SessionStateChangedNotification object:nil];
    
    self.title = @"test";
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.friendPickerController = nil;
}

- (void)populateUserDetails
{
    if (FBSession.activeSession.isOpen) {
        [[FBRequest requestForMe] startWithCompletionHandler:
         ^(FBRequestConnection *connection,
           NSDictionary<FBGraphUser> *user,
           NSError *error) {
             if (!error) {
                 self.userName = user.name;
                 self.userNameLabel.text = self.userName;
                 self.userProfileImage.profileID = user.id;
             }
         }];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if (FBSession.activeSession.isOpen) {
        [self populateUserDetails];
    }
}

- (void)sessionStateChanged:(NSNotification*)notification {
    [self populateUserDetails];
}

- (NSString*) getUserName{
    return self.userName;
}

//Profile Page Table info. This code runs but is NOT COMPLETE and only has functionality for 1 of the options

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = (UITableViewCell*)[tableView
                                               dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell.textLabel.font = [UIFont systemFontOfSize:16];
        cell.textLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
        cell.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        cell.textLabel.clipsToBounds = YES;
        
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
        cell.detailTextLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
        cell.detailTextLabel.textColor = [UIColor colorWithRed:0.4
                                                         green:0.6
                                                          blue:0.8
                                                         alpha:1];
        cell.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        cell.detailTextLabel.clipsToBounds = YES;
    }
    
    switch (indexPath.row) {
            /*Images are something we can think about, but are commented out for now.
             The image files referenced here are from the sample code in the facebook SDK
             they should be removed/changed before we turn this in.
             ONLY THE MY FRIENDS SECTION HAS CODE IMPLEMENTATION BEHIND IT*/
        case 0:
            cell.textLabel.text = @"Favorite Spots";
            cell.detailTextLabel.text = @"Your favorite places to shred"; //shred is a cool word, right guys?
            //cell.imageView.image = [UIImage imageNamed:@"action-eating.png"];
            break;
            
        case 1:
            cell.textLabel.text = @"My Spots";
            cell.detailTextLabel.text = @"Spots that you have uploaded";
            //cell.imageView.image = [UIImage imageNamed:@"action-location.png"];
            break;
            
        case 2:
            cell.textLabel.text = @"My Tricks"; // This could be comments or something else
            cell.detailTextLabel.text = @"Tricks that you have uploaded";
            //cell.imageView.image = [UIImage imageNamed:@"action-people.png"];
            break;
            
        case 3:
            cell.textLabel.text = @"My Friends";
            cell.detailTextLabel.text = @"The people you know who are also using skate.app";
            //cell.imageView.image = [UIImage imageNamed:@"action-photo.png"];
            break;
            
        default:
            break;
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//TODO: add functionality for the other cases
    switch (indexPath.row) {
        case 3:
            if (!self.friendPickerController) {
                self.friendPickerController = [[FBFriendPickerViewController alloc]
                                               initWithNibName:nil bundle:nil];
                
                /*Should set the picker to only show friends that have the app installed
                 Comment out both lines and method below to display all friends*/
                NSSet *fields = [NSSet setWithObjects:@"installed", nil];
                self.friendPickerController.fieldsForRequest = fields;
                
                
                // Set the friend picker delegate
                self.friendPickerController.delegate = self;
                self.friendPickerController.title = @"Select friends";
            }
            
            [self.friendPickerController loadData];
            [self.navigationController pushViewController:self.friendPickerController
                                                 animated:true];
            break;
    }
}

- (void)updateCellIndex:(int)index withSubtitle:(NSString*)subtitle {
    UITableViewCell *cell = (UITableViewCell *)[self.menuTableView
                                                cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    cell.detailTextLabel.text = subtitle;
}

/*Right now lets you select multiple friends and only shows who you have selected, future implementation could take you to a profile page? */
- (void)updateSelections
{
    
    NSString* friendsSubtitle = @"Select friends";
    int friendCount = self.selectedFriends.count;
    if (friendCount > 2) {
        // Just to mix things up, don't always show the first friend.
        id<FBGraphUser> randomFriend =
        [self.selectedFriends objectAtIndex:arc4random() % friendCount];
        friendsSubtitle = [NSString stringWithFormat:@"%@ and %d others",
                           randomFriend.name,
                           friendCount - 1];
    } else if (friendCount == 2) {
        id<FBGraphUser> friend1 = [self.selectedFriends objectAtIndex:0];
        id<FBGraphUser> friend2 = [self.selectedFriends objectAtIndex:1];
        friendsSubtitle = [NSString stringWithFormat:@"%@ and %@",
                           friend1.name,
                           friend2.name];
    } else if (friendCount == 1) {
        id<FBGraphUser> friend = [self.selectedFriends objectAtIndex:0];
        friendsSubtitle = friend.name;
    }
    [self updateCellIndex:2 withSubtitle:friendsSubtitle];
}

- (void)friendPickerViewControllerSelectionDidChange:
(FBFriendPickerViewController *)friendPicker
{
    self.selectedFriends = friendPicker.selection;
    [self updateSelections];
}

/*Method to limit friend list to show only friends with the app installed, untested, approach with caution
 Comment out this method and two lines above in didSelectRowAtIndexPath to show all friends*/
-(BOOL)friendPickerViewController:(FBFriendPickerViewController *)friendPicker shouldIncludeUser:(id<FBGraphUser>)user{
    BOOL installed = [user objectForKey:@"installed"] != nil;
    return installed;
}

@end
