//
//  SkipTracer.m
//  SkipTracer
//
//  Created by Sam Lerner on 6/22/19.
//  Copyright © 2019 Sam Lerner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "Uploader.h"
#include "skipman.h"
#include <string.h>

typedef id playbackFunc(id, SEL, id);

IMP origPrevImp;
IMP origNextImp;

SkipManager *skipman;


NSString *getTID(id playerState)
{
    NSURL *uri = [[playerState valueForKey:@"track"] valueForKey:@"URI"];
    return [[uri absoluteString] substringFromIndex:14];
}

int getPlaybackPosition(id playerState)
{
    NSNumber *pos = [playerState valueForKey:@"position"];
    return (int)[pos doubleValue];
}

int getDuration(id playerState)
{
    NSNumber *dur = [playerState valueForKey:@"duration"];
    return (int)[dur doubleValue];
}

BOOL shdHandleSkip(id playerState)
{
    int pos = getPlaybackPosition(playerState);
    int duration = getDuration(playerState);
    return pos <= duration/2;
}

id prev(id slf, SEL cmd, id options)
{
    id playerState = [slf valueForKey:@"state"];
    
    NSString *oldTID = getTID(playerState);
    BOOL shdHandle = shdHandleSkip(playerState);

    // Get the return value from skipToPrevious... because we still have some work to do
    id retVal = ((playbackFunc *)origPrevImp)(slf, cmd, options);

    NSString *newTID = getTID(playerState);

    // Only pop a skip if we actually went back a song, often, skip will just return
    // to the start of the current song.
    if (![oldTID isEqualToString:newTID] && shdHandle)
        [skipman pop];
    
    return retVal;
}

id next(id self, SEL _cmd, id options)
{
    id playerState = [self valueForKey:@"state"];
    
    if (shdHandleSkip(playerState))
        [skipman push:getTID(playerState)];
    
    return ((playbackFunc *)origNextImp)(self, _cmd, options);
}

static void __attribute__((constructor)) initialize(void)
{
    // Perform the pseudo-swizzling
    Class playerImplClass = NSClassFromString(@"SPTPlayerImpl");
    
    // Get the original prev method imp
    SEL prevSel = NSSelectorFromString(@"skipToPreviousTrackWithOptions:");
    Method prevMeth = class_getInstanceMethod(playerImplClass, prevSel);
    origPrevImp = method_getImplementation(prevMeth);

    // Replace it with ours
    class_replaceMethod(playerImplClass, prevSel, (IMP)prev, method_getTypeEncoding(prevMeth));
    
    // Do the same with the next method
    SEL nextSel = NSSelectorFromString(@"skipToNextTrackWithOptions:");
    Method nextMeth = class_getInstanceMethod(playerImplClass, nextSel);
    origNextImp = method_getImplementation(nextMeth);
    
    class_replaceMethod(playerImplClass, nextSel, (IMP)next, method_getTypeEncoding(nextMeth));
    
    // Initialize the skipman -- kludge but ok for now
    skipman = [[SkipManager alloc] init];
    
    // Upload the skip history file to our server, should ideally be just
    // diffs but that's too much for now
    [Uploader upload];
}

static void __attribute__((destructor)) finalize(void)
{
    [Uploader upload];
    [skipman close];
}
