//
//  asman.m
//  LibSkipMac
//
//  Created by Sam Lerner on 9/15/19.
//  Copyright © 2019 Sam Lerner. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "asman.h"
#include <string.h>

@implementation AppleScriptManager

- (id)init
{
    self = [super init];
    
    [self setObjectModelClass:NSClassFromString(@"SPTAppleScriptObjectModel")];
    
    return self;
}

- (NSString *)_getTID:(id)trackObj
{
    NSString *spotifyURL = [trackObj valueForKey:@"spotifyURL"];
    return [spotifyURL substringFromIndex:14];
}

- (NSString *)getTID
{
    id trackObj = [[self objectModelClass] performSelector:NSSelectorFromString(@"currentTrack")];
    return [self _getTID:trackObj];
}

- (BOOL)shdHandle
{
    id trackObj;
    NSNumber *playbackPos,
             *duration;
    NSString *spotifyURL;
    
    playbackPos = [[self objectModelClass] performSelector:NSSelectorFromString(@"playbackPosition")];
    trackObj = [[self objectModelClass] performSelector:NSSelectorFromString(@"currentTrack")];
    duration = [trackObj valueForKey:@"duration"];
    
    if ([playbackPos floatValue] >= [duration floatValue] / 2000.0f)
        return NO;
    
    return YES;
}

@end
