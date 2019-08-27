//
//  ReactPlayer.m
//  maphabitMobileApp
//
//  Created by Ansal on 20/08/19.
//  Copyright © 2019 Facebook. All rights reserved.
//

#import "RNSPlayer.h"

@implementation RNSPlayer

- (instancetype)initWithURL:(NSURL *)URL {
    self = [super initWithURL:URL];
    
    self.looping = NO;
    self.autoDestroy = YES;
    self.speed = 1.0f;
    
    return self;
}

@end
