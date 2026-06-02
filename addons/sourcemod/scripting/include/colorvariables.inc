#if defined _colorvariables_included
	#endinput
#endif
#define _colorvariables_included

#include <colors>

static int g_iColorVariablesAuthor = NO_INDEX;

stock void CSetNextAuthor(int author)
{
	g_iColorVariablesAuthor = author;
}

stock void CRemoveColors(char[] message, int maxlength)
{
	CRemoveTags(message, maxlength);
}

stock void CProcessVariables(char[] message, int maxlength)
{
	CFormat(message, maxlength, g_iColorVariablesAuthor);
	g_iColorVariablesAuthor = NO_INDEX;
}
