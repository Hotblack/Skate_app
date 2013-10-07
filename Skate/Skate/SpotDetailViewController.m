//
//  SpotViewController.m
//  Skate
//
//  Copyright (c) 2013 Skate App. All rights reserved.
//

#import "SpotDetailViewController.h"

@interface SpotDetailViewController ()
@property (weak, nonatomic) NSString *username;
@end

@implementation SpotDetailViewController

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
    self.title = [self.spot title];
    
    /* add image from URL to detail view */
    NSURL * imageURL = [NSURL URLWithString:[[self spot] imageFileURL]];
    self.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageURL]];
    
    /* add user credit */
    self.usernameLabel.adjustsFontSizeToFitWidth = NO; //formatting for newline to work
    self.usernameLabel.numberOfLines = 0;
    
    self.usernameLabel.text = [NSString stringWithFormat:@"Added by %@", [self.spot username]];
    
    /* add comments to commentsLabel */
    self.commentsLabel.adjustsFontSizeToFitWidth = NO;
    self.commentsLabel.numberOfLines = 0;
    
    self.commentsLabel.text = @"";
    for (id object in [self.spot comments]) {
        self.commentsLabel.text = [NSString stringWithFormat:@"%@\nuser: %@\ntime: %@\n\n%@", [object valueForKey:@"content"], [object valueForKey:@"username"], [self dateToStringInterval:[object valueForKey:@"updated_at"]], self.commentsLabel.text];
    }
    self.commentsLabel.text = [NSString stringWithFormat:@"Comments: \n\n%@", self.commentsLabel.text];
    if (self.username) {
        [self.commentButton setEnabled:YES];
    } else {
        [self.commentButton setEnabled:NO];
    }
}

/* press the comment button and opens UIAlertView for a new comment */
- (IBAction)commentButtonPressed:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[[self spot] title] message:@"Enter your comment:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView show];
}

/* pushes the comment to API after OK button is pressed. Since we don't need to upload an image, we
 can use JSON which is relatively easy to work with. */
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex!=0)
    {
        NSString *commentContent = [alertView textFieldAtIndex:0].text;
        NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionary];
        [mutableParameters setObject:self.username forKey:@"username"];
        [mutableParameters setObject:[[self spot] idNumber] forKey:@"spot_id"];
        [mutableParameters setObject:commentContent forKey:@"content"];
        
        NSURL *url = [NSURL URLWithString:@"https://skateappnyu.herokuapp.com/comments"];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        NSData *requestData = [NSJSONSerialization dataWithJSONObject:mutableParameters options:0 error:nil];
        
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"%d", [requestData length]] forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody: requestData];
        
        NSURLResponse *response;
        NSError *error;
        NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if (!error && returnData) {
            NSString *content = [NSString stringWithUTF8String:[returnData bytes]];
            if (content) {
                // use JSON response to add comment to this view
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:returnData options:NSJSONReadingMutableLeaves error:nil];
                [[self spot] addComment:json];
                [self viewDidLoad];
            } else {
                /* unable to parse JSON response, but the comment was still
                 posted successfully so use mutableParameters to update view */
                [[self spot] addComment:mutableParameters];
                [self viewDidLoad];
            }
        } else { // comment failed. show error message
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Comment Failed" message:@"Try Again Maybe" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
            alertView.alertViewStyle = UIAlertViewStyleDefault;
            [alertView show];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (id)initWithSpot:(Spot *)spot andUsername:(NSString *)username
{
    self = [super init];
    if (self) {
        // Custom initialization
    }
    self.spot = spot;
    self.username = username;
    return self;
}

/* taken from http://fieldforceapp.blogspot.com/2010/05/nsdate-formatting-how-long-ago.html */
- (NSString *)dateToStringInterval:(NSString *)pastDateString
//! Method to return a string "xxx days ago" based on the difference between pastDate and the current date and time.
{
    /* date formatter */
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    NSDate *pastDate = [dateFormatter dateFromString:pastDateString];
    
    // Get the system calendar
    NSCalendar *sysCalendar = [NSCalendar currentCalendar];
    
    // Create the current date
    NSDate *currentDate = [[NSDate alloc] init];
    
    // Get conversion to months, days, hours, minutes
    unsigned int unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit;
    
    NSDateComponents *breakdownInfo = [sysCalendar components:unitFlags fromDate:currentDate  toDate:pastDate  options:0];
    
    //NSLog(@"Break down: %dmin %dhours %ddays %dmoths",[breakdownInfo minute], [breakdownInfo hour], [breakdownInfo day], [breakdownInfo month]);
    
    NSString *intervalString;
    if ([breakdownInfo month]) {
        if (-[breakdownInfo month] > 1)
            intervalString = [NSString stringWithFormat:@"%d months ago", -[breakdownInfo month]];
        else
            intervalString = @"1 month ago";
    }
    else if ([breakdownInfo day]) {
        if (-[breakdownInfo day] > 1)
            intervalString = [NSString stringWithFormat:@"%d days ago", -[breakdownInfo day]];
        else
            intervalString = @"1 day ago";
    }
    else if ([breakdownInfo hour]) {
        if (-[breakdownInfo hour] > 1)
            intervalString = [NSString stringWithFormat:@"%d hours ago", -[breakdownInfo hour]];
        else
            intervalString = @"1 hour ago";
    }
    else {
        if (-[breakdownInfo minute] > 1)
            intervalString = [NSString stringWithFormat:@"%d minutes ago", -[breakdownInfo minute]];
        else
            intervalString = @"1 minute ago";
    }
    
    return intervalString;
}


@end
