//
//  UIView+HeightResize.h
//  iTrack5
//
//  Created by Dean Leitersdorf on 5/4/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (HeightResize)

+(void)resizeHeightForView:(UIView*)view;//takes the view, loops through its subviews, and sets the view's height so that it is 8 + the y origin of its lowest view + the height of its lowest view, where lowest view is defined as the view with y origin + height is maximum

@end
