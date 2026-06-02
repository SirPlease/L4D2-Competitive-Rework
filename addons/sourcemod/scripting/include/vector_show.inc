#if !defined _vector_show_included
#define _vector_show_included

#include <sdktools_tempents>
#include <sdktools_tempents_stocks>

static int g_sprite = -1;

stock int GetVectorShowSprite()
{
	if (g_sprite == -1)
	{
		g_sprite = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	}
	return g_sprite;
}

stock void ShowPos(int ColorType, float pos1[3], float pos2[3], float life = 10.0, float length = 0.0, float width1 = 1.0, float width2 = 11.0)
{
	float copy[3];
	if (length != 0.0)
	{
		SubtractVectors(pos2, pos1, copy);
		NormalizeVector(copy, copy);
		ScaleVector(copy, length);
		AddVectors(pos1, copy, copy);
	}
	else
	{
		CopyVector(pos2, copy);
	}
	ShowLaser(ColorType, pos1, copy, life, width1, width2);
}

stock void ShowDir(int ColorType, float pos[3], float dir[3], float life = 10.0, float length = 200.0, float width1 = 1.0, float width2 = 11.0)
{
	float pos2[3];
	CopyVector(dir, pos2);
	NormalizeVector(pos2, pos2);
	ScaleVector(pos2, length);
	AddVectors(pos, pos2, pos2);
	ShowLaser(ColorType, pos, pos2, life, width1, width2);
}

stock void ShowAngle(int ColorType, float pos[3], float angle[3], float life = 10.0, float length = 200.0, float width1 = 1.0, float width2 = 11.0)
{
	float pos2[3];
	GetAngleVectors(angle, pos2, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(pos2, pos2);
	ScaleVector(pos2, length);
	AddVectors(pos, pos2, pos2);
	ShowLaser(ColorType, pos, pos2, life, width1, width2);
}

stock void CopyVector(float Source[3], float Target[3])
{
	Target[0] = Source[0];
	Target[1] = Source[1];
	Target[2] = Source[2];
}

stock void ShowLaser(int ColorType, float pos1[3], float pos2[3], float life = 10.0, float width1 = 1.0, float width2 = 11.0)
{
	int color[4];
	if (ColorType == 1)
	{
		color[0] = 200;
		color[1] = 0;
		color[2] = 0;
		color[3] = 230;
	}
	else if (ColorType == 2)
	{
		color[0] = 0;
		color[1] = 200;
		color[2] = 0;
		color[3] = 230;
	}
	else if (ColorType == 3)
	{
		color[0] = 0;
		color[1] = 0;
		color[2] = 200;
		color[3] = 230;
	}
	else
	{
		color[0] = 200;
		color[1] = 200;
		color[2] = 200;
		color[3] = 230;
	}
	TE_SetupBeamPoints(pos1, pos2, GetVectorShowSprite(), 0, 0, 0, life, width1, width2, 1, 0.0, color, 0);
	TE_SendToAll();
}

#endif
