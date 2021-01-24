#import <Foundation/Foundation.h>

void disable_aslr(NSString * path);
void set_maxprot(NSString * segname, int prot, NSString * path);
void inject_dylibs(NSArray<NSString*> * dylib_paths, NSString * path);
