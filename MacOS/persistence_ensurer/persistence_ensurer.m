#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#define PYTHON_PATH @"/usr/local/bin/python"
#define SCRIPT_PATH @"/Users/samlerner/Projects/SPSkip/common/load_dylib.py"
#define INJECT_CWD  @"/Users/samlerner/Projects/SPSkip/common"
#define PERSISTENCE_DYLIB_PATH @"/Users/samlerner/Projects/SPSkip/MacOS/persistence_ensurer/persistence_ensurer.dylib"
#define SKIPTRACER_DYLIB_PATH  @"/Users/samlerner/Projects/SPSkip/MacOS/skiptracer/skiptracer.dylib"


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


NSString* update_app_path = NULL;

IMP orig_waitUntilExit;
typedef void proto_waitUntilExit(id, SEL);

void my_waitUntilExit(id self, SEL cmd, NSString* path)
{
    // Perform the unpacking (untaring).
    ((proto_waitUntilExit *)orig_waitUntilExit)(self, cmd);

    // We don't need this hook anymore.
    restore_meth(@"NSTask", @"waitUntilExit", orig_waitUntilExit);
    
    if (update_app_path)
    {
        NSString* update_binary_path = [update_app_path stringByAppendingString:@"/Contents/MacOS/Spotify"];
        NSArray* args = @[SCRIPT_PATH,
                          @"--binary", update_binary_path,
                          @"--is64", @"--disable_aslr",
                          PERSISTENCE_DYLIB_PATH, SKIPTRACER_DYLIB_PATH];

        // Create a task to call our dylib injector Python script.
        // Inject both the library we are executing from (for persistence) and the skiptracer library.
        NSTask* inject_dylib_task = [[NSTask alloc] init];
        inject_dylib_task.launchPath = PYTHON_PATH;
        inject_dylib_task.arguments = args;
        inject_dylib_task.currentDirectoryPath = INJECT_CWD;

        // Run the script.
        [inject_dylib_task launch];
        [inject_dylib_task waitUntilExit];

        if (inject_dylib_task.terminationStatus)
            NSLog(@"Dylibs successfully injected!\n");
        else
            NSLog(@"Failed to inject dylibs :(\n");
    }
}


IMP orig_isDeletableAtFilePath;
typedef BOOL proto_isDeletableAtFilePath(id, SEL, NSString*);

BOOL my_isDeletableAtFilePath(id self, SEL cmd, NSString* path)
{
    // Call the original method.
    BOOL is_deletable = ((proto_isDeletableAtFilePath *)orig_isDeletableAtFilePath)(self, cmd, path);

    if ([path hasSuffix:@"Spotify.app"])
    {
        // We don't need this hook anymore (presumably).
        restore_meth(@"NSFileManager", @"isDeletableFileAtPath:", orig_isDeletableAtFilePath);

        // Hook waitUntilExit so we can get access to the unpacked binary.
        hook_meth(@"NSTask", @"waitUntilExit", (IMP)my_waitUntilExit, &orig_waitUntilExit);

        // Keep track of the %.app update path.
        update_app_path = [NSString stringWithString:path];
    }

    return is_deletable;
}


static void __attribute__((constructor)) initialize(void)
{
    hook_meth(@"NSFileManager", @"isDeletableFileAtPath:", (IMP)my_isDeletableAtFilePath, &orig_isDeletableAtFilePath);
}
