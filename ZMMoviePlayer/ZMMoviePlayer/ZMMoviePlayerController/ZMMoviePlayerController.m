//
//  ZMMoviePlayerController.m
//  ZMMoviePlayer
//
//  Created by Leo on 15/7/15.
//  Copyright (c) 2015年 Leo. All rights reserved.
//

#import "ZMMoviePlayerController.h"

@interface ZMMoviePlayerController() {
    
    //  手势视图
    UIView* _gestureRecognizerView;     /** < 手势视图*/
    

    UIView* _topBarView;                /** < 顶部视图*/
    
    UIView* _bottomBarView;             /** < 底部视图*/
    UIButton* _fullScreenButton;        /** < 切换全屏模式按钮*/
    UIButton* _playButton;              /** < 播放按钮*/
    UIButton* _pauseButton;             /** < 暂停按钮*/
    
    UILabel* _progressTimeLabel;        /** < 进度时间*/
    UILabel* _totalTimeLabel;           /** < 总时间*/
    
    UIProgressView* _progressView;      /** < 预加载进度视图*/
    UISlider* _progressSlider;          /** < 播放进度视图*/
    
    
    UIView* _loadingTipsView;           /** < 加载提示视图*/
    
    BOOL _isFullScreen;                 /** < 判断是否是全屏模式*/
    
    NSTimer* _progressTimer;
    dispatch_source_t _timer;
}


@end

@implementation ZMMoviePlayerController

- (id)initWithContentURL:(NSURL *)url andWithVideoViewFrame:(CGRect)frame {
    
    self = [super initWithContentURL: url];
    if (self) {
        [self setScalingMode: MPMovieScalingModeAspectFit];
        [self setMovieSourceType: MPMovieSourceTypeUnknown];
        [self setControlStyle: MPMovieControlStyleNone];
        
        [self prepareToPlay];
        
        [self initNotification];
        [self iniGestureRecognizerView];
        
        UIView* movieView = self.view;
        movieView.frame = frame;
        _videoViewFrame = frame;
        
        [self initTopBarView];
        [self initBottomBarView];
        [self initLoadingTipsView];
    }
    return self;
}

- (void)dealloc {
    
    [self stop];
}

#pragma mark - init methods

- (void)initTopBarView {
    
    UIView* movieView = self.view;
    
    _topBarView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, CGRectGetWidth(movieView.bounds), 34)];
    _topBarView.backgroundColor = [UIColor colorWithWhite: 0.0 alpha:0.3];
    _topBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _topBarView.hidden = YES;
    [movieView addSubview: _topBarView];
    {
        UIView* loadingView = [[UIView alloc] initWithFrame: CGRectMake(CGRectGetWidth(_topBarView.bounds)/2 - 55, 0, 110, 34)];
        loadingView.backgroundColor = [UIColor clearColor];
        loadingView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        [_topBarView addSubview: loadingView];
        
        {
            UIActivityIndicatorView* activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhite];
            activityView.center = CGPointMake(10, CGRectGetHeight(loadingView.bounds)/2);
            [activityView startAnimating];
            [loadingView addSubview: activityView];
            
            UILabel* titleLabel = [[UILabel alloc] initWithFrame: CGRectMake(30, 7, 100, 20)];
            titleLabel.backgroundColor = [UIColor clearColor];
            titleLabel.textColor = [UIColor whiteColor];
            titleLabel.textAlignment = NSTextAlignmentLeft;
            titleLabel.font = [UIFont systemFontOfSize: 12];
            titleLabel.text = @"拼命加载中...";
            [loadingView addSubview: titleLabel];
        }
    }
}

