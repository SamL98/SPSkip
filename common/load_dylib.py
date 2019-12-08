import shutil
from xxd_helper import read_int, write_int, write_str
import argparse

def edit_header(f, dylib_path, disable_aslr, is64, remove_dylib):
	dylib_lc = 0xc
	dylib_lc_size = 24

	total_lc_size = dylib_lc_size + len(dylib_path) + 1
	if total_lc_size % 8 != 0:
		total_lc_size += 8 - (total_lc_size % 8)

	f.seek(16) # ncmd offset
	ncmd = read_int(f, 4)
	sizeofcmds = read_int(f, 4)

	if remove_dylib:
		f.seek(-8, 1)
		write_int(f, ncmd-1, 4)

	f.seek(16)
	write_int(f, ncmd+1, 4)
	write_int(f, sizeofcmds+total_lc_size, 4)

	if disable_aslr:
		flags = read_int(f, 4)
		flags &= 0xffdfffff
		f.seek(-4, 1)
		write_int(f, flags, 4)
	else:
		f.seek(4, 1)

	if is64: 
		f.seek(4, 1)

	f.seek(sizeofcmds, 1) # seek to the current end of the commands

	write_int(f, dylib_lc, 4)
	write_int(f, total_lc_size, 4)
	write_int(f, dylib_lc_size, 4)
	write_int(f, 2, 4)
	write_int(f, 0, 4)
	write_int(f, 0, 4)
	write_str(f, dylib_path)
	

if __name__ =='__main__':
	parser = argparse.ArgumentParser()
	parser.add_argument('--binary', dest='binary', type=str)
	parser.add_argument('--dylib', dest='dylib', type=str)
	parser.add_argument('--disable_aslr', dest='disable_aslr', action='store_true')
	parser.add_argument('--is64', dest='is64', action='store_true')
	parser.add_argument('--remove', dest='remove', action='store_true')
	args = parser.parse_args()

	with open(args.binary, 'r+b') as f:
		edit_header(f, args.dylib, args.disable_aslr, args.is64, args.remove)
