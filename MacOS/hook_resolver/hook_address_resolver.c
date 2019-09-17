#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <mach-o/loader.h>
#include "objc_types.h"
#include "find_method.h"
#include "find_subproc.h"

#define TEXT_SEGNAME "__TEXT"
#define DATA_SEGNAME "__DATA"

#define TEXT_SECTNAME "__text"
#define OBJC_METHNAME_SECTNAME "__objc_methname"
#define OBJC_CLASSNAME_SECTNAME "__objc_classname"
#define OBJC_CLASSLIST_SECTNAME "__objc_classlist"
#define OBJC_CONST_SECTNAME "__objc_const"
#define OBJC_DATA_SECTNAME "__objc_data"
#define SECTNAME_LEN 16

void 
(*resolve_mediaKey_subproc_addr(int32_t **reloc_addr, 
								int64_t *reloc_pc))(void *, int32_t)
{
	FILE 				  	  *fp;
	size_t					  i,j;
	size_t					  curr_off;
	struct mach_header_64     header;
	struct load_command		  load_cmd;
	struct segment_command_64 seg_cmd;
	struct section_64		  sect;

	struct section_64 text_sect,
					  objc_classlist_sect;

	int64_t data_addend,
			text_addend;

	objc_class_data mediaKey_class_data;
	objc_method 	mediaKey_meth;

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
			curr_off = sizeof(load_cmd);
			goto seek_to_eos;
		}

		// Read the load command as a segment command
		fread((void *)((char *)&seg_cmd + sizeof(load_cmd)), sizeof(seg_cmd) - sizeof(load_cmd), 1, fp);

		// If this section is the data section, map it and calculate the addend
		if (!strcmp(seg_cmd.segname, DATA_SEGNAME))
			data_addend = (int64_t)seg_cmd.fileoff - (int64_t)seg_cmd.vmaddr;
		else if (!strcmp(seg_cmd.segname, TEXT_SEGNAME))
			text_addend = (int64_t)seg_cmd.fileoff - (int64_t)seg_cmd.vmaddr;

		// Otherwise, if this section isn't the text section, ignore it
		else {
			curr_off = sizeof(seg_cmd);
			goto seek_to_eos;
		}

		for (j=0; j<seg_cmd.nsects; j++)
		{
			// Read the section
			fread((void *)&sect, sizeof(sect), 1, fp);

			// If it is the text section or the classlist section, read them
			if (!strncmp(sect.sectname, TEXT_SECTNAME, SECTNAME_LEN)) 
				memcpy((void *)&text_sect, (void *)&sect, sizeof(sect));
			else if (!strncmp(sect.sectname, OBJC_CLASSLIST_SECTNAME, SECTNAME_LEN))
				memcpy((void *)&objc_classlist_sect, (void *)&sect, sizeof(sect));
		}

		curr_off = load_cmd.cmdsize;

seek_to_eos:
		fseek(fp, load_cmd.cmdsize - curr_off, SEEK_CUR);
	}

	get_mediaKey_class(fp, 
					   data_addend,
					   objc_classlist_sect,
					   &mediaKey_class_data);

	get_mediaKey_meth(fp,
					  data_addend,
					  &mediaKey_class_data,
					  &mediaKey_meth);

	return (void (*)(void *, int32_t))find_subproc(fp,
				 								   &mediaKey_meth,
				 								   text_addend,
												   reloc_addr,
												   reloc_pc);
}
