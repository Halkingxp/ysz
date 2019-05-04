#include "MeshPath.h"
#include "NavMesh.h"
#include "Assert/Assert.h"

//#define  _DEBUG_OUT_
//********************************************************************
//函数功能: 寻路接口
//第一参数: [IN] 开始位置，结束位置，outPoint编号，mesh的数据指针
//返回说明: 无
//备注说明: 
//********************************************************************
uint8 CMeshPath::FindPath(const Vector2f& begin, const Vector2f& end, std::list<Vector2f>& outPoint, const CNavMesh* pMesh, uint32 nBeginIndex, uint32 nEndIndex)
{
	if (NULL == pMesh)
	{
		return PATH_POINT_CANNOT_ARRIVE;
	}
	
	if (FAILED_TRIGON_INDEX == nBeginIndex || FAILED_TRIGON_INDEX == nEndIndex)
	{
		sprintf(g_szInfo, "use error, x=%.2f, y=%.2f, x=%.2f, y=%.2f, bug,map=%d", begin[0], begin[1], end[0], end[1], pMesh->GetMapID());
		REPORT(g_szInfo);
		return PATH_POINT_CANNOT_ARRIVE;
	}

	if (nBeginIndex == nEndIndex)
	{
		// outPoint两个点
		outPoint.push_back(begin);
		outPoint.push_back(end);
		return PATH_FIND_SUC;
	}

	m_OriginEnd = end;
	m_OriginBegin = begin;

	std::vector<uint32> trigonIndex;
	FindTrigon(nBeginIndex, nEndIndex, trigonIndex, pMesh);
	if (trigonIndex.empty())
	{
		return PATH_SEAL_POINT;
	}
		
	if (trigonIndex.size() < 2)
	{
		sprintf(g_szInfo, "x=%.2f, y=%.2f, x=%.2f, y=%.2f, bug,map=%d", begin[0], begin[1], end[0], end[1], pMesh->GetMapID());
		REPORT(g_szInfo);
		outPoint.push_back(begin);
		outPoint.push_back(end);
		return PATH_FIND_SUC;
	}
	outPoint.push_back(m_OriginBegin);
	FindSpinodal(pMesh,nEndIndex, trigonIndex, outPoint);
	outPoint.push_back(m_OriginEnd);

	return PATH_FIND_SUC;
}

//********************************************************************
//函数功能: 获得一个可到达的目标点
//第一参数: [IN] 开始位置，结束位置，mesh的数据指针
//返回说明: 可用的结束点位置
//备注说明: 
//********************************************************************
uint32 CMeshPath::GetCanArriveGoalPoint(const Vector2f& begin, const Vector2f& end, const CNavMesh* pMesh, uint32 nBeginIndex, Vector2f& outPoint)
{
	if (NULL == pMesh)
	{
		return FAILED_TRIGON_INDEX;
	}
		
	m_OriginEnd = end;
	m_OriginBegin = begin;
	return FindPoint(nBeginIndex, pMesh, outPoint);
}



