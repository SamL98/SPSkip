#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <mach-o/loader.h>
#include "find_subproc.h"

#define TEXT_SEGNAME "__TEXT"

void 
(*resolve_mediaKey_subproc_addr(uint64_t imp_ptr,
								int32_t **reloc_addr, 
								int64_t *reloc_pc))(void *, int32_t)
{
	FILE 				  	  *fp;
	size_t					  i;
	struct mach_header_64     header;
	struct load_command		  load_cmd;
	struct segment_command_64 seg_cmd;
	int64_t text_addend;

	// Open the Spotify application for reading
	if (!(fp = fopen("/Applications/Spotify.app/Contents/MacOS/Spotify", "r"))) {
		fprintf(stderr, "Couldn't open spotify binary\n");
		return NULL;
	}

	// Read the Mach-O header
	fread((void *)&header, sizeof(header), 1, fp);

	for (i=0; i<header.ncmds; i++)
	{
		// Read the load command
		fread((void *)&load_cmd, sizeof(load_cmd), 1, fp);
		
		// Ignore it if it isn't a load command
		if (load_cmd.cmd != LC_SEGMENT_64) {
			fseek(fp, load_cmd.cmdsize - sizeof(load_cmd), SEEK_CUR);
			continue;
		}

		// Read the load command as a segment command
		fread((void *)((char *)&seg_cmd + sizeof(load_cmd)), sizeof(seg_cmd) - sizeof(load_cmd), 1, fp);

		if (!strcmp(seg_cmd.segname, TEXT_SEGNAME)) {
			text_addend = (int64_t)seg_cmd.fileoff - (int64_t)seg_cmd.vmaddr;
			break;
		}
	}

	return (void (*)(void *, int32_t))find_subproc(fp,
												   imp_ptr,
				 								   text_addend,
												   reloc_addr,
												   reloc_pc);
}
