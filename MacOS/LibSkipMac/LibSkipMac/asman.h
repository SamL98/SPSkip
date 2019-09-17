//
//  asman.h
//  LibSkipMac
//
//  Created by Sam Lerner on 9/15/19.
//  Copyright © 2019 Sam Lerner. All rights reserved.
//

#ifndef asman_h
#define asman_h

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface AppleScriptManager : NSObject

@property Class objectModelClass;

- (id)init;
- (NSString *)getTID;
- (BOOL)shdHandle;

@end

#endif /* asman_h */
