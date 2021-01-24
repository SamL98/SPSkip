#import <Foundation/Foundation.h>

#define CWD @"/Users/samlerner/Projects/SPSkip/MacOS/reinjector/test_target/"
#define TARBALL @"/Users/samlerner/Projects/SPSkip/MacOS/reinjector/test_target/packed_update.tgz"


int main()
{
    NSFileManager * fileman = [NSFileManager defaultManager];
    NSString * update_dir = [CWD stringByAppendingString:@"Spotify.app"];

    if ([fileman isDeletableFileAtPath:update_dir])
        [fileman removeItemAtPath:update_dir error:NULL];

    [fileman createDirectoryAtPath:update_dir
             withIntermediateDirectories:YES
             attributes:0
             error:NULL];

    NSTask * task = [[NSTask alloc] init];

    task.launchPath = @"/usr/bin/tar";
    task.arguments = @[@"xf", TARBALL];
    task.currentDirectoryPath = update_dir;

    [task launch];
    [task waitUntilExit];

    return task.terminationStatus;
}
