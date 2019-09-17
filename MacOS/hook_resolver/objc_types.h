#include <stdlib.h>

#ifndef OBJC_H
#define OBJC_H

typedef struct {
	uint64_t name;
	uint64_t types;
	uint64_t imp;
} objc_method;

typedef struct {
	uint32_t    entsize;
	uint32_t    count;
} objc_methodlist;

typedef struct {
	uint32_t 	flags;
	uint32_t 	instance_start;
	uint64_t 	instance_size;
	uint64_t  	ivar_layout;
	uint64_t  	name;
	uint64_t	base_methods;
} objc_class_data;

typedef struct {
	uint64_t	isa;
	uint64_t 	super;
	uint64_t 	cache;
	uint64_t 	vtable;
	uint64_t 	data;
	uint64_t 	meta_isa;
	uint64_t 	meta_super;
	uint64_t 	meta_cache;
	uint64_t 	meta_vtable;
	uint64_t	meta_data;
} objc_class;

#endif

void fixup_class(objc_class *class, int64_t data_addend);
void fixup_class_data(objc_class_data *class_data, int64_t data_addend);
void fixup_method(objc_method *meth, int64_t data_addend);
