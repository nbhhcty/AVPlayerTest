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
    UIView*         mContentView;
}
@property(nonatomic, strong) AVAsset*           mAsset;
@property(nonatomic, strong) AVPlayerItem*      mPlayerItem;
@property(nonatomic, strong) AVPlayer*          mPlayer;
@property(nonatomic, strong) AVPlayerLayer*     mPlayerLayer;
@end




@implementation ViewController

#pragma mark - AVAsset主要用于获取多媒体信息，是一个抽象类，不能直接使用
#pragma mark - AVURLAsset是AVAsset的子类，可以根据一个url的路径创建一个AVURLAsset对象
-(AVAsset *)mAsset
{
    if ( !_mAsset ) {
        NSString* urlStr = [[NSBundle mainBundle] pathForResource:@"2016" ofType:@"mp4"];
        _mAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:urlStr] options:nil];
    }
    return _mAsset;
}

#pragma mark - AVPlayerItem对象，一个媒体资源管理对象，管理者视频的一些基本信息和状态。一个AVPlayerItem对应着一个视频资源。
-(AVPlayerItem *)mPlayerItem
{
    if ( !_mPlayerItem ) {
#if MD_IS_USE_LocalVideo
        _mPlayerItem = [AVPlayerItem playerItemWithAsset:self.mAsset];
#else
        _mPlayerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:@"http://static.tripbe.com/videofiles/20121214/9533522808.f4v.mp4"]];
#endif
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
    self.mPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [mContentView.layer addSublayer:self.mPlayerLayer];
    [self.mPlayer play];
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

















- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
