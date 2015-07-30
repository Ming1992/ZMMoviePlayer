//
//  ViewController.m
//  ZMMoviePlayer
//
//  Created by Leo on 15/7/14.
//  Copyright (c) 2015年 Leo. All rights reserved.
//

#import "ViewController.h"

#import "ZMMoviePlayerController.h"

@interface ViewController () {
    
    ZMMoviePlayerController* _moviePlayerController;
    
    BOOL _isWebFile;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"video" ofType:@"mp4"];
    NSURL* fileURL = [NSURL fileURLWithPath: filePath];
    
//    fileURL = [NSURL URLWithString: @"http://classvideo.meihua.info/UploadFile/mp4/4b6c703d-6928-4145-94e0-43abc2d3c7b6.mp4"];
    

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - 

- (IBAction)play:(id)sender {
    
    NSURL* fileURL = nil;
    
    if (_isWebFile) {
        _isWebFile = NO;
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"video" ofType:@"mp4"];
        fileURL = [NSURL fileURLWithPath: filePath];
    }
    else {
        _isWebFile = YES;
        
        fileURL = [NSURL URLWithString: @"http://classvideo.meihua.info/UploadFile/mp4/4b6c703d-6928-4145-94e0-43abc2d3c7b6.mp4"];
    }
    
    [_moviePlayerController stop];
    
    ZMMoviePlayerController* videoViewController = [[ZMMoviePlayerController alloc] initWithContentURL: fileURL andWithVideoViewFrame: CGRectMake(0, 100, CGRectGetWidth(self.view.bounds), 200)];
    [videoViewController setSuperView: self.view];
    
    _moviePlayerController = videoViewController;
}

@end
