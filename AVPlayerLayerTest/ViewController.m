//
//  ViewController.m
//  AVPlayerLayerTest
//
//  Created by lykj on 2016/11/1.
//  Copyright © 2016年 lykj. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

#define MD_IS_USE_LocalVideo (1)            // 是否使用本地视频


@interface ViewController ()
{
    UIView*             mContentView;
    NSDateFormatter*    _dateFormatter;
}
@property(nonatomic, strong) AVAsset*           mAsset;
@property(nonatomic, strong) AVPlayerItem*      mPlayerItem;
@property(nonatomic, strong) AVPlayer*          mPlayer;
@property(nonatomic, strong) AVPlayerLayer*     mPlayerLayer;

@property(nonatomic, strong) id                 playbackTimeObserver;
@property(nonatomic, strong) NSString*          totalTime;
@end




@implementation ViewController

#pragma mark - AVAsset主要用于获取多媒体信息，是一个抽象类，不能直接使用
#pragma mark - AVURLAsset是AVAsset的子类，可以根据一个url的路径创建一个AVURLAsset对象
-(AVAsset *)mAsset
{
    if ( !_mAsset ) {
#if MD_IS_USE_LocalVideo
        NSString* urlStr = [[NSBundle mainBundle] pathForResource:@"2016" ofType:@"mp4"];
        _mAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:urlStr] options:nil];
#else
        _mAsset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:@"http://static.tripbe.com/videofiles/20121214/9533522808.f4v.mp4"] options:nil];
#endif
    }
    return _mAsset;
}

#pragma mark - AVPlayerItem对象，一个媒体资源管理对象，管理者视频的一些基本信息和状态。一个AVPlayerItem对应着一个视频资源。
-(AVPlayerItem *)mPlayerItem
{
    if ( !_mPlayerItem ) {
        _mPlayerItem = [AVPlayerItem playerItemWithAsset:self.mAsset];
    }
    return _mPlayerItem;
}

#pragma mark - AVPlayer本身并不能显示视频，而且他不像MPMoviePlayerController有一个view属性。
#pragma mark - 如果AVPlayer想要显示必须创建一个播放器层AVPlayerLayer，播放器层继承CALyer。有了AVPlayerLayer之后，添加到控制器的layer上即可。
-(AVPlayer *)mPlayer
{
    if ( !_mPlayer ) {
        _mPlayer = [AVPlayer playerWithPlayerItem:self.mPlayerItem];
    }
    return _mPlayer;
}

#pragma mark - 播放器层
-(AVPlayerLayer *)mPlayerLayer
{
    if ( !_mPlayerLayer ) {
        _mPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.mPlayer];
    }
    return _mPlayerLayer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    mContentView = [UIView new];
    mContentView.backgroundColor = [UIColor redColor];
    [self.view addSubview:mContentView];
    mContentView.frame = CGRectMake(0, 0, 200, 200);
    mContentView.center = self.view.center;
    
    self.mPlayerLayer.frame = mContentView.layer.bounds;
    self.mPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [mContentView.layer addSublayer:self.mPlayerLayer];
    [self.mPlayer play];
    
    // 监听：status属性
    [self.mPlayerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    // 监听：播放器的下载进度
    [self.mPlayerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    // 监听：播放器在缓冲数据的状态
    [self.mPlayerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    // 监听：缓冲达到可播放程度了
    [self.mPlayerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    
    // 添加视频播放结束通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.mPlayerItem];
}

// KVO方法
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"status"])
    {
        if ([playerItem status] == AVPlayerStatusReadyToPlay)
        {
            NSLog(@"AVPlayerStatusReadyToPlay");
            CMTime duration = self.mPlayerItem.duration;                                        // 获取视频总长度
            CGFloat totalSecond = playerItem.duration.value/playerItem.duration.timescale;      // 转换成秒
            _totalTime = [self convertTime:totalSecond];                                        // 转换成播放时间
            NSLog(@"movie total duration:%f",CMTimeGetSeconds(duration));
            [self monitoringPlayback:self.mPlayerItem];                                         // 监听播放状态
        }
        else if ([playerItem status] == AVPlayerStatusFailed || [playerItem status] == AVPlayerStatusUnknown)
        {
            [self.mPlayer pause];
        }
    }
    else if ([keyPath isEqualToString:@"loadedTimeRanges"])
    {
        NSTimeInterval timeInterval = [self availableDuration];     // 计算缓冲进度
        CMTime duration = self.mPlayerItem.duration;
        CGFloat totalDuration = CMTimeGetSeconds(duration);

        if ( (NSInteger)timeInterval == (NSInteger)totalDuration )
        {
            NSLog(@"缓冲进度 百分之:100");
        }
        else
        {
            NSLog(@"缓冲进度 百分之:%ld",(NSInteger)(((CGFloat)(timeInterval)/totalDuration)*100)%100);
        }
    }
    else if ([keyPath isEqualToString:@"playbackBufferEmpty"])
    {
        NSLog(@"缓冲不足自动暂停了");
    }
    else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"])
    {
        NSLog(@"缓冲达到可播放程度了");
        [self.mPlayer play];        //由于 AVPlayer 缓存不足就会自动暂停，所以缓存充足了需要手动播放，才能继续播放
    }
}

- (NSString *)convertTime:(CGFloat)second{
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    if (second/3600 >= 1)
    {
        [[self dateFormatter] setDateFormat:@"HH:mm:ss"];
    }
    else
    {
        [[self dateFormatter] setDateFormat:@"mm:ss"];
    }
    NSString *showtimeNew = [[self dateFormatter] stringFromDate:d];
    return showtimeNew;
}

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
    }
    return _dateFormatter;
}

- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [[self.mPlayer currentItem] loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];    // 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;                     // 计算缓冲总进度
    return result;
}

#pragma mark - 监听播放进度
- (void)monitoringPlayback:(AVPlayerItem *)playerItem {
    __weak typeof(self) weakSelf = self;
    self.playbackTimeObserver = [self.mPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 1)
                                                                           queue:NULL
                                                                      usingBlock:^(CMTime time) {
                                                                          // 计算当前在第几秒
                                                                          CGFloat currentSecond = weakSelf.mPlayerItem.currentTime.value/weakSelf.mPlayerItem.currentTime.timescale;
                                                                          NSString *timeString = [weakSelf convertTime:currentSecond];
                                                                          NSLog(@"timeLabel = %@", [NSString stringWithFormat:@"%@/%@", timeString, weakSelf.totalTime]);
                                                                      }];
}

#pragma mark - 播放结束通知
- (void)moviePlayDidEnd:(NSNotification *)notification {
    NSLog(@"播放结束");
    [self.mPlayer seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {

    }];
}

- (void)dealloc
{
    [self.mPlayerItem removeObserver:self forKeyPath:@"status" context:nil];
    [self.mPlayerItem removeObserver:self forKeyPath:@"loadedTimeRanges" context:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.mPlayerItem];
    [self.mPlayer removeTimeObserver:self.playbackTimeObserver];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}





























#pragma mark - 测试函数
-(void)playAv
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"2016" ofType:@"mp4"];
    AVAsset *movieAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:filePath] options:nil];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.frame = self.view.layer.bounds;
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    
    [self.view.layer addSublayer:playerLayer];
    [player play];
}

















@end
