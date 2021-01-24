#ifndef MACHO_PARSER
#define MACHO_PARSER

#import <Foundation/Foundation.h>
#include <mach-o/loader.h>

typedef struct segment_command_64 seg_cmd_t;
typedef struct mach_header_64     header_t;
typedef struct dylib_command      dylib_cmd_t;
typedef struct load_command       load_cmd_t;

NSArray<NSString* >* parse_dylibs(NSString* path);

#endif
