import shutil
from xxd_helper import read_int, write_int, write_str

def edit_header(f):
	dylib_lc = 0xc
	dylib_lc_size = 24
	dylib_path = "@rpath/libskip.dylib"

	total_lc_size = dylib_lc_size + len(dylib_path) + 1
	if total_lc_size % 4 != 0:
		total_lc_size += 4 - (total_lc_size % 4)

	f.seek(16) # ncmd offset
	ncmd = read_int(f, 4)
	sizeofcmds = read_int(f, 4)

	f.seek(16)
	write_int(f, ncmd+1, 4)
	write_int(f, sizeofcmds+total_lc_size, 4)

	'''
	flags = read_int(f, 4)
	flags &= 0xffdfffff
	f.seek(-4, 1)
	write_int(f, flags, 4)
	'''
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
	shutil.copy('client/Spotify', 'spmod')

	with open('spmod', 'r+b') as f:
		edit_header(f)
