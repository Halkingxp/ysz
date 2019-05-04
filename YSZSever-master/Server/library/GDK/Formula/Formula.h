/*****************************************************************************
Copyright (C), 2008-2009, ***. Co., Ltd.
文 件 名:  Config.h
作    者:  wgl  
版    本:  1.0
完成日期:  2015-1-27
说明信息:  公式
*****************************************************************************/
#pragma once
#include "Define.h"
#include "Eigen/Dense"
using namespace Eigen;

#define FLOAT_FAULT_TOLERANT 0.001

enum LineDirection
{
	E_Line_Direction_Left,									// 在射线左边
	E_Line_Direction_Right,									// 在射线右边
	E_Line_Direction_Online,								// 向线段上（也有可能在延长线上）
};

struct EigenRect
{
	/*
	    a --b
	    |   |
	    c---d
	*/
	Vector2f _a;
	Vector2f _b;
	Vector2f _c;
	Vector2f _d;
};

class CFormula
{
private:
	CFormula();
public:
	~CFormula();
	static CFormula& GetInstance();
	
public:
	static uint8		GetLineDirection(const Vector2f& A, const Vector2f& B, const Vector2f& C);
	static float		GetDeltaSequence(const Vector2f& A, const Vector2f& B, const Vector2f& C);
	static bool			IsIntersectAnt(const Vector2f& ori, const Vector2f& point, const Vector2f& a, const Vector2f& b, Vector2f& corss);
	static Vector2f		GetPointMiddle(const Vector2f& a, const Vector2f& b);
	static float		GetPointDistance(const Vector2f& a, const Vector2f& b);
	static bool			PointIsOnSegment(const Vector2f& point,  const Vector2f& A, const Vector2f& B);
	static Vector2f		GetPointInSegment(const Vector2f& A, const Vector2f& B, float Alen, float ABlen);
	static float		TrigonArea(const Vector2f& pos1, const Vector2f& pos2, const Vector2f& pos3);
	static Vector2f		GetLintVertical(const Vector2f &pt1, const Vector2f &pt2, const Vector2f &point);
	static  bool		FloatEqual(float a, float b);
	static  bool		IsInRect(const Vector2f& point, const Vector2f& leftUp, const Vector2f& rightDown);
	static  bool		LineIntersect(const Vector2f& p1, const Vector2f& p2, const Vector2f& other1, const Vector2f& other2);
	static  EigenRect	GetRect(const Vector2f& leftUp, const Vector2f& rightDown);
	static  Vector2f	GetCutPoint(const Vector2f& leftUp, const Vector2f& rightDown);
private:
	static  float		Multiply(const Vector2f& p1,const Vector2f& p2,const Vector2f& p0);
	static bool			Inter(const Vector2f& origin, const Vector2f& point, const Vector2f& a, const Vector2f& b, Vector2f& outPoint);
	static int			HitType(const Vector2f& a, const Vector2f& b, const Vector2f& outPoint);
	
};

#define sFormulaMgr CFormula::GetInstance()