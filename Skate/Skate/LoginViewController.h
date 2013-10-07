//
//  LoginViewController.h
//  Skate
//
//  Created by Midground on 5/3/13.
//  Copyright (c) 2013 Skate App. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LoginViewController;

/* delegate to handle username after login */
@protocol LoginViewControllerDelegate <NSObject>

- (void)setUsername:(LoginViewController *)controller didFinishUsername:(NSString *)username;
@end

@interface LoginViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIButton *loginButton;
@property (nonatomic, weak) id <LoginViewControllerDelegate> delegate;

- (void)loginFailed;

@end
