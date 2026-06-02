#if defined _stringtables_data_included
	#endinput
#endif
#define _stringtables_data_included

#include <sdktools_stringtables>

stock void DeleteStringTableData(int table)
{
	LockStringTables(false);

	int count = GetStringTableNumStrings(table);
	char empty[1];
	for (int i = 0; i < count; i++)
	{
		SetStringTableData(table, i, empty, 0);
	}
}