- (void)initBottomBarView {
    
    UIView* movieView = self.view;
    
    _bottomBarView = [[UIView alloc] initWithFrame: CGRectMake(0, CGRectGetHeight(movieView.bounds) - 44, CGRectGetWidth(movieView.bounds), 44)];
    _bottomBarView.backgroundColor = [UIColor colorWithWhite: 0.0 alpha:0.3];
    _bottomBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    [movieView addSubview: _bottomBarView];
    {
        _pauseButton = [UIButton buttonWithType: UIButtonTypeCustom];
        _pauseButton.frame = CGRectMake(5, 2, 40, 40);
        _pauseButton.hidden = YES;
        [_pauseButton setBackgroundImage: [UIImage imageNamed: @"ad_pause_p"] forState: UIControlStateNormal];
        [_pauseButton setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
        [_pauseButton addTarget: self action: @selector(moviePause:) forControlEvents: UIControlEventTouchUpInside];
        [_bottomBarView addSubview: _pauseButton];
        
        _playButton = [UIButton buttonWithType: UIButtonTypeCustom];
        _playButton.frame = CGRectMake(5, 2, 40, 40);
        [_playButton setBackgroundImage: [UIImage imageNamed: @"ad_play_p"] forState: UIControlStateNormal];
        [_playButton setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
        [_playButton addTarget: self action: @selector(moviePlay:) forControlEvents: UIControlEventTouchUpInside];
        [_bottomBarView addSubview: _playButton];
        
        UIView* progressBackgroundView = [[UIView alloc] initWithFrame: CGRectMake(50, 0, CGRectGetWidth(_bottomBarView.bounds) - 100, CGRectGetHeight(_bottomBarView.bounds))];
        progressBackgroundView.backgroundColor = [UIColor clearColor];
        progressBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [_bottomBarView addSubview: progressBackgroundView];
        
        {
            _progressTimeLabel = [[UILabel alloc] initWithFrame: CGRectMake(10, 10, 40, 22)];
            _progressTimeLabel.backgroundColor = [UIColor clearColor];
            _progressTimeLabel.font = [UIFont systemFontOfSize: 10.0f];
            _progressTimeLabel.text = @"00:00";
            _progressTimeLabel.textAlignment = NSTextAlignmentRight;
            _progressTimeLabel.textColor = [UIColor whiteColor];
            [progressBackgroundView addSubview: _progressTimeLabel];
            
            _progressView = [[UIProgressView alloc] initWithProgressViewStyle: UIProgressViewStyleDefault];
            _progressView.frame = CGRectMake(60, 20, CGRectGetWidth(progressBackgroundView.bounds) - 120, 10);
            _progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            _progressView.progressTintColor = [UIColor colorWithRed: 136/255.0 green: 171/255.0 blue:218/255.0 alpha: 1.0];
            _progressView.trackTintColor = [UIColor colorWithWhite: 1.0 alpha: 0.3];
            _progressView.progress = 0.0;
            [progressBackgroundView addSubview: _progressView];
            
            _progressSlider = [[UISlider alloc] initWithFrame: CGRectMake(58, 16, CGRectGetWidth(progressBackgroundView.bounds) - 116, 10)];
            [_progressSlider setThumbImage: [UIImage imageNamed: @"slider_round_p"] forState: UIControlStateNormal];
            _progressSlider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            _progressSlider.maximumTrackTintColor = [UIColor clearColor];
            [_progressSlider addTarget: self action: @selector(chageProgress:) forControlEvents: UIControlEventValueChanged];
            [progressBackgroundView addSubview: _progressSlider];
            
            _totalTimeLabel = [[UILabel alloc] initWithFrame: CGRectMake(CGRectGetWidth(progressBackgroundView.bounds) - 50, 10, 40, 22)];
            _totalTimeLabel.backgroundColor = [UIColor clearColor];
            _totalTimeLabel.font = [UIFont systemFontOfSize: 10.0f];
            _totalTimeLabel.text = @"00:00";
            _totalTimeLabel.textColor = [UIColor whiteColor];
            _totalTimeLabel.textAlignment = NSTextAlignmentLeft;
            _totalTimeLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            [progressBackgroundView addSubview: _totalTimeLabel];
        }
        
        _fullScreenButton = [UIButton buttonWithType: UIButtonTypeCustom];
        _fullScreenButton.frame = CGRectMake(CGRectGetWidth(_bottomBarView.bounds) - 45, 7, 40, 30);
        _fullScreenButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        _fullScreenButton.titleLabel.font = [UIFont systemFontOfSize: 16.0];
        [_fullScreenButton setTitle: @"全屏" forState: UIControlStateNormal];
        [_fullScreenButton setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
        [_fullScreenButton addTarget: self action: @selector(actionOfSwitchScreen:) forControlEvents: UIControlEventTouchUpInside];
        [_bottomBarView addSubview: _fullScreenButton];
    }
}

- (void)iniGestureRecognizerView {
    
    UIView* movieView = self.view;
    NSArray* gestureRecognizers = [movieView gestureRecognizers];
    for (UIGestureRecognizer* gestureRecognizer in gestureRecognizers) {
        [movieView removeGestureRecognizer: gestureRecognizer];
    }
    
    _gestureRecognizerView = [[UIView alloc] initWithFrame: [movieView bounds]];
    _gestureRecognizerView.backgroundColor = [UIColor clearColor];
    _gestureRecognizerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [movieView addSubview: _gestureRecognizerView];
    
    [_gestureRecognizerView addGestureRecognizer: [[UITapGestureRecognizer alloc] initWithTarget: self action: @selector(onTap:)]];
}

- (void)initLoadingTipsView {
    
    UIView* movieView = self.view;
    
    UIView* loadingView = [[UIView alloc] initWithFrame: CGRectMake(CGRectGetWidth(movieView.bounds)/2 - 55, CGRectGetHeight(movieView.bounds)/2 - 17, 110, 34)];
    loadingView.backgroundColor = [UIColor clearColor];
    loadingView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [movieView addSubview: loadingView];
    _loadingTipsView = loadingView;
    {
        UIActivityIndicatorView* activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhite];
        activityView.center = CGPointMake(10, CGRectGetHeight(loadingView.bounds)/2);
        [activityView startAnimating];
        [loadingView addSubview: activityView];
        
        UILabel* titleLabel = [[UILabel alloc] initWithFrame: CGRectMake(30, 7, 100, 20)];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.textAlignment = NSTextAlignmentLeft;
        titleLabel.font = [UIFont systemFontOfSize: 12];
        titleLabel.text = @"拼命加载中...";
        [loadingView addSubview: titleLabel];
    }
}

#pragma mark - 
#pragma mark - Notification methods

- (void)initNotification {
    //注册消息监听
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(playbackDidFinish:) name: MPMoviePlayerPlaybackDidFinishNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(loadStateDidChange:) name: MPMoviePlayerLoadStateDidChangeNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(listenPlayerState:) name: MPMediaPlaybackIsPreparedToPlayDidChangeNotification object: nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(listenPlaybackStateDidChanged:) name: MPMoviePlayerPlaybackStateDidChangeNotification object: nil];
}

- (void)cleanNotification {
    //情况消息监听
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

#pragma mark - NSNotification methods

- (void)listenPlaybackStateDidChanged:(NSNotification*)notification {
    
    if (self.playbackState == MPMoviePlaybackStatePlaying) {
        
        if (_timer) {
            dispatch_source_cancel(_timer);
        }
        
        __block int timeout = 5; //倒计时时间
        __block UIView* blockBottomBarView = _bottomBarView;
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,queue);
        
        dispatch_source_set_timer(_timer,dispatch_walltime(NULL, 0),1.0*NSEC_PER_SEC, 0); //每秒执行
        dispatch_source_set_event_handler(_timer, ^{
            
            if(timeout == 0){ //倒计时结束，关闭
                dispatch_source_cancel(_timer);
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    NSLog(@"时间到");
                    blockBottomBarView.hidden = YES;
                });
            }else{
                timeout--;
            }
        });
        dispatch_resume(_timer);
    }
    else if (self.playbackState == MPMoviePlaybackStatePaused) {
        
        _bottomBarView.hidden = NO;
        
        if (_timer) {
            dispatch_source_cancel(_timer);
        }
    }
}

