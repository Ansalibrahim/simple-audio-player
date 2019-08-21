//
//  ReactPlayerItem.m
//  maphabitMobileApp
//
//  Created by Ansal on 20/08/19.
//  Copyright © 2019 Facebook. All rights reserved.
//

#import "RNSPlayerItem.h"

@implementation RNSPlayerItem

- (void)dealloc {
    self.reactPlayerId = nil;
}

+ (instancetype)playerItemWithAsset:(AVAsset *)asset {
    return [[self alloc] initWithAsset:asset];
}

@end
