#include <stdio.h>
#include "objc_types.h"

uint64_t find_subproc(FILE *fp, 
					  objc_method *meth, 
					  int64_t text_addend,
					  int32_t **reloc_addr,
					  int64_t *reloc_pc);
