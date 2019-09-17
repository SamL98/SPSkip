//
//  skipman.h
//  SkipTracer
//
//  Created by Sam Lerner on 6/24/19.
//  Copyright © 2019 Sam Lerner. All rights reserved.
//

#ifndef skipman_h
#define skipman_h

#define SKIP_FILE_NAME "skipped.csv"

#import <Foundation/Foundation.h>

@interface SkipManager : NSObject

- (void)push:(NSString *)tid;
- (void)pop;
- (void)close;

@end

#endif /* skipman_h */
