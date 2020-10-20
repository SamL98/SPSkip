//
//  skipman.m
//  LibSkipMac
//
//  Created by Sam Lerner on 9/15/19.
//  Copyright © 2019 Sam Lerner. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "skipman.h"
#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include <time.h>

#define NUM_SKIP_BYTES 10
#define BYTES_PER_LINE 34

@implementation SkipManager

FILE *_Nullable skipFile;
int bytesInHeader;
int numSkipped;
int numSkippedInSession;

- (id)init
{
    self = [super init];
    
    bytesInHeader = 0;
    
    numSkipped = 0;
    numSkippedInSession = 0;
    
    [self openSkipFile];
    
    // Read the number of songs previously skipped, or writer 0 if the file is empty
    numSkipped = [self readNumSkipped];
    
    return self;
}

- (void) openSkipFile
{
    skipFile = fopen(SKIP_FILE_NAME, "r+");
    if (!skipFile) {
        skipFile = fopen(SKIP_FILE_NAME, "w+");
        if (!skipFile) {
            perror("Could not open skip file");
            exit(-1);
        }
    }
}

- (void)close
{
    if (skipFile)
        fclose(skipFile);
}

- (int)readNumSkipped
{
    if (!skipFile)
        return 0;
    
    char numSkipStr[NUM_SKIP_BYTES];
    
    // If this read fails (the file is empty), then write 0 on the first line
    if (!fgets(numSkipStr, NUM_SKIP_BYTES, skipFile)) {
        [self writeNumSkipped];
        return 0;
    }
    
    bytesInHeader = (int)strlen(numSkipStr) + 1;
    
    return atoi(numSkipStr);
}

- (void)writeNumSkipped
{
    if (!skipFile)
        return;
    
    char skipStr[NUM_SKIP_BYTES];
    sprintf(skipStr, "%d\n", numSkipped);
    
    bytesInHeader = (int)strlen(skipStr);
    
    // Write the total number of skips to the beginning of the file
    fseek(skipFile, 0, SEEK_SET);
    fputs(skipStr, skipFile);
    fflush(skipFile);
}

- (void)push:(NSString *)tid
{
    if (!skipFile)
        return;
    
    // Increment both num skipped counters
    ++numSkippedInSession;
    ++numSkipped;
    
    [self writeNumSkipped];
    
    char line[BYTES_PER_LINE+1];
    unsigned long ts = (unsigned long)time(NULL);
    sprintf(line, "%s,%lu\n", [tid cStringUsingEncoding:NSASCIIStringEncoding], ts);
    
    fseek(skipFile, bytesInHeader + (numSkipped - 1) * BYTES_PER_LINE, SEEK_SET);
    fputs(line, skipFile);
    fflush(skipFile);
}

- (void)pop
{
    // Don't decrement the skipped counters if we haven't skipped any in this session
    if (!skipFile || !numSkippedInSession)
        return;
    
    --numSkippedInSession;
    --numSkipped;
    
    [self writeNumSkipped];
    fflush(skipFile);
}

@end
