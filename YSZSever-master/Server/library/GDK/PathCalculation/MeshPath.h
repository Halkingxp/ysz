#pragma once
#include <vector>
#include <list>
#include "Define.h"
#include "Eigen/Dense"
using namespace Eigen;

enum ESpinodalState
{
	E_SPINODAL_START,							// 开始寻找
	E_SPINODAL_FIND_ONE,						// 找到一个拐点,loop
	E_SPINODAL_LOOP,							// loop寻找拐点中
};

struct PathNode
{
	uint32 trigonIndex;							// 节点所在索引
	float f;
	float g;
	float h;
	const PathNode *pFather;

	Vector2f origin;                     // 起点，做三角形的穿入边和穿出边判断
};


typedef std::list<PathNode*> OPEN_TABLE;
typedef OPEN_TABLE CLOSE_TABLE;

enum EPathResult
{
	PATH_POINT_CANNOT_ARRIVE,						// 点不可到达
	PATH_SEAL_POINT,								// 封闭点
	PATH_FIND_SUC,									// 路径寻找成功
};

class CNavMesh;
class CMeshPath
{
	friend class CNavMeshMgr;
protected:
	CMeshPath()
	{
		m_OriginBegin.setZero();
		m_OriginEnd.setZero();
	}
public:
	virtual ~CMeshPath()
	{
		
	}

	uint8  FindPath(const Vector2f& begin, const Vector2f& end, std::list<Vector2f>& outPoint, const CNavMesh* pMesh, uint32 nBeginIndex, uint32 nEndIndex);
	uint32   GetCanArriveGoalPoint(const Vector2f& begin, const Vector2f& end, const CNavMesh* pMesh, uint32 nBeginIndex, Vector2f& outPoint);
	Vector2f GetCanArriveGoalPoint(const Vector2f& point, CNavMesh* pMesh);
	

private:
	bool  GetTrigonCrossPoint(const Vector2f& origin, uint32 nFatherIndex, uint32 nChildIndex, const CNavMesh* pMesh, Vector2f& point_a, Vector2f& point_b);
	bool  GetNextLeftRightPoint(uint32 nIndex, uint32 nNextIndex, const CNavMesh* pMesh, Vector2f& left, Vector2f& right);
	
	void  FindSpinodal(const CNavMesh* pMesh, uint32 nEndIndex, std::vector<uint32>& trigonIndex, std::list<Vector2f>& outPoint);
	void  FindTrigon(uint32 iBeginIndex, uint32 iEndIndex, std::vector<uint32>& outPoint,const CNavMesh* pMesh);
	float GetH(const Vector2f& point, const Vector2f& end);
	float GetG(const Vector2f& point_a, const Vector2f& point_b);

	void   GenerateNext(const PathNode* pFather, const CNavMesh* pMap);
	void   SetNextTile(const PathNode* pFather, uint32 nextIndex, const CNavMesh* pMap);
	float  GetaStarReviseDistance(const Vector2f& point, const Vector2f& next);
	uint32 FindPoint(uint32 iBeginIndex, const CNavMesh* pMesh, Vector2f& outPoint);
private:
	OPEN_TABLE m_cOpen;
	CLOSE_TABLE m_cClose;
	Vector2f  m_OriginBegin;						// 原始的起点
	Vector2f  m_OriginEnd;						// 原始的结束位置
};