#include <stdlib.h>
#include <stdio.h>
#import "macho_parser.h"

#define DYLIB_PATH_MAXLEN 100


NSArray<NSString *> * parse_dylibs(NSString * path)
{
    FILE * file;

    if (!(file = fopen(path.UTF8String, "r"))) 
    {
        NSLog(@"Couldn't open %@", path);
        return NULL;
    }
    else 
    {
        header_t    header;
        load_cmd_t  lc;
        dylib_cmd_t dyc;
        size_t      i, lc_off;
        char        dylib_path[DYLIB_PATH_MAXLEN+1];

        // Using a fixed-length dylib path so that we don't have to malloc/realloc for every dylib. Should be OK.
        dylib_path[DYLIB_PATH_MAXLEN] = 0;

        fread((void *)&header, sizeof(header_t), 1, file);

        NSMutableArray<NSString*> * dylib_paths = [NSMutableArray arrayWithCapacity:header.ncmds];

        for (i=0; i<header.ncmds; i++)
        {
            lc_off = ftell(file);
            fread((void *)&lc, sizeof(load_cmd_t), 1, file);
            
            if (lc.cmd != LC_LOAD_DYLIB) 
            {
                fseek(file, lc.cmdsize - sizeof(load_cmd_t), SEEK_CUR);
            }
            else
            {
                // Rewind to the start of the LC and re-read it as a LC_LOAD_DYLIB.
                fseek(file, lc_off, SEEK_SET);
                fread((void *)&dyc, sizeof(dylib_cmd_t), 1, file);

                // Read the dylib's path using the `name` offset.
                fseek(file, lc_off + dyc.dylib.name.offset, SEEK_SET);
                fread((void *)dylib_path, 1, DYLIB_PATH_MAXLEN, file);

                [dylib_paths addObject:[NSString stringWithUTF8String:dylib_path]];

                // Seek to the start of the next LC.
                fseek(file, lc_off + lc.cmdsize, SEEK_SET);
            }
        }

        fclose(file);

        return dylib_paths;
    }
}
