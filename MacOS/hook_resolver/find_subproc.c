#include <capstone/capstone.h>
#include <string.h>
#include "find_subproc.h"

#define NBYTES 500

uint64_t
find_subproc(FILE *fp,
			 objc_method *meth,
			 int64_t text_addend,
			 int32_t **reloc_addr,
			 int64_t *reloc_pc)
{
	uint8_t code[NBYTES];
	size_t  start_addr;

	csh     handle;
	cs_insn *insn;
	size_t  i, insn_count;

	uint64_t target_addr = 0;

	fseek(fp, (meth->imp) & 0xffffff, SEEK_SET);
	fread((void *)code, 1, NBYTES-1, fp);
	code[NBYTES-1] = 0;

	// The imp offset was already fixed up, so we unfix it to get the virtual address.
	// It doesn't really matter but it's nice maybe.
	start_addr = (size_t)((int64_t)(meth->imp) - text_addend);

	if (cs_open(CS_ARCH_X86, CS_MODE_64, &handle) != CS_ERR_OK) {
		fprintf(stderr, "Couldn't open capstone\n");
		exit(1);
	}

	insn_count = cs_disasm(handle,
						   code,
						   NBYTES-1,
						   start_addr,
						   0,
						   &insn);

	if (!insn_count) {
		fprintf(stderr, "No instructions disassembled by capstone in mediaKeyTap callback\n");
		exit(1);
	}

	for (i=0; i<insn_count; i++)
	{
		if (strcmp(insn[i].mnemonic, "mov") || strcmp(insn[i].op_str, "esi, 3"))
			continue;

		target_addr = strtoll(insn[i+2].op_str, NULL, 16);
		break;
	}

	if (!target_addr) {
		fprintf(stderr, "Did not find target address in handleMediaKeyTap\n");
		exit(1);
	}

	fseek(fp, target_addr & 0xffffff, SEEK_SET);
	fread((void *)code, 1, NBYTES-1, fp);

	start_addr = target_addr + text_addend;

	insn_count = cs_disasm(handle,
						   code,
						   NBYTES-1,
						   start_addr,
						   0,
						   &insn);

	if (!insn_count) {
		fprintf(stderr, "No instructions disassembled by capstone in handleMediaKey wrapper\n");
		exit(1);
	}

	target_addr = 0;

	for (i=0; i<insn_count; i++)
	{
		if (strcmp(insn[i].mnemonic, "mov") || strcmp(insn[i].op_str, "esi, r14d"))
			continue;

		*reloc_addr = (int32_t *)(insn[i+5].address+1);
		*reloc_pc = (uint64_t)(insn[i+5].address + insn[i+5].size);

		target_addr = strtoll(insn[i+5].op_str, NULL, 16);
		break;
	}

	if (!target_addr) {
		fprintf(stderr, "Did not find target address in handleMediaKey wrapper\n");
		exit(1);
	}

	cs_close(&handle);

	return target_addr;
}