- (void)listenPlayerState:(NSNotification*)notification {
    
    NSInteger seconds = self.duration;
    NSInteger hour = 0;
    if (seconds >= 3600) {
        hour = seconds / 3600;
        seconds -= 3600 * hour;
    }
    NSInteger minute = 0;
    if (seconds > 60) {
        minute = seconds / 60;
        seconds -= 60 * minute;
    }
    
    NSString* hourString = [NSString stringWithFormat: @"%.2ld", (long)hour];
    NSString* minuteString = [NSString stringWithFormat: @"%.2ld", (long)minute];
    NSString* secondString = [NSString stringWithFormat: @"%.2ld", (long)seconds];
    
    if (hour > 0) {
        _totalTimeLabel.text = [NSString stringWithFormat: @"%@:%@:%@",hourString,minuteString,secondString];
    }
    else {
        _totalTimeLabel.text = [NSString stringWithFormat: @"%@:%@",minuteString,secondString];
    }
    
    [self play];
    [self startPlaying];
}

- (void)playbackDidFinish:(NSNotification*)notification {
    
    [_progressTimer invalidate];
    _progressTimer = nil;
}

- (void)loadStateDidChange:(NSNotification*)notification {
    
    if (self.loadState == MPMovieLoadStatePlayable) {
        
        _pauseButton.hidden = NO;
        _playButton.hidden = YES;
        _topBarView.hidden = YES;
        _loadingTipsView.hidden = YES;
    }
    else {
        _pauseButton.hidden = YES;
        _playButton.hidden = NO;
        _topBarView.hidden = _isFullScreen ? NO : YES;
        _loadingTipsView.hidden = _isFullScreen ? YES : NO;
    }
}