//********************************************************************
//函数功能: 获得一个可到达的目标点
//第一参数: [IN] 结束位置，mesh的数据指针
//返回说明: 可用的结束点位置
//备注说明: 
//********************************************************************
Vector2f CMeshPath::GetCanArriveGoalPoint(const Vector2f& point, CNavMesh* pMesh)
{
	if (NULL == pMesh)
	{
		return point;
	}
		
	uint32 nIndex = pMesh->GetTrigonIndex(point);
	if (FAILED_TRIGON_INDEX != nIndex)
	{
		return point;
	}

	return ((CNavMesh*)pMesh)->GetNearEndPoint(point);
}
//********************************************************************
//函数功能: 从三角形面片中寻找拐点
//第一参数: [IN] mesh, 目标位置的三角形索引，三角形索引集合，输出
//返回说明: 无
//备注说明: 不能做点位置修正，某些情况会造成传不可到达的地方
//********************************************************************
void CMeshPath::FindSpinodal(const CNavMesh* pMesh, uint32 nEndIndex, std::vector<uint32>& trigonIndex, std::list<Vector2f>& outPoint)
{
	Vector2f left;
	Vector2f right;
	uint8 nSpinodal = E_SPINODAL_START;

	Vector2f lastLeftPoint;
	Vector2f lastRightPoint;

	// 
	Vector2f beginPos = m_OriginBegin;
	int _DebugIndex = 0;

	std::vector<uint32> trigonIndexCopy = trigonIndex;
	
	uint32 nLastI = 0;
	for (uint32 i = 0; i < trigonIndexCopy.size();)
	{
		if (E_SPINODAL_FIND_ONE == nSpinodal)
		{
			for (i = 0; i < trigonIndexCopy.size(); ++i)
			{
				if (i > nLastI && pMesh->PointIsInTrigonIndex(trigonIndexCopy[i], beginPos))
				{
					nLastI = i;
					break;
				}
			}


			if (i >= trigonIndexCopy.size())
			{
				return;
			}

#ifdef _DEBUG_OUT_
			sprintf(g_szInfo, "【find拐点】index=%d, re begin = %d\n", _DebugIndex, i);
			LogInfo(g_szInfo);
#endif
		}
		
		++_DebugIndex;
		uint32 nIndex = trigonIndexCopy[i];
		if (nIndex == nEndIndex)
		{
			if (E_SPINODAL_LOOP == nSpinodal)
			{
				uint8 _tmp_left = CFormula::GetLineDirection(beginPos, lastLeftPoint, m_OriginEnd);
				uint8 _tmp_right = CFormula::GetLineDirection(beginPos, lastRightPoint, m_OriginEnd);
				if ((E_Line_Direction_Left == _tmp_right || E_Line_Direction_Online == _tmp_right) && (E_Line_Direction_Right == _tmp_left || E_Line_Direction_Online == _tmp_left))
				{
					return;
				}

				nSpinodal = E_SPINODAL_FIND_ONE;
				// 这里是本身足以成为拐点，然后才会继续寻找
				// 点在左右的右边 || 点在左右的左边
				if (E_Line_Direction_Right == _tmp_right && E_Line_Direction_Right == _tmp_left)
				{
					beginPos = lastRightPoint;
					outPoint.push_back(lastRightPoint);
				}
				else
				{
					beginPos = lastLeftPoint;
					outPoint.push_back(lastLeftPoint);
				}
				i = 0;
				continue;
			}
			
			return;
		}
				
		if (i + 1 >= trigonIndexCopy.size())
		{
			sprintf(g_szInfo, "begin=%.2f,%.2f, end=%.2f,%.2f bug,map=%d", m_OriginBegin[0], m_OriginBegin[1], m_OriginEnd[0], m_OriginEnd[1], pMesh->GetMapID());
			REPORT(g_szInfo);
			break;
		}
				
		if (!GetNextLeftRightPoint(nIndex, trigonIndexCopy[i + 1], pMesh, left, right))
		{
			sprintf(g_szInfo, "begin=%.2f,%.2f, end=%.2f,%.2f bug,map=%d", m_OriginBegin[0], m_OriginBegin[1], m_OriginEnd[0], m_OriginEnd[1], pMesh->GetMapID());
			REPORT(g_szInfo);

			++i;
			continue;
		}
		
#ifdef _DEBUG_OUT_
		sprintf(g_szInfo, "index=%d, find left :%.2f, %.2f, right:%.2f,%.2f\n", _DebugIndex, left[0], left[1], right[0], right[1]);
		LogInfo(g_szInfo);
#endif
		if (E_SPINODAL_LOOP != nSpinodal)
		{
			nSpinodal = E_SPINODAL_LOOP;
			lastLeftPoint = left;
			lastRightPoint = right;
			++i;
			continue;
		}
		

        // 新的左点相对于老左点位置， 新的右点相对于老右点位置
		uint8 leftSpinodal_left = CFormula::GetLineDirection(beginPos, lastLeftPoint, left);
		uint8 rightSpinodal_right = CFormula::GetLineDirection(beginPos, lastRightPoint, right);

#ifdef _DEBUG_OUT_
		sprintf(g_szInfo, "index=%d, left left :dir, %d, right right dir %d\n", _DebugIndex, leftSpinodal_left, rightSpinodal_right);
		LogInfo(g_szInfo);
#endif
		// 防止拐点作为起点，然后左右点其中一个点和起点相同
		if (E_Line_Direction_Online == leftSpinodal_left && E_Line_Direction_Online == rightSpinodal_right)
		{
			lastLeftPoint = left;
			lastRightPoint = right;
			++i;
			continue;
		}

		// 新的左点相对于老右点位置， 新的右点相对于老左点位置
		uint8 rightSpinodal_left = CFormula::GetLineDirection(beginPos, lastRightPoint, left);
		uint8 leftSpinodal_right = CFormula::GetLineDirection(beginPos, lastLeftPoint, right);

		// 左右点只能有一个相等才能成为拐点
		uint8 nLeftSpinodal = 0;
		if (E_Line_Direction_Online == leftSpinodal_left)
		{
			++nLeftSpinodal;
		}
		if (E_Line_Direction_Online == leftSpinodal_right)
		{
			++nLeftSpinodal;
		}
		if (nLeftSpinodal < 2 && (E_Line_Direction_Left == leftSpinodal_left || E_Line_Direction_Online == leftSpinodal_left) && (E_Line_Direction_Left == leftSpinodal_right || E_Line_Direction_Online == leftSpinodal_right))
		{

			outPoint.push_back(lastLeftPoint);
			nSpinodal = E_SPINODAL_FIND_ONE;
			beginPos = lastLeftPoint;
			
#ifdef _DEBUG_OUT_
			sprintf(g_szInfo, "left 【拐点】 :pos=%.2f,%.2f, next  left :%.2f, %.2f, right:%.2f,%.2f\n", beginPos[0], beginPos[1], lastLeftPoint[0], lastLeftPoint[1], lastRightPoint[0], lastRightPoint[1]);
			LogInfo(g_szInfo);
#endif
			continue;
		}
		
		
		uint8 nRightSpinodal = 0;
		if (E_Line_Direction_Online == rightSpinodal_right)
		{
			++nRightSpinodal;
		}
		if (E_Line_Direction_Online == rightSpinodal_left)
		{
			++nRightSpinodal;
		}

		if (nRightSpinodal < 2 && (E_Line_Direction_Right == rightSpinodal_right || E_Line_Direction_Online == rightSpinodal_right) && (E_Line_Direction_Right == rightSpinodal_left || E_Line_Direction_Online == rightSpinodal_left))
		{
			outPoint.push_back(lastRightPoint);
			nSpinodal = E_SPINODAL_FIND_ONE;
			beginPos = lastRightPoint;
			
#ifdef _DEBUG_OUT_
			sprintf(g_szInfo, "right 【拐点】 :pos=%.2f,%.2f, next  left :%.2f, %.2f, right:%.2f,%.2f\n", beginPos[0], beginPos[1], lastLeftPoint[0], lastLeftPoint[1], lastRightPoint[0], lastRightPoint[1]);
			LogInfo(g_szInfo);
#endif
			continue;
		}

		++i;
		// 新的左点在左点右边
		if (E_Line_Direction_Right == leftSpinodal_left)
		{
#ifdef _DEBUG_OUT_
			sprintf(g_szInfo, "up left index=%d, last=%.2f,%.2f, new  left :%.2f, %.2f\n", _DebugIndex, lastLeftPoint[0], lastLeftPoint[1], left[0], left[1]);
			LogInfo(g_szInfo);
#endif
			lastLeftPoint = left;
		}

		// 新的右点在右点左边
		if (E_Line_Direction_Left == rightSpinodal_right)
		{
#ifdef _DEBUG_OUT_
			sprintf(g_szInfo, "up right index=%d, last=%.2f,%.2f, new  right:%.2f,%.2f\n", _DebugIndex, lastRightPoint[0], lastRightPoint[1], right[0], right[1]);
			LogInfo(g_szInfo);
#endif
			lastRightPoint = right;
		}

	}
}
//********************************************************************
//函数功能: 获得三角形的下一个左右点
//第一参数: [IN] 
//返回说明: 找到点true
//备注说明: 
//********************************************************************
bool CMeshPath::GetNextLeftRightPoint(uint32 nIndex, uint32 nNextIndex, const CNavMesh* pMesh, Vector2f& left, Vector2f& right)
{
	if (!pMesh->GetTrigonLeftRightPoint(nIndex, nNextIndex, left, right))
	{
		sprintf(g_szInfo, "index=%u, next=%u, bug,map=%d", nIndex, nNextIndex, pMesh->GetMapID());
		REPORT(g_szInfo);
		return false;
	}
	return true;
}


