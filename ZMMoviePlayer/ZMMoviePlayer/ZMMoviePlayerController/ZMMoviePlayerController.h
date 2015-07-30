//
//  ZMMoviePlayerController.h
//  ZMMoviePlayer
//
//  Created by Leo on 15/7/15.
//  Copyright (c) 2015年 Leo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface ZMMoviePlayerController : MPMoviePlayerController

@property (nonatomic, assign) CGRect videoViewFrame;
@property (nonatomic, weak) UIView* superView;

- (id)initWithContentURL:(NSURL *)url andWithVideoViewFrame:(CGRect)frame;

@end
