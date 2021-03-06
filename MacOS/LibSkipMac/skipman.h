//
//  skipman.h
//  LibSkipMac
//
//  Created by Sam Lerner on 9/15/19.
//  Copyright © 2019 Sam Lerner. All rights reserved.
//

#ifndef skipman_h
#define skipman_h

#define SKIP_FNAME_FMT @"/Users/samlerner/Documents/Spotify/skipped-%@.csv"

#import <Foundation/Foundation.h>

@interface SkipManager : NSObject

- (id)init:(NSString *)dateString;
- (void)push:(NSString *)tid;
- (void)pop;
- (void)close;

@end

#endif /* skipman_h */