//********************************************************************
//函数功能: 先通过A*查找三角形的编号
//第一参数: [IN] 开始面片index，结束面片index，outPoint编号，mesh的数据指针
//返回说明: 无
//备注说明: 
//********************************************************************
void  CMeshPath::FindTrigon(uint32 iBeginIndex, uint32 iEndIndex, std::vector<uint32>& outPoint, const CNavMesh* pMesh)
{	
	m_cOpen.clear();
	m_cClose.clear();
	outPoint.clear();
	
	PathNode *node = new PathNode; 
	node->trigonIndex = iBeginIndex;
	node->origin = m_OriginBegin;
	node->g = 0;  node->h = 0; node->f = node->g + node->h;
	node->pFather = NULL; 

	m_cOpen.push_front(node);
	while (!m_cOpen.empty())
	{
		OPEN_TABLE::iterator it = m_cOpen.begin();
		OPEN_TABLE::iterator smallIt = it;
		for (; m_cOpen.end() != it; ++it)
		{
			PathNode* pTmp = (*smallIt);
			PathNode* pLoop = (*it);
			if (pTmp->f > pLoop->f)
			{
				smallIt = it;
			}
		}
		
		node = *smallIt;
		m_cClose.push_back(node);
		m_cOpen.erase(smallIt);
		
		if (node->trigonIndex == iEndIndex)
		{
			const PathNode *pPathNode = node;
			outPoint.insert(outPoint.begin(), iEndIndex);
			
			while (NULL != pPathNode->pFather)
			{	
				pPathNode = pPathNode->pFather;
				outPoint.insert(outPoint.begin(), pPathNode->trigonIndex);
			}
			break;
		}

		GenerateNext(node, pMesh);
	}

	for (OPEN_TABLE::iterator it = m_cClose.begin(); m_cClose.end() != it; ++it)
	{
		delete *it;
	}

	for (OPEN_TABLE::iterator it = m_cOpen.begin(); m_cOpen.end() != it; ++it)
	{
		delete *it;
	}

	m_cClose.clear();
	m_cOpen.clear();

}

