#if __has_include(<React/RCTBridgeModule.h>)
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#else
#import "RCTBridgeModule.h"
#import "RCTEventEmitter.h"
#endif

// status events
 NSString* const PREPARING = @"RNS_AUDIO/PREPARING";
 NSString* const READY = @"RNS_AUDIO/READY";
 NSString* const PLAYING = @"RNS_AUDIO/PLAYING";
 NSString* const PAUSED = @"RNS_AUDIO/PAUSED";
 NSString* const ERROR = @"RNS_AUDIO/ERROR";
 NSString* const IDLE = @"RNS_AUDIO/IDLE";

// buffering events
//const NSString* BUFFERING = @"RNS_AUDIO/BUFFERING";

 NSString* const STATUS_EVENT = @"RNS_AUDIO/STATUS_EVENT";
 NSString* const POSITION_EVENT = @"RNS_AUDIO/POSITION_EVENT";
//const NSString* BUFFERING_EVENT = @"RNS_AUDIO/BUFFERING_EVENT";


@interface RNSimpleAudioPlayer : RCTEventEmitter <RCTBridgeModule>

@end

// idle:default or initial
// preparing
// prepared
// buffering?? have to find implementation
// playing
// paused
// playing (on resume)
// prepared (on stop)
//
