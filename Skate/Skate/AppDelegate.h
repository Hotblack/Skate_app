//
//  AppDelegate.h
//  Skate
//
//  Created by Chris Williams on 5/1/13.
//  Copyright (c) 2013 Skate App. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const SessionStateChangedNotification;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *navigationController;

- (BOOL)openSessionWithAllowLoginUI:(BOOL)allowLoginUI;
- (void)closeSession;

@end