//********************************************************************
//函数功能: 找到最近的一个点
//第一参数: [IN] mesh, 目标位置的三角形索引，备选点，输出
//返回说明: 无
//备注说明: 
//********************************************************************
uint32 CMeshPath::FindPoint(uint32 iBeginIndex, const CNavMesh* pMesh, Vector2f& outPoint)
{
	m_cOpen.clear();
	m_cClose.clear();
	PathNode *node = new PathNode; 
	node->trigonIndex = iBeginIndex;
	node->origin = m_OriginBegin;
	node->g = 0;  node->h = 0; node->f = node->g + node->h;
	node->pFather = NULL; 

	m_cOpen.push_front(node);
	
	Vector2f lastNearCross;
	lastNearCross.setZero();
	bool bFindis = false;
	float distance = 0.0f;

	uint32 nNewIndex = FAILED_TRIGON_INDEX;
	while (!m_cOpen.empty())
	{
		OPEN_TABLE::iterator it = m_cOpen.begin();
		OPEN_TABLE::iterator smallIt = it;
		for (; m_cOpen.end() != it; ++it)
		{
			PathNode* pTmp = (*smallIt);
			PathNode* pLoop = (*it);
			if (pTmp->f > pLoop->f)
			{
				smallIt = it;
			}
		}

		node = *smallIt;
		m_cClose.push_back(node);
		m_cOpen.erase(smallIt);

		Vector2f _cross;
		float _dis = 0.0f;
		if (pMesh->GetGainOnEndPoint(node->trigonIndex, m_OriginEnd, _dis, _cross))
		{
			if (!bFindis)
			{
				nNewIndex = node->trigonIndex;
				bFindis = true;
				distance = _dis;
				lastNearCross = _cross;
			}
			else
			{
				if (_dis < distance)
				{
					nNewIndex = node->trigonIndex;
					distance = _dis;
					lastNearCross = _cross;
				}
			}
		}
		GenerateNext(node, pMesh);
	}

	for (OPEN_TABLE::iterator it = m_cClose.begin(); m_cClose.end() != it; ++it)
	{
		delete *it;
	}

	for (OPEN_TABLE::iterator it = m_cOpen.begin(); m_cOpen.end() != it; ++it)
	{
		delete *it;
	}

	m_cClose.clear();
	m_cOpen.clear();

	
	if (!bFindis)
	{
		outPoint = m_OriginBegin;
		return iBeginIndex;
	}

	outPoint = lastNearCross;
	return nNewIndex;
}

//********************************************************************
//函数功能: 执行寻找下一步的操作
//第一参数: [IN] 父节点，mesh数据
//返回说明: 无
//备注说明: 
//********************************************************************
void  CMeshPath::GenerateNext(const PathNode* pFather, const CNavMesh* pMesh)
{
	const STrigon* pFatherTrigon = pMesh->GetTrigon(pFather->trigonIndex);
	if (NULL == pFatherTrigon)
	{
		sprintf(g_szInfo, "mesh =%d超过索引最大值,map=%d", pFather->trigonIndex, pMesh->GetMapID());
		REPORT(g_szInfo);
		return;
	}

	for (ADJOIN_TRIGON::const_iterator it = pFatherTrigon->adjoin.begin(); pFatherTrigon->adjoin.end() != it; ++it)
	{
		SetNextTile(pFather, (*it), pMesh);
	}
}

