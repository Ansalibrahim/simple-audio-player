#import "RNSimpleAudioPlayer.h"

#import "RNSPlayer.h"
#import "RNSPlayerItem.h"
#import <AVFoundation/AVFoundation.h>



@implementation RNSimpleAudioPlayer {
    RNSPlayer* player;
    AVURLAsset *asset;
    RNSPlayerItem *playerItem;
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

+ (BOOL)requiresMainQueueSetup
{
    return NO;
}

- (NSDictionary *)constantsToExport
{
    return @{ @"EVENT_TYPES": @{
                      @"STATUS_EVENT": STATUS_EVENT,
                      @"POSITION_EVENT": POSITION_EVENT
                      },
              @"STATUS": @{
                      @"PREPARING": PREPARING,
                      @"READY": READY,
                      @"PLAYING": PLAYING,
                      @"PAUSED": PAUSED,
                      @"ERROR": ERROR
                      }
              };
}


- (NSArray<NSString *> *)supportedEvents {
    return @[@"RNSAudio"];
}

- (void)tellJs:(NSObject *)event {
    [self sendEventWithName:@"RNSAudio" body:event];
}

-(void)sendStatusEvents:(NSString *) status {
    NSDictionary* event = @{@"type": STATUS_EVENT, @"status":status };
    [self tellJs:event];
}

-(void)sendPositionEvents:(NSString *) status {
    NSDictionary* event = @{@"type": POSITION_EVENT, @"currentPosition":status };
    [self tellJs:event];
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
    [self sendStatusEvents:READY];
}

RCT_EXPORT_MODULE()

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        NSDictionary* event = @{@"event": @"status", @"status": [[NSNumber numberWithFloat:player.status] stringValue]};
        [self tellJs:event];
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


RCT_EXPORT_METHOD(prepare:(NSString *)path
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [self sendStatusEvents:PREPARING];
    NSURL *url = [self findUrlForPath:path];
    if (url) {
        asset = [AVURLAsset assetWithURL: url];
        playerItem = (RNSPlayerItem *)[RNSPlayerItem playerItemWithAsset: asset];
        player = [[RNSPlayer alloc]
                  initWithPlayerItem:playerItem];
        // setup event listners
        [player addObserver:self forKeyPath:@"status" options:0 context:nil];
        [player addObserver:self forKeyPath:@"rate" options:0 context:nil];
        CMTime timeInterval = CMTimeMakeWithSeconds(1, 1);
        [player addPeriodicTimeObserverForInterval:(timeInterval) queue:dispatch_get_main_queue() usingBlock:^(CMTime time){
            NSTimeInterval seconds = CMTimeGetSeconds(time);
            NSInteger intSec = seconds;
//            NSString* strSec = [NSString stringWithFormat:@"%li", intSec];
            [self sendPositionEvents:[NSString stringWithFormat:@"%li", intSec]];
//            NSLog(@"[AudioPlayer] player position: %@", strSec);
        }];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:player.currentItem];
        //
        Float64 totalDurationSeconds = CMTimeGetSeconds(player.currentItem.asset.duration);
        NSDictionary* response = @{@"duration": @(totalDurationSeconds * 1000), @"path": url};
        resolve(response);
        [self sendStatusEvents:READY];
    } else {
        NSError *err = [NSError errorWithDomain:@"invalid_URL"
                                           code:500
                                       userInfo:@{
                                                  NSLocalizedDescriptionKey:@"invalid uri; please check path passed"
                                                  }];
        reject(@"error",[[err userInfo] description], err);
        [self sendStatusEvents:ERROR];
    }
}


RCT_EXPORT_METHOD( play:
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [player play];
    [self sendStatusEvents:PLAYING];
    resolve([NSNull null]);
}

RCT_EXPORT_METHOD(stop:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    [self stop];
    [self sendStatusEvents:READY];
    resolve([NSNull null]);
}

RCT_EXPORT_METHOD(pause:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    [player pause];
    [self sendStatusEvents:PAUSED];
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
    [self sendStatusEvents:PLAYING];
    resolve([NSNull null]);
}

// restart audio
RCT_EXPORT_METHOD(restart:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    [self stop];
    [player play];
    [self sendStatusEvents:PLAYING];
    resolve([NSNull null]);
}

RCT_EXPORT_METHOD(seekTo:(float)seekValue)
{
    CMTime newTime = CMTimeMakeWithSeconds(seekValue, 1);
    [player seekToTime:newTime];
}


@end

