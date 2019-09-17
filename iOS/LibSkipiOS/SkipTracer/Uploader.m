//
//  Uploader.m
//  SkipTracer
//
//  Created by Sam Lerner on 6/23/19.
//  Copyright © 2019 Sam Lerner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Uploader.h"
#import "skipman.h"

@implementation Uploader

+ (void)upload
{
    NSString *boundary = @"---------------------------14737809831466499882746641449";
    
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@SKIP_FILE_NAME];
    NSData *fileData = [[NSData alloc] initWithContentsOfFile:filePath];
    
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] init];
    
    NSString *serverURLStr = [[[NSProcessInfo processInfo] environment] objectForKey:@"SERVER_URL"];
    
    [req setURL:[NSURL URLWithString:[serverURLStr stringByAppendingPathComponent:@"upload"]]];
    [req setHTTPMethod:@"POST"];
    [req addValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
    
    NSMutableData *body = [NSMutableData data];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Disposition: form-data; name=\"file\"; filename=\"test.csv\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[NSData dataWithData:fileData]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [req setHTTPBody:body];

    [[[NSURLSession sharedSession] dataTaskWithRequest:req] resume];
}

@end