//********************************************************************
//函数功能: 获得三角形的两个点，根据两个点计算g和h
//第一参数: [IN] 父节点，三角形编号，mesh数据
//返回说明: 无
//备注说明: 
//********************************************************************
bool CMeshPath::GetTrigonCrossPoint(const Vector2f& origin, uint32 nFatherIndex, uint32 nChildIndex, const CNavMesh* pMesh, Vector2f& point_a, Vector2f& point_b)
{
	if (pMesh->GetTrigonBERayCrossPoint(origin, m_OriginEnd,nFatherIndex, nChildIndex, point_a, point_b))
	{
		return true;
	}

	if (pMesh->GetTrigonRayCrossPoint(origin, nFatherIndex, nChildIndex, point_a, point_b))
	{
		return true;
	}

	return false;
}

//********************************************************************
//函数功能: 设置a*的下一个地块
//第一参数: [IN] 父节点，三角形编号，mesh数据
//返回说明: 无
//备注说明: 
//********************************************************************
void  CMeshPath:: SetNextTile(const PathNode* pFather, uint32 nextIndex, const CNavMesh* pMesh)
{
	/*if (!pMesh->CanPass(nextx, nexty))
	{
		return;
	}*/

	for (OPEN_TABLE::iterator it = m_cClose.begin(); m_cClose.end() != it; ++it)
	{
		if ((*it)->trigonIndex == nextIndex)
		{
			return;
		}
	}
	
	Vector2f point_a;
	Vector2f point_b;
	if (!GetTrigonCrossPoint(pFather->origin, pFather->trigonIndex, nextIndex, pMesh, point_a, point_b))
	{
		return;
	}
	

	for (OPEN_TABLE::iterator it = m_cOpen.begin(); m_cOpen.end() != it; ++it)
	{
		PathNode *pOpen = *it;
		if (pOpen->trigonIndex == nextIndex)
		{
			// 
			
			float newg = pFather->g + GetG(point_a, point_b);
			if (newg < pOpen->g)
			{
				float distance = GetaStarReviseDistance(pFather->origin, point_a);
				pOpen->g = newg;
				pOpen->f = pOpen->g + pOpen->h + distance;
				pOpen->pFather = pFather;
			}
			return;
		}
	}
	
	PathNode* node = new PathNode; 
	node->trigonIndex = nextIndex;
	node->origin = CFormula::GetPointMiddle(point_a, point_b);
	float g = GetG(point_a, point_b);
	node->g = pFather->g + g;
	// old 
	//node->h = GetH(pMesh->GetTrigonMiddle(nextIndex), m_OriginEnd); 
	// new
	float distance = GetaStarReviseDistance(pFather->origin, point_a);
	node->h = GetH(node->origin, m_OriginEnd) + distance; 
	node->f = node->g + node->h;
	node->pFather = pFather; 
	m_cOpen.push_back(node);
}

//********************************************************************
//函数功能: 获得astar的g计算中修正距离，
//第一参数: [IN] 三角形的起点
//返回说明: 距离
//备注说明: 起点到三角形到终点修正值
//********************************************************************
float CMeshPath::GetaStarReviseDistance(const Vector2f& point, const Vector2f& next)
{
	return CFormula::GetPointDistance(point, next);
}

//********************************************************************
//函数功能: 获得h
//第一参数: [IN] 起点，结束点
//返回说明: 距离
//备注说明: 使用该三角形的中心点（3个顶点的平均值）到路径终点的x和y方向的距离
//********************************************************************
float CMeshPath::GetH(const Vector2f& point, const Vector2f& end)
{
	return CFormula::GetPointDistance(point, end);
}

//********************************************************************
//函数功能: 获得g
//第一参数: [IN] 穿入边和穿出边的中点
//返回说明: 距离
//备注说明: 采用穿入边和穿出边的中点的距离, 
//********************************************************************
float CMeshPath::GetG(const Vector2f& point_a, const Vector2f& point_b)
{
	return CFormula::GetPointDistance(point_a, point_b);// + CNavMesh::GetPointDistance(newOrgin, m_OriginEnd);
}