#pragma mark - Public methods

@synthesize superView = _superView;
- (void)setSuperView:(UIView *)superView {
    _superView = superView;
    [_superView addSubview: self.view];
}

- (void)prepareToPlay {
    [super prepareToPlay];
}

- (void)stop {
    
    [self cleanNotification];
    [super stop];
    
    
    
    [_progressTimer invalidate];
    _progressTimer = nil;
    if (_timer) {
        dispatch_source_cancel(_timer);
    }
    
    [self.view.subviews makeObjectsPerformSelector: @selector(removeFromSuperview)];
    [self.view removeFromSuperview];
}

#pragma mark - Private methods

- (void)startPlaying {
    
    _loadingTipsView.hidden = YES;
    
    [_progressTimer invalidate];
    _progressTimer = nil;
    _progressTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0 target: self selector: @selector(movieProgress) userInfo: nil repeats: YES];
}

- (void)endPlaying {
    
    [_progressTimer invalidate];
    _progressTimer = nil;
}

- (void)movieProgress {
    
    //总时间
    
    NSTimeInterval duration = self.duration;
    NSTimeInterval playabledDuration = self.playableDuration;
    NSTimeInterval currentPlaybackTime = self.currentPlaybackTime;
    
    if (duration == 0.0) {
        return;
    }
    
    NSInteger seconds = self.currentPlaybackTime;
    NSInteger hour = 0;
    if (seconds >= 3600) {
        hour = seconds / 3600;
        seconds -= 3600 * hour;
    }
    NSInteger minute = 0;
    if (seconds > 60) {
        minute = seconds / 60;
        seconds -= 60 * minute;
    }
    
    NSString* hourString = [NSString stringWithFormat: @"%.2ld", (long)hour];
    NSString* minuteString = [NSString stringWithFormat: @"%.2ld", (long)minute];
    NSString* secondString = [NSString stringWithFormat: @"%.2ld", (long)seconds];
    
    if (hour > 0) {
        _progressTimeLabel.text = [NSString stringWithFormat: @"%@:%@:%@",hourString,minuteString,secondString];
    }
    else {
        _progressTimeLabel.text = [NSString stringWithFormat: @"%@:%@",minuteString,secondString];
    }
    
    float loadingProgress = playabledDuration / duration;
    [_progressView setProgress: loadingProgress animated: YES];
    
    float progress = currentPlaybackTime / duration;
    [_progressSlider setValue: progress animated: YES];
    
    if (self.playbackState != MPMoviePlaybackStatePlaying && currentPlaybackTime < playabledDuration - 2) {
        
        [self moviePlay: nil];
    }
}

