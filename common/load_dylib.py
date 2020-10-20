import shutil
from xxd_helper import read_int, read_str, write_int, write_str
import argparse

DYLIB_LC = 0xc
DYLIB_LC_SIZE = 24

SEGMENT_64_LC = 0x19
SEGNAME_LEN = 16
TEXT_SEGNAME = '__TEXT'


def edit_header(f, dylib_paths, disable_aslr, is64, remove, text_maxprot):
    # Read the number of commands and size of them.
    f.seek(16)
    ncmd = read_int(f, 4)
    sizeofcmds = read_int(f, 4)

    # Calculate the size of all the hypothetical dylib LC's that we'll inject/uninject.
    num_dylib_lcs = len(dylib_paths)
    dylib_lc_sizes = []
    total_dylib_lcs_size = 0

    for dylib_path in dylib_paths:
        lc_size = DYLIB_LC_SIZE + len(dylib_path) + 1
        if lc_size % 8 != 0:
            lc_size += 8 - (lc_size % 8)

        dylib_lc_sizes.append(lc_size)
        total_dylib_lcs_size += lc_size

    # If we are removing them, then it's assumed that we previously added them with this script.
    # Therefore, we edit `sizeofcmds` by the calculated size of the LC commands.
    f.seek(-8, 1)

    if remove:
        write_int(f, ncmd - num_dylib_lcs, 4)
        write_int(f, sizeofcmds - total_dylib_lcs_size, 4)
    else:
        write_int(f, ncmd + num_dylib_lcs, 4)
        write_int(f, sizeofcmds + total_dylib_lcs_size, 4)

    # Disable ASLR if requested. Otherwise, just skip this field.
    if disable_aslr:
        flags = read_int(f, 4)
        flags &= 0xffdfffff
        f.seek(-4, 1)
        write_int(f, flags, 4)
    else:
        f.seek(4, 1)

    # Skip past the extra dword if this is a 64-bit binary.
    # TODO: Automatically detect 64-bitness.
    if is64: 
        f.seek(4, 1)

    end_of_header = f.tell()

    # Iterate over the segment LC's until we find the __TEXT segment so we can set the maxprot.
    while True:
        cmd = read_int(f, 4)
        cmdsize = read_int(f, 4)

        if cmd != SEGMENT_64_LC:
            f.seek(cmdsize - 8, 1)
        else:
            segname = read_str(f, 16)

            if not segname.startswith(TEXT_SEGNAME):
                f.seek(cmdsize - 24, 1)
            else:
                f.seek(8 * 4, 1)
                write_int(f, text_maxprot, 4)
                break

    # Seek to the current end of the commands.
    f.seek(end_of_header + sizeofcmds) 

    # Insert all of the dylib LC's if we're not removing them.
    if not remove:
        for lc_size, dylib_path in zip(dylib_lc_sizes, dylib_paths):
            write_int(f, DYLIB_LC, 4)
            write_int(f, lc_size, 4)
            write_int(f, DYLIB_LC_SIZE, 4)
            write_int(f, 2, 4)
            write_int(f, 0, 4)
            write_int(f, 0, 4)
            write_str(f, dylib_path)

            off = f.tell()
            if off % 8 != 0:
                f.seek(8 - (off % 8), 1)
    

if __name__ =='__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--binary', dest='binary', type=str)
    parser.add_argument('--disable_aslr', dest='disable_aslr', action='store_true')
    parser.add_argument('--is64', dest='is64', action='store_true')
    parser.add_argument('--remove', dest='remove', action='store_true')
    parser.add_argument('--text_maxprot', dest='text_maxprot', type=int, default=5)
    parser.add_argument('dylibs', type=str, nargs='+')
    args = parser.parse_args()

    with open(args.binary, 'r+b') as f:
        edit_header(f, args.dylibs, args.disable_aslr, args.is64, args.remove, args.text_maxprot)
