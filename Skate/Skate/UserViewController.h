//
//  UserViewController.h
//  Skate
//
//  Created by Midground on 5/3/13.
//  Copyright (c) 2013 Skate App. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserViewController : UIViewController

@property (strong, nonatomic) NSString *userName;

-(NSString*) getUserName;

@end
