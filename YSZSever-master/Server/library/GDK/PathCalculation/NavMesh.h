/*****************************************************************************
Copyright (C), 2008-2009, ***. Co., Ltd.
文 件 名:  navmesh.h
作    者:  gl.wang
版    本:  1.0
完成日期:  2014-12-24
说明信息:  need u3d的不可到达三角~~
*****************************************************************************/
#pragma once
#include "Define.h"
#include "Eigen/Dense"
#include "QuadNavmesh.h"
using namespace Eigen;


// 无效的三角形索引
#define FAILED_TRIGON_INDEX  (0xffffffff)

const int C_TRIGON_NUM = 3;
// mesh的顶点
struct MeshPoint
{
	uint32 nIndex;
	Vector2f position;
	bool operator<(const MeshPoint& obj)const
	{
		return nIndex < obj.nIndex;
	}
	float  _y;
};
typedef std::vector<MeshPoint>  MESH_POINT;
typedef std::vector<uint32>       ADJOIN_TRIGON;

struct SVerIndex
{
	uint32 nIndex;
	uint32 verindex;
	bool operator< (const SVerIndex& obj)const
	{
		return nIndex < obj.nIndex;
	}
};


// 加载资源的优化,某个点引用了的三角形
typedef std::set<uint32>  ADJOIN_OPTIMIZE;
struct SLoadOptimize
{
	ADJOIN_OPTIMIZE adjoin;
};

typedef std::map<uint32, SLoadOptimize>  TRIGON_OPTIMIZE;
// 三角形,顶点顺时针
struct STrigon
{
	uint32 nIndex;
	uint32 nodeIndex[C_TRIGON_NUM];							// 三角形顶点的索引
	ADJOIN_TRIGON  adjoin;									// 这个三角形的邻接三角形
	Vector2f middle;
};

typedef std::vector<STrigon> TRIGON_MESH;


class CNavMesh
{
public:
	CNavMesh(void);
	~CNavMesh(void);

public:
	bool Init(uint16 nMapID, const std::string& directPath);					// 初始化mesh
	uint16 GetMapID(void)const						 { return m_nMapID; }
public:
	bool             PointIsInTrigonIndex(uint32 nIndex, const Vector2f& point) const;
	const STrigon*   GetTrigon(uint32 nIndex) const;
	Vector2f  GetNearEndPoint(const Vector2f& end);
	bool      GetGainOnEndPoint(uint32 nIndex, const Vector2f& end, float& distance, Vector2f& cross)const;
private:
	Vector2f  _GetTrigonMiddle(uint32 nIndex) const;
	Vector2f  GetOriginCheck(uint32 trigonIndex) const;
public:
	bool   GetTrigonLeftRightPoint(uint32 iFatherIndex, uint32 iNextIndex, Vector2f& left, Vector2f& right)const;

	uint32 GetTrigonIndex(const Vector2f& point)       ;		// 根据点击的位置获得三角形索引
	uint32 GetTrigonIndex_1(const Vector2f& point)const;		// 根据点击的位置获得三角形索引
	bool   GetTrigonRayCrossPoint(const Vector2f& origin, uint32 nFatherIndex, uint32 nChildIndex, Vector2f& point_a, Vector2f& point_b)const;
	bool   GetTrigonBERayCrossPoint(const Vector2f& origin, const Vector2f& end, uint32 nFatherIndex, uint32 nIndex, Vector2f& point_a, Vector2f& point_b)const;
private:
	bool   IsBorder(const STrigon& trigon, const STrigon& other, ADJOIN_TRIGON *pOut)const;
	bool   IsExistAdjoinIndex(const STrigon& trigon, uint32 nIndex)const;
	// 不是标准的四叉树 and 不想记录重复的点位置,没有独立成类

private:
	static bool IsCrossQuad(void *pThis, const Vector2f& leftUp, const Vector2f& rightDown, const uint32& nData);
	static bool PointIsInTrigon(void *pThis, const Vector2f& point, const uint32& nIndex);
	static bool PointNearEnd(void *pThis, const Vector2f& end, const uint32& nData, float& outDistance, Vector2f& outPoint);
	
	bool  _IsCrossQuad(const Vector2f& leftUp, const Vector2f& rightDown, const uint32& nData);
	bool  _PointIsInTrigon(const Vector2f& point, const uint32& nData) ;
	bool  _PointNearEnd(const Vector2f& end, const uint32& nData, float& outDistance, Vector2f& outPoint);
private:
	MESH_POINT   m_cMeshPoint;
	TRIGON_MESH  m_cTrigon;
	uint16       m_nMapID;

	CQuadNavmesh<uint32> m_Tree;
	float        m_fMindis;
	uint32       m_nIndex;
};