#pragma mark -
#pragma mark - Action methods

- (void)chageProgress:(UISlider*)slider {
    
    UIControlState state = slider.state;
    if (state == UIControlStateNormal) {
        [self moviePause: _pauseButton];
    }
    
    NSTimeInterval currentTime = self.duration * slider.value;
    
    if (currentTime > self.playableDuration) {
        
        if (_isFullScreen) {
            _topBarView.hidden = NO;
        }
        else {
            _loadingTipsView.hidden = NO;
        }
    }
    
    [self setCurrentPlaybackTime: currentTime];
}

- (void)moviePlay:(UIButton*)sender {
    
    if (![self isPreparedToPlay]) {
        return;
    }
    
    [super play];
    _playButton.hidden = YES;
    _pauseButton.hidden = NO;
}

- (void)moviePause:(UIButton*)sender {
    [super pause];
    _playButton.hidden = NO;
    _pauseButton.hidden = YES;
}

- (void)actionOfSwitchScreen:(UIButton*)sender {

    UIView* movieView = self.view;
    [movieView removeFromSuperview];
    
    if (_isFullScreen) {
        _isFullScreen = NO;
        
        _topBarView.hidden = YES;
        _loadingTipsView.hidden = self.playbackState != MPMoviePlaybackStatePlaying ? NO : YES;
        
        [[UIApplication sharedApplication] setStatusBarHidden: NO];
        [_superView addSubview: movieView];
        
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        [UIView animateWithDuration: 0.25 animations:^{
            
            movieView.transform = CGAffineTransformIdentity;
            movieView.frame = _videoViewFrame;
        }completion:^(BOOL finished) {
            
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
            [_fullScreenButton setTitle: @"全屏" forState: UIControlStateNormal];
        }];
    }
    else {
        _isFullScreen = YES;
        
        _topBarView.hidden = self.playbackState != MPMoviePlaybackStatePlaying ? NO : YES;
        _loadingTipsView.hidden = YES;
        
        UIWindow* keyWindow = [[UIApplication sharedApplication] keyWindow];
        [[UIApplication sharedApplication] setStatusBarHidden: YES ];
        [keyWindow addSubview: movieView];
        
        CGFloat width = CGRectGetWidth([UIScreen mainScreen].bounds);
        CGFloat height = CGRectGetHeight([UIScreen mainScreen].bounds);
        
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        [UIView animateWithDuration: 0.25 animations:^{
            
            movieView.frame = CGRectMake(-(height - width)/2, (height - width)/2, height, width);
            movieView.transform = CGAffineTransformMakeRotation(M_PI_2);
            
        }completion:^(BOOL finished) {
            
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
            
            [_fullScreenButton setTitle: @"原始" forState: UIControlStateNormal];
        }];
    }
}

#pragma mark - 

- (void)onTap:(UITapGestureRecognizer*)tapper {
    
    UIView* target = [tapper view];
    if (target == _gestureRecognizerView) {
        
        if (_timer) {
            dispatch_source_cancel(_timer);
        }
        
        if (_bottomBarView.hidden) {
            _bottomBarView.hidden = NO;
            
            __block int timeout = 5; //倒计时时间
            __block UIView* blockBottomBarView = _bottomBarView;
            
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,queue);
            
            dispatch_source_set_timer(_timer,dispatch_walltime(NULL, 0),1.0*NSEC_PER_SEC, 0); //每秒执行
            dispatch_source_set_event_handler(_timer, ^{
                
                if(timeout == 0){ //倒计时结束，关闭
                    dispatch_source_cancel(_timer);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        blockBottomBarView.hidden = YES;
                    });
                }else{
                    timeout--;
                }
            });
            dispatch_resume(_timer);
        }
        else {
            _bottomBarView.hidden = YES;
        }
    }
}


@end
