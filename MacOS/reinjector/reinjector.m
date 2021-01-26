#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#import "macho_parser.h"
#import "macho_editor.h"

#define OLD_BINARY_PATH @"/Applications/Spotify.app/Contents/MacOS/Spotify"
//#define OLD_BINARY_PATH @"/Users/samlerner/Projects/SPSkip/MacOS/reinjector/test_target/target"


void hook_meth(NSString* classname, NSString* selname, IMP new_imp, IMP* orig_imp)
{
    // Perform the pseudo-swizzling.
    Class class = NSClassFromString(classname);

    // Get the original method.
    SEL sel = NSSelectorFromString(selname);
    Method meth = class_getInstanceMethod(class, sel);

    // Store its imp.
    *orig_imp = method_getImplementation(meth);

    // Replace it with ours.
    class_replaceMethod(class, sel, new_imp, method_getTypeEncoding(meth));
}

void restore_meth(NSString* classname, NSString* selname, IMP orig_imp)
{
    Class class = NSClassFromString(classname);
    SEL sel = NSSelectorFromString(selname);
    Method meth = class_getInstanceMethod(class, sel);
    class_replaceMethod(class, sel, orig_imp, method_getTypeEncoding(meth));
}


IMP orig_waitUntilExit;
typedef void proto_waitUntilExit(id, SEL);

void my_waitUntilExit(NSTask * self, SEL cmd)
{
    // Perform the unpacking (i.e. tar xf).
    ((proto_waitUntilExit *)orig_waitUntilExit)(self, cmd);

    // We don't need this hook anymore.
    restore_meth(@"NSConcreteTask", @"waitUntilExit", orig_waitUntilExit);

    NSString * exec = self.launchPath,
             * cwd = self.currentDirectoryPath;
    NSArray * args = self.arguments;
    
    if (!(exec && cwd && args && \
          [exec isEqualTo:@"/usr/bin/tar"] && \
          [cwd hasSuffix:@"Spotify.app"] && \
          args.count > 0 && \
          [args[0] isEqualTo:@"xf"])) 
    {
        NSLog(@"[NSConcreteTask waitUntilExit] called but update_app_path is NULL. This shouldn't happen.");
        return;
    }
    else 
    {
        NSString* update_binary_path = [cwd stringByAppendingString:@"/Contents/MacOS/Spotify"];

        // 1. Read all of the LC_LOAD_DYLIB's from the about-to-be-updated binary
        //    then keep every dylib with a path of the form .../spskip_XX.dylib.
        NSArray<NSString* >* current_dylibs = parse_dylibs(OLD_BINARY_PATH);

        if (!current_dylibs)
        {
            NSLog(@"Could not parse dylibs from %@", OLD_BINARY_PATH);
            return;
        }
        else
        {
            NSMutableArray<NSString* >* dylibs_to_insert = [NSMutableArray arrayWithCapacity:current_dylibs.count];

            for (NSString* dylib_path in current_dylibs) {
                NSArray<NSString* >* path_comps = [dylib_path componentsSeparatedByString:@"/"];
                NSString* dylib_name = path_comps.lastObject;

                if (dylib_name && [dylib_name hasPrefix:@"spskip"]) {
                    [dylibs_to_insert addObject:dylib_path];
                }
            }

            // 2. Edit the update binary's Mach-O header so that our monkey patching will be accepted by the kernel.
            disable_aslr(update_binary_path);
            set_maxprot(@"__TEXT", 7, update_binary_path);

            // 3. Inject the dylibs we parsed in Step 1. into the update binary.
            inject_dylibs(dylibs_to_insert, update_binary_path);

            return;
        }
    }
}


static void __attribute__((constructor)) initialize(void)
{
    hook_meth(@"NSConcreteTask", @"waitUntilExit", (IMP)my_waitUntilExit, &orig_waitUntilExit);
}
