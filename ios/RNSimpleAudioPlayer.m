#import "RNSimpleAudioPlayer.h"

#import "RNSPlayer.h"
#import "RNSPlayerItem.h"
#import <AVFoundation/AVFoundation.h>

@implementation RNSimpleAudioPlayer {
    RNPlayer* player;
    AVURLAsset *asset;
    RNPlayerItem *playerItem;
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}


- (NSURL *)findUrlForPath:(NSString *)path {
    NSURL *url = nil;
    
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               path,
                               nil];
    
    NSString *possibleUrl = [NSString pathWithComponents:pathComponents];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:possibleUrl]) {
        NSString *fileWithoutExtension = [path stringByDeletingPathExtension];
        NSString *extension = [path pathExtension];
        NSString *urlString = [[NSBundle mainBundle] pathForResource:fileWithoutExtension ofType:extension];
        if (urlString) {
            url = [NSURL fileURLWithPath:urlString];
        } else {
            NSString* mainBundle = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], path];
            BOOL isDir = NO;
            NSFileManager* fm = [NSFileManager defaultManager];
            if ([fm fileExistsAtPath:mainBundle isDirectory:&isDir]) {
                url = [NSURL fileURLWithPath:mainBundle];
            } else {
                url = [NSURL URLWithString:path];
            }
            
        }
    } else {
        url = [NSURL fileURLWithPathComponents:pathComponents];
    }
    
    return url;
}

-(void)stop{
    [player seekToTime:CMTimeMake(0, 1)];
    [player pause];
}

-(void)itemDidFinishPlaying:(NSNotification *) notification {
    // Will be called when AVPlayer finishes playing playerItem
    [self stop];
}

RCT_EXPORT_MODULE()

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        NSDictionary* response = @{@"event": @"status", @"status": [[NSNumber numberWithFloat:player.status] stringValue]};
        [self tellJs:@"RNAudio" body:response];
        NSLog(@"[AudioPlayer] player status: %li", player.status);
    } else if ([keyPath isEqualToString:@"rate"]) {
        float rate = [change[NSKeyValueChangeNewKey] floatValue];
        NSLog(@"[AudioPlayer] player rate: %f", rate);
        if (rate == 0.0) {
            // Playback stopped
        } else if (rate == 1.0) {
            // Normal playback
        } else if (rate == -1.0) {
            // Reverse playback
        }
    }
}

- (NSArray<NSString *> *)supportedEvents {
    return @[@"RNAudio"];
}

- (void)tellJs:(NSString *)eventName
          body:(NSObject *)body {
    [self sendEventWithName:eventName body:body];
}



RCT_EXPORT_METHOD(prepare:(NSString *)path
                  options:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    NSURL *url = [self findUrlForPath:path];
    if (url) {
        asset = [AVURLAsset assetWithURL: url];
        playerItem = (RNPlayerItem *)[RNPlayerItem playerItemWithAsset: asset];
        player = [[RNPlayer alloc]
                  initWithPlayerItem:playerItem];
        // setup event listners
        [player addObserver:self forKeyPath:@"status" options:0 context:nil];
        [player addObserver:self forKeyPath:@"rate" options:0 context:nil];
        CMTime timeInterval = CMTimeMakeWithSeconds(1, 1);
        [player addPeriodicTimeObserverForInterval:(timeInterval) queue:dispatch_get_main_queue() usingBlock:^(CMTime time){
            NSTimeInterval seconds = CMTimeGetSeconds(time);
            NSInteger intSec = seconds;
            NSString* strSec = [NSString stringWithFormat:@"%li", intSec];
            NSLog(@"[AudioPlayer] player position: %@", strSec);
        }];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:player.currentItem];
        //
        Float64 totalDurationSeconds = CMTimeGetSeconds(player.currentItem.asset.duration);
        NSDictionary* response = @{@"duration": @(totalDurationSeconds * 1000), @"path": url};
        resolve(response);
    } else {
        NSError *err = [NSError errorWithDomain:@"invalid_URL"
                                           code:500
                                       userInfo:@{
                                                  NSLocalizedDescriptionKey:@"invalid uri; please check path passed"
                                                  }];
        reject(@"error",[[err userInfo] description], err);
    }
}


RCT_EXPORT_METHOD( play:
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [player play];
    NSDictionary* response = @{@"duration": @"1000000", @"path": @"pppppaaaa"};
    [self tellJs:@"RNAudio" body:response];
    resolve([NSNull null]);
}

RCT_EXPORT_METHOD(stop:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    [self stop];
    resolve([NSNull null]);
}

RCT_EXPORT_METHOD(pause:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    [player pause];
    resolve([NSNull null]);
}

RCT_EXPORT_METHOD(setVolume: (float)volume)
{
    NSArray *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
    NSMutableArray *allAudioParams = [NSMutableArray array];
    for (AVAssetTrack *track in audioTracks) {
        AVMutableAudioMixInputParameters *audioInputParams =
        [AVMutableAudioMixInputParameters audioMixInputParameters];
        [audioInputParams setVolume:volume atTime:kCMTimeZero];
        [audioInputParams setTrackID:[track trackID]];
        [allAudioParams addObject:audioInputParams];
    }
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    [audioMix setInputParameters:allAudioParams];
    [playerItem setAudioMix:audioMix];
    //  [[AVAudioSession sharedInstance] setActive:YES error:nil];
    //  float vol = [[AVAudioSession sharedInstance] outputVolume];
    //  NSLog(@"output volume: %1.2f dB",vol);
}

// resume audio
RCT_EXPORT_METHOD(resume:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    [player play];
    resolve([NSNull null]);
}

// restart audio
RCT_EXPORT_METHOD(restart:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    [self stop];
    [player play];
    resolve([NSNull null]);
}

@end

