import shutil
import capstone as cap
import sys
import atexit

def cvt_int(bs, nbytes):
	val = 0

	for i in range(nbytes):
		byte = ord(bytes([bs[i]]))
		val |= byte << (i * 8)

	return val

def read_int(f, nbytes):
	val = 0

	for i in range(nbytes):
		byte = ord(f.read(1))
		val |= byte << (i * 8)

	return val

def read_ptr(f):
	return read_int(f, 4)

def write_int(f, p, nbytes):
	f.write(bytes([(p >> i*8) & 0xff for i in range(nbytes)]))

def write_ptr(f, p):
	write_int(f, p, 4)

def write_str(f, s):
	f.write(bytes(s.encode('ascii')))


def read_offsets(f):
	offsets = {}

	f.seek(16) # ncmd offset
	ncmd = read_int(f, 4)

	f.seek(8, 1) # end of header
	
	for i in range(ncmd):
		cmd = read_int(f, 4)
		cmdsize = read_int(f, 4)

		if cmd != 1: # LC_SEGMENT
			f.seek(cmdsize - 8, 1) # end of command
			continue

		segname = str(f.read(16))
		
		if not 'TEXT' in segname and not 'DATA' in segname:
			f.seek(cmdsize - 8 - 16, 1) # end of command
			continue

		f.seek(6 * 4, 1) # nsects offset
		nsects = read_int(f, 4)

		f.seek(4, 1) # end of segment command

		for j in range(nsects):
			sectname = str(f.read(16))
			
			if not 'objc' in sectname and not 'text' in sectname:
				f.seek(16 + 9 * 4, 1) # end of section
				continue

			f.seek(16, 1) # addr offset
			vaddr = read_int(f, 4)
			vsize = read_int(f, 4)
			foff = read_int(f, 4)

			sectname = sectname.split('\\x00')[0]
			sectname = sectname.strip('\'\" ')

			offsets[sectname[sectname.rindex('_')+1:]] = { 'virt_addr': vaddr,
														   'virt_size': vsize,
														   'file_off': foff }

			f.seek(6 * 4, 1) # end of section

	return offsets


def get_faddr(vaddr, offsets, ret_sect=False):
	for sect, offset in offsets.items():
		if vaddr < offset['virt_addr'] or vaddr >= offset['virt_addr'] + offset['virt_size']:
			continue

		faddr = vaddr - offset['virt_addr'] + offset['file_off']
		
		if ret_sect:
			return faddr, sect

		return faddr


def print_hd(f, faddr, header, md, terms):
	f.seek(faddr)
	hd = f.read(64)

	string = ''

	if len(terms) > 2:
		if terms[2] == '-str' or terms[2] == '-name':
			string = str(hd).split('\\x00')[0]
		elif terms[2] == '-disas':
			string  = '\n' + '\n'.join(['0x%x:\t%s\t%s' % (addr, mnem, opstr)
										for addr, _, mnem, opstr in md.disasm_lite(hd, int(terms[1], 16))])
	else:
		string = ', '.join([hex(cvt_int(hd[i*4:(i+1)*4], 4)) for i in range(len(hd)//4)])

	print(' '.join([header, string]))


if __name__ == '__main__':
	machofilename = 'client/Spotify'
	if len(sys.argv) > 1:
		machofilename = sys.argv[1]

	f = open(machofilename, 'rb')
	atexit.register(f.close)

	offsets = read_offsets(f)

	first_write_occurred = False

	md = cap.Cs(cap.CS_ARCH_ARM, cap.CS_MODE_ARM)

	while True:
		try:
			user_input = input('xxd> ')
		except EOFError:
			break
		
		if user_input == 'q':
			break

		vaddr = 0
		terms = user_input.split(' ')

		assert len(terms) > 1

		if terms[0] == 'ra':
			vaddr = int(terms[1], 16)
			faddr, sect = get_faddr(vaddr, offsets, True)
			header = ' '.join([sect, '@', hex(faddr) + ':'])
			print_hd(f, faddr, header, md, terms)

		elif terms[0] == 'wa':
			assert len(terms) > 2

			if not first_write_occurred:
				print('Copying {0} to {0}-mod'.format(machofilename))
				shutil.copyfile(machofilename, machofilename+'-mod')

				f.close()
				f = open(machofilename+'-mod', 'r+b')

				first_write_occurred = True

			vaddr = int(terms[1], 16)
			faddr, sect = get_faddr(vaddr, offsets, True)
			f.seek(faddr)

			if len(terms) > 3:
				if terms[3] == '-str':
					val = terms[2]
					write_str(f, val)
					print(f'Wrote %s to 0x%x in section: %s' % (val, faddr, sect))
				elif terms[3] == '--thumb':
					val = int(terms[2], 16)
					write_int(f, val, 2)
					print(f'Wrote 0x%x to 0x%x in section: %s' % (val, faddr, sect))
			else:
				val = int(terms[2], 16)
				write_ptr(f, val)
				print(f'Wrote 0x%x to 0x%x in section: %s' % (val, faddr, sect))

		elif terms[0] == 'rc':
			class_idx = int(terms[1], 16)
			vaddr = offsets['classlist']['virt_addr'] + class_idx * 4

			if len(terms) > 2 and terms[2] == '-name':
				f.seek(get_faddr(vaddr, offsets)) # seek to the classlist

				vaddr = read_int(f, 4) # data pointer
				f.seek(get_faddr(vaddr, offsets) + 0x10) # seek to the data pointer

				vaddr = read_int(f, 4) # data data pointer
				f.seek(get_faddr(vaddr, offsets) + 0x10) # seek to the data data pointer

				vaddr = read_int(f, 4) # name pointer
				faddr, sect = get_faddr(vaddr, offsets, True)

				header = ' '.join([sect, '@', hex(faddr) + ':'])
				print_hd(f, faddr, header, md, terms)
			else:
				faddr, sect = get_faddr(vaddr, offsets, True)
				header = ' '.join([sect, '@', hex(faddr) + ':'])
				print_hd(f, faddr, header, md, terms)

		elif terms[0] == 'cvt':
			vaddr = int(terms[1], 16)
			faddr, sect = get_faddr(vaddr, offsets, True)
			header = ' '.join([sect, 'in', hex(faddr)])
			print(header)

		elif terms[0] == 'po':
			assert len(terms) > 1

			sect = terms[1]
			offset = offsets[sect]

			print('vaddr: 0x%x\nvsize: 0x%x\nfoff: 0x%x' % tuple(offset.values()))

		else:
			print('Unrecognized command')
