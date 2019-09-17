#include "objc_types.h"

void
get_mediaKey_class(FILE *fp,
				   int64_t data_addend,
				   struct section_64 classlist_sect,
				   objc_class_data *mediaKey_class_data);

void
get_mediaKey_meth(FILE *fp,
				  int64_t data_addend,
				  objc_class_data *mediaKey_class_data,
				  objc_method *mediaKey_meth);
