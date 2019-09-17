#include "objc_types.h"

void
fixup_pointers(uint64_t *st, size_t nfields, int64_t addend)
{
	size_t i;

	for (i=0; i<nfields; i++)
		*(st + i) = (uint64_t)((int64_t)(*(st + i)) + addend);
}

void
fixup_class(objc_class *class, int64_t data_addend)
{
	fixup_pointers((uint64_t *)class, sizeof(objc_class) / sizeof(uint64_t), data_addend);
}

void
fixup_class_data(objc_class_data *class_data, int64_t data_addend)
{
	fixup_pointers((uint64_t *)class_data + 2, 3, data_addend);
}

void
fixup_method(objc_method *meth, int64_t data_addend)
{
	fixup_pointers((uint64_t *)meth, sizeof(meth) / sizeof(uint64_t), data_addend);
}
