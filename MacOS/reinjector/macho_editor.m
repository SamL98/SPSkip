#include <string.h>
#include <stdio.h>
#import "macho_parser.h"
#import "macho_editor.h"


void disable_aslr(NSString * path)
{
    FILE * file;

    if (!(file = fopen(path.UTF8String, "r+"))) 
    {
        NSLog(@"Couldn't open %@", path);
    }
    else 
    {
        header_t header;

        fread((void *)&header, sizeof(header_t), 1, file);

        header.flags &= 0xffdfffff;

        rewind(file);
        fwrite((void *)&header, sizeof(header_t), 1, file);

        fclose(file);
    }
}

void set_maxprot(NSString * segname, int prot, NSString * path)
{
    FILE * file;

    if (!(file = fopen(path.UTF8String, "r+"))) 
    {
        NSLog(@"Couldn't open %@", path);
    }
    else 
    {
        header_t   header;
        seg_cmd_t  sc;
        load_cmd_t lc;
        size_t     i;

        fread((void *)&header, sizeof(header_t), 1, file);

        for (i=0; i<header.ncmds; i++)
        {
            fread((void *)&lc, sizeof(load_cmd_t), 1, file);
            
            if (lc.cmd != LC_SEGMENT_64) 
            {
                fseek(file, lc.cmdsize - sizeof(load_cmd_t), SEEK_CUR);
            }
            else
            {
                fseek(file, -sizeof(load_cmd_t), SEEK_CUR);
                fread((void *)&sc, sizeof(seg_cmd_t), 1, file);

                if (!strcmp(sc.segname, segname.UTF8String)) 
                {
                    sc.maxprot = prot;

                    fseek(file, -sizeof(seg_cmd_t), SEEK_CUR);
                    fwrite((void *)&sc, sizeof(seg_cmd_t), 1, file);

                    break;
                }
            }
        }

        fclose(file);
    }
}

void inject_dylibs(NSArray<NSString*> * dylib_paths, NSString * path)
{
    FILE * file;

    if (!(file = fopen(path.UTF8String, "r+"))) 
    {
        NSLog(@"Couldn't open %@", path);
    }
    else 
    {
        header_t    header;
        dylib_cmd_t dyc;
        size_t      dyc_size, padding;

        fread((void *)&header, sizeof(header_t), 1, file);
        fseek(file, header.sizeofcmds, SEEK_CUR);

        dyc.cmd = LC_LOAD_DYLIB;

        dyc.dylib.name.offset = sizeof(dylib_cmd_t);
        dyc.dylib.timestamp = 2; // buh
        dyc.dylib.current_version = 0;
        dyc.dylib.compatibility_version = 0;

        for (NSString * dylib_path in dylib_paths)
        {
            dyc_size = sizeof(dylib_cmd_t) + dylib_path.length + 1;
            padding = 0;

            if (dyc_size % 8) {
                padding = 8 - (dyc_size % 8);
                dyc_size += padding;
            }

            header.ncmds += 1;
            header.sizeofcmds += dyc_size;

            dyc.cmdsize = dyc_size;

            fwrite((void *)&dyc, sizeof(dylib_cmd_t), 1, file);
            fwrite((void *)dylib_path.UTF8String, 1, dylib_path.length + 1, file);

            fseek(file, padding, SEEK_CUR);
        }

        rewind(file);
        fwrite((void *)&header, sizeof(header_t), 1, file);

        fclose(file);
    }
}
