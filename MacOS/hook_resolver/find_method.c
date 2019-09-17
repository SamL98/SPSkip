#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <mach-o/loader.h>
#include "find_method.h"

#define MEDIAKEY_CLASSNAME "SPTBrowserClientMacObjCAnnex"
#define MEDIAKEY_SELNAME "mediaKeyTap:receivedMediaKeyEvent:"
#define MAX_CLASSNAME_LEN 33
#define MAX_SELNAME_LEN 64

void
get_mediaKey_class(FILE *fp,
				   int64_t data_addend,
				   struct section_64 classlist_sect,
				   objc_class_data *mediaKey_class_data)
{
	uint64_t   fileoff,
			   classoff;

	objc_class 		class;
	objc_class_data class_data;

	char name[MAX_CLASSNAME_LEN];
	name[MAX_CLASSNAME_LEN-1] = 0;

	for (fileoff=classlist_sect.offset; fileoff<classlist_sect.offset + classlist_sect.size; fileoff+=8)
	{
		fseek(fp, fileoff, SEEK_SET);
		fread((void *)&classoff, sizeof(classoff), 1, fp);
		classoff += data_addend;

		fseek(fp, classoff, SEEK_SET);
		fread((void *)&class, sizeof(class), 1, fp);
		fixup_class(&class, data_addend);

		fseek(fp, class.data, SEEK_SET);
		fread((void *)&class_data, sizeof(class_data), 1, fp);
		fixup_class_data(&class_data, data_addend);

		fseek(fp, class_data.name, SEEK_SET);
		fread((void *)name, 1, MAX_CLASSNAME_LEN, fp);

		if (!strcmp(name, MEDIAKEY_CLASSNAME)) {
			memcpy(mediaKey_class_data, &class_data, sizeof(objc_class_data));
			break;
		}
	}

	return;
}

void
get_mediaKey_meth(FILE *fp,
				  int64_t data_addend,
				  objc_class_data *mediaKey_class_data,
				  objc_method *mediaKey_meth)
{
	uint64_t		orig_methoff;
	uint64_t		methoff;
	objc_methodlist methlist;
	objc_method		meth;
	char			name[MAX_SELNAME_LEN];

	name[MAX_SELNAME_LEN-1] = 0;

	fseek(fp, mediaKey_class_data->base_methods, SEEK_SET);
	fread((void *)&methlist, sizeof(methlist), 1, fp);
	orig_methoff = ftell(fp);

	for (methoff=orig_methoff; methoff<orig_methoff + methlist.count * methlist.entsize; methoff+=methlist.entsize)
	{
		fseek(fp, methoff, SEEK_SET);
		fread((void *)&meth, sizeof(meth), 1, fp);
		fixup_method(&meth, data_addend);

		fseek(fp, meth.name, SEEK_SET);
		fread((void *)name, 1, MAX_SELNAME_LEN, fp);

		if (!strcmp(name, MEDIAKEY_SELNAME)) {
			memcpy(mediaKey_meth, &meth, sizeof(objc_method));
			break;
		}
	}
	
	return;
}
