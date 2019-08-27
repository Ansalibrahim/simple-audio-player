//
//  ReactPlayer.h
//  maphabitMobileApp
//
//  Created by Ansal on 20/08/19.
//  Copyright © 2019 Facebook. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
//#import "RCTEventDispatcher.h"

@interface RNSPlayer : AVPlayer

@property (readwrite) BOOL autoDestroy;
@property (readwrite) BOOL looping;
@property (readwrite) float speed;

@end
