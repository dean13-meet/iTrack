//
//  UIView+HeightResize.m
//  iTrack5
//
//  Created by Dean Leitersdorf on 5/4/15.
//  Copyright (c) 2015 Dean Leitersdorf. All rights reserved.
//

#import "UIView+HeightResize.h"

@implementation UIView (HeightResize)

+(void)resizeHeightForView:(UIView *)view
{
	int maxHeight = 0;
	
	for(UIView* sub in view.subviews)
	{
		int temp = sub.frame.origin.y + sub.frame.size.height;
		if(temp>maxHeight)maxHeight = temp;
	}
	
	view.frame = CGRectMake(view
							.frame.origin.x, view.frame.origin.y, view.frame.size.width, maxHeight+8);
}

@end
