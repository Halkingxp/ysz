#include "NavMesh.h"
#include "Xml/Xml.h"
#include "Formula/Formula.h"
#include "Assert/Assert.h"

#define FLOAT_CHECK_TOLERANT 0.001
#define FLOAT_CHECK_TOLERANT_DEVIATION 0.01

CNavMesh::CNavMesh(void)
{
	m_nMapID = 0;
	m_fMindis = 0.0f;
	m_nIndex = FAILED_TRIGON_INDEX;
}

CNavMesh::~CNavMesh(void)
{
}

//********************************************************************
//函数功能: 初始化navmesh地图
//第一参数: [IN] 地图ID
//返回说明: 返回true, 初始化成功
//备注说明: 
//********************************************************************
bool CNavMesh::Init(uint16 nMapID, const std::string& directPath)
{
	m_cMeshPoint.clear();
	m_cTrigon.clear();

	m_nMapID=  nMapID;
	char szTmp[256] = "";

	CXml vertices;
	sprintf(szTmp, "%d_vertices.xml", nMapID);
	String verticesPath = directPath + szTmp;

	vertices.OpenXmlFile(verticesPath.c_str());
	vertices.Iterator();
	
	float fMin_x = 0.0f;
	float fMax_x = 0.0f;

	float fMin_z = 0.0f;
	float fMax_z = 0.0f;
	while (!vertices.IsDone())
	{
		MeshPoint point;
		point.nIndex = vertices.ReadInt("index");
		point.position[0] = vertices.ReadFloat("x");
		point.position[1] = vertices.ReadFloat("z");
		point._y = vertices.ReadFloat("y");

		if (point.position[0] < fMin_x)
		{
			fMin_x = point.position[0];
		}

		if (point.position[0] > fMax_x)
		{
			fMax_x = point.position[0];
		}

		// ----
		if (point.position[1] < fMin_z)
		{
			fMin_z = point.position[1];
		}

		if (point.position[1] > fMax_z)
		{
			fMax_z = point.position[1];
		}
		m_cMeshPoint.push_back(point);
		vertices.Next();
	}
	std::sort(m_cMeshPoint.begin(), m_cMeshPoint.end());


	CXml indices;
	sprintf(szTmp, "%d_indices.xml", nMapID);
	String indicesPath = directPath + szTmp;
	indices.OpenXmlFile(indicesPath.c_str());
	indices.Iterator();
	std::vector<SVerIndex> verticesIndex;
	while (!indices.IsDone())
	{
		SVerIndex tmp;
		tmp.nIndex = indices.ReadInt("index");
		tmp.verindex = indices.ReadInt("verticesIndex");
		indices.Next();
		if (tmp.verindex >= m_cMeshPoint.size())
		{
			sprintf(g_szInfo, "初始化%d号地图时,mesh的索引数据超过索引最大值", nMapID);
			REPORT(g_szInfo);
			continue;
		}
		
		verticesIndex.push_back(tmp);
	}
	
	// 优化邻接三角形的判断
	TRIGON_OPTIMIZE optimize;
	std::sort(verticesIndex.begin(), verticesIndex.end());
	STrigon trigon;
	for (uint32 i = 0, nTrigonPointIndex = 0, nTrigon = 0; i < verticesIndex.size(); ++i)
	{
		trigon.nodeIndex[nTrigonPointIndex++] = verticesIndex[i].verindex;

		if (verticesIndex[i].verindex >= m_cMeshPoint.size())
		{
			sprintf(g_szInfo, "初始化%d号地图时,mesh的索引数据超过索引最大值", nMapID);
			REPORT(g_szInfo);
		}

		if (C_TRIGON_NUM == nTrigonPointIndex)
		{
			nTrigonPointIndex = 0;
			bool bDiscard = false;
			for (uint32 j = 0; j < C_TRIGON_NUM; ++j)
			{
				if (m_cMeshPoint[trigon.nodeIndex[j]]._y < 0)
				{
					bDiscard = true;
					break;
				}
			}

			if (bDiscard)
			{
				continue;
			}
			trigon.nIndex = nTrigon++;
			m_cTrigon.push_back(trigon);

			for (uint32 j = 0 ; j < C_TRIGON_NUM; ++j)
			{
				uint32 _PointIndex = trigon.nodeIndex[j];
				TRIGON_OPTIMIZE::iterator it = optimize.find(_PointIndex);
				if (optimize.end() == it)
				{
					SLoadOptimize tmp;tmp.adjoin.insert(trigon.nIndex);
					optimize[_PointIndex] = tmp;
				}
				else
				{
					it->second.adjoin.insert(trigon.nIndex);
				}

			}
		}
	}
	

	ADJOIN_OPTIMIZE mergerIndex;
	for (uint32 i = 0; i < m_cTrigon.size(); ++i)
	{
		STrigon& trigon = m_cTrigon[i];
		trigon.middle = _GetTrigonMiddle(i);
		mergerIndex.clear();
		for (uint32 j = 0; j < C_TRIGON_NUM; ++j)
		{
			TRIGON_OPTIMIZE::iterator it = optimize.find(trigon.nodeIndex[j]);
			if (optimize.end() == it)
			{
				continue;
			}

			for (ADJOIN_OPTIMIZE::iterator itAdjoin = it->second.adjoin.begin(); it->second.adjoin.end() != itAdjoin; ++itAdjoin)
			{
				uint32 _nIndex = *itAdjoin;
				mergerIndex.insert(_nIndex);
			}
		}

		for (ADJOIN_OPTIMIZE::iterator itAdjoin = mergerIndex.begin(); mergerIndex.end() != itAdjoin; ++itAdjoin)
		{
			uint32 _nIndex = *itAdjoin;
			STrigon& other = m_cTrigon[_nIndex];
			if (other.nIndex == trigon.nIndex)
			{
				continue;
			}

			if (IsBorder(trigon, other, NULL))
			{
				if (!IsExistAdjoinIndex(trigon, other.nIndex))
				{
					trigon.adjoin.push_back(other.nIndex);
				}
				if (!IsExistAdjoinIndex(other, trigon.nIndex))
				{
					other.adjoin.push_back(trigon.nIndex);
				}
			}
		}
	}	
	

	m_Tree.SetBindFun(this, CNavMesh::IsCrossQuad, CNavMesh::PointIsInTrigon, CNavMesh::PointNearEnd);

	Vector2f leftUp(fMin_x, fMax_z);
	Vector2f rightDown(fMax_x, fMin_z);


	float ab = CFormula::GetPointDistance(leftUp, rightDown);
	// 估值一个深度
	m_Tree.InitTree((uint8)(ab / 20.0f), leftUp, rightDown);
	for (uint32 i = 0; i < m_cTrigon.size(); ++i)
	{
		if (!m_Tree.InsertData(m_cTrigon[i].nIndex))
		{
			sprintf(g_szInfo, "初始化%d号地图时,id=%d 插入失败", nMapID, m_cTrigon[i].nIndex);
			REPORT(g_szInfo);

		}
	}

	printf("mapid=%d, size=%d,size=%d\n", nMapID, m_cMeshPoint.size(), m_cTrigon.size());
	return true;
}

//********************************************************************
//函数功能: 是否存在邻接的三角形索引
//第一参数: 三角形的结构，判断的所有
//返回说明: true存在
//备注说明: 
//********************************************************************
bool CNavMesh::IsExistAdjoinIndex(const STrigon& trigon, uint32 nIndex)const
{
	for (uint32 i = 0 ; i < trigon.adjoin.size(); ++i)
	{
		if (nIndex == trigon.adjoin[i])
		{
			return true;
		}
	}

	return false;
}
//********************************************************************
//函数功能: 获得三角形的数据指针
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
const STrigon*  CNavMesh::GetTrigon(uint32 nIndex) const
{
	if (nIndex >= m_cTrigon.size())
	{
		return NULL;
	}
	return &m_cTrigon[nIndex];
}

//********************************************************************
//函数功能: 获得三角形的中点
//第一参数: [IN] 三角形数据
//返回说明: 
//备注说明: 三角形的中心点（3个顶点的平均值）
//********************************************************************
Vector2f CNavMesh::_GetTrigonMiddle(uint32 nIndex) const
{
	Vector2f tmp;
	const STrigon& obj = m_cTrigon[nIndex];
	const MeshPoint& _a = m_cMeshPoint[obj.nodeIndex[0]];
	const MeshPoint& _b = m_cMeshPoint[obj.nodeIndex[1]];
	const MeshPoint& _c = m_cMeshPoint[obj.nodeIndex[2]];

	tmp[0] = (_a.position[0] + _b.position[0] + _c.position[0]) / 3;
	tmp[1] = (_a.position[1] + _b.position[1] + _c.position[1]) / 3;
	return tmp;
}
//********************************************************************
//函数功能: 根据终点和靠近的三角获得一个靠近终点的可到达点
//第一参数: [IN] 终点，三角形索引
//返回说明: 可到达点
//备注说明: 
//********************************************************************
Vector2f CNavMesh::GetNearEndPoint(const Vector2f& end)
{
	Vector2f outPoint;
	outPoint.setZero();
	m_Tree.GetNearEndPoint(end, outPoint);
	return outPoint;
}

//********************************************************************
//函数功能: 根据终点和靠近的三角获得一个靠近终点的可到达点
//第一参数: [IN] 终点，三角形索引
//返回说明: 可到达点
//备注说明: 
//********************************************************************
bool CNavMesh::GetGainOnEndPoint(uint32 nIndex, const Vector2f& end, float& distance, Vector2f& cross)const
{
	if (nIndex >= m_cMeshPoint.size())
	{
		return false;
	}

	
	const STrigon& obj = m_cTrigon[nIndex];
	const Vector2f& middle = obj.middle;
	bool bFirst = true;
	distance = 0.0f;
	
	Vector2f _cross;
	for (uint32 i = 0 ; i < C_TRIGON_NUM; ++i)
	{
		const Vector2f& _ind_a = m_cMeshPoint[obj.nodeIndex[i]].position;
		for (uint32 j = i + 1; j < C_TRIGON_NUM; ++j)
		{
			const Vector2f& _ind_b = m_cMeshPoint[obj.nodeIndex[j]].position;
			if (!CFormula::IsIntersectAnt(middle, end, _ind_a, _ind_b, _cross))
			{
				continue;
			}

			float _newDis = CFormula::GetPointDistance(_cross, end);
			if (bFirst)
			{
				bFirst = false;
				cross = _cross;
				distance = _newDis;
				continue;
			}

			
			if (_newDis < distance)
			{
				distance = _newDis;
				cross = _cross;
			}
		}
	}

	if (bFirst)
	{
		return false;
	}
	return true;
}

//********************************************************************
//函数功能: 根据位置获得三角形索引
//第一参数: [IN] 点击的x z
//返回说明: 索引，点击的位置不在三角形内返回0xffffffff
//备注说明: 矢量积计算面积
//********************************************************************
uint32 CNavMesh::GetTrigonIndex(const Vector2f& point)
{
	uint32 nData = 0;
	m_fMindis = 1.0f;
	m_nIndex = FAILED_TRIGON_INDEX;
	if (m_Tree.FindData(point, nData))
	{
		return nData;
	}	

	if (m_fMindis < FLOAT_CHECK_TOLERANT_DEVIATION)
	{
		return m_nIndex;
	}
	return FAILED_TRIGON_INDEX;
}


//********************************************************************
//函数功能: 根据位置获得三角形索引
//第一参数: [IN] 点击的x z
//返回说明: 索引，点击的位置不在三角形内返回0xffffffff
//备注说明: 面积法
//********************************************************************
uint32 CNavMesh::GetTrigonIndex_1(const Vector2f& point)const
{
	
	const Vector2f& p = point;
	Vector2f a, b, c;

	Vector2f ab;
	Vector2f ac;
	Vector2f ap;
	for (uint32 i = 0 ; i < m_cTrigon.size(); ++i)
	{
		const STrigon& trigon = m_cTrigon[i];

		const MeshPoint& _a = m_cMeshPoint[trigon.nodeIndex[0]];
		const MeshPoint& _b = m_cMeshPoint[trigon.nodeIndex[1]];
		const MeshPoint& _c = m_cMeshPoint[trigon.nodeIndex[2]];

		float triangleArea = CFormula::TrigonArea(_a.position, _b.position, _c.position);
		float area = CFormula::TrigonArea(point, _a.position, _b.position);
		area += CFormula::TrigonArea(point, _a.position, _c.position);
		area += CFormula::TrigonArea(point, _b.position, _c.position);

		// 算了太多的除法，减少误差范围
		float delta = fabs(triangleArea - area);
		if (delta < FLOAT_CHECK_TOLERANT)
		{
			return i;
		}

	}
	return FAILED_TRIGON_INDEX;
}


//********************************************************************
//函数功能: 起点到终点一条射线，是否穿越该三角形，穿越获得穿入边和穿出边
//第一参数: [IN] 起点终点,三角形索引
//第二参数: [OUT] 父节点和子节点的索引
//返回说明: true获得两个点
//备注说明:
//********************************************************************
bool CNavMesh::GetTrigonBERayCrossPoint(const Vector2f& origin, const Vector2f& end, uint32 nFatherIndex, uint32 nChildIndex, Vector2f& point_a, Vector2f& point_b)const
{
	const STrigon* pTrigon = this->GetTrigon(nFatherIndex);
	const STrigon* pTrigonChild = this->GetTrigon(nChildIndex);
	if (NULL == pTrigon || NULL == pTrigonChild)
	{
		sprintf(g_szInfo, "mesh =%d, =%d超过索引最大值,map=%d", nFatherIndex, nChildIndex, this->GetMapID());
		REPORT(g_szInfo);
		return false;
	}

	ADJOIN_TRIGON point;
	this->IsBorder(*pTrigon, *pTrigonChild, &point);
	if (2 != point.size())
	{
		sprintf(g_szInfo, "bug,相邻三角形两点没有2个. index=%d,index=%d, map=%d", nFatherIndex, nChildIndex, this->GetMapID());
		REPORT(g_szInfo);
		return false;
	}

	// 相邻边的点数据
	uint32 adjoin_a = point[0];
	uint32 adjoin_b = point[1];
	
	Vector2f cross;
	bool bFind = false;
	for (uint32 i = 0; i < C_TRIGON_NUM; ++i)
	{
		uint32 _a = pTrigon->nodeIndex[i];
		for (uint32 j = i + 1; j < C_TRIGON_NUM; ++j)
		{
			// 
			uint32 _b = pTrigon->nodeIndex[j];

			if (CFormula::IsIntersectAnt(origin, end, m_cMeshPoint[_a].position, m_cMeshPoint[_b].position, cross))
			{
				if (!bFind)
				{
					bool bAdjoin = false;
					// 保证穿入边一定是邻边
					if (! ((adjoin_a == _a && adjoin_b == _b) || (adjoin_a == _b && adjoin_b == _a)) )
					{
						return false;
					}

					
					point_a = CFormula::GetPointMiddle(m_cMeshPoint[_a].position, m_cMeshPoint[_b].position);;
					bFind = true;
					continue;
				}
				
				point_b = CFormula::GetPointMiddle(m_cMeshPoint[_a].position, m_cMeshPoint[_b].position);;
				return true;
			}
			
		}
	}
	return false;
}
//********************************************************************
//函数功能: 父三角形中一个点，到相邻的子三角形共边垂线做一条射线，获得该射线的穿入边和穿出边的点,  没有射线则从起点到相邻边中点做一条射线
//第一参数: [IN] 原始的trigon
//第二参数: [OUT] 父节点和子节点的索引
//返回说明: true获得两个点
//备注说明:
//********************************************************************
bool CNavMesh::GetTrigonRayCrossPoint(const Vector2f& origin, uint32 nFatherIndex, uint32 nChildIndex, Vector2f& point_a, Vector2f& point_b)const
{
	const STrigon* pTrigon = this->GetTrigon(nFatherIndex);
	const STrigon* pTrigonChild = this->GetTrigon(nChildIndex);
	if (NULL == pTrigon || NULL == pTrigonChild)
	{
		sprintf(g_szInfo, "mesh =%d, =%d超过索引最大值,map=%d", nFatherIndex, nChildIndex, this->GetMapID());
		REPORT(g_szInfo);
		return false;
	}

	ADJOIN_TRIGON point;
	this->IsBorder(*pTrigon, *pTrigonChild, &point);
	if (2 != point.size())
	{
		sprintf(g_szInfo, "bug,相邻三角形两点没有2个. index=%d,index=%d, map=%d", nFatherIndex, nChildIndex, this->GetMapID());
		REPORT(g_szInfo);
		return false;
	}

	// 相邻边的点数据
	uint32 adjoin_a = point[0];
	uint32 adjoin_b = point[1];

	// ----------------------     到相邻的子三角形共边垂线做一条射线，获得该射线的穿入边和穿出边的点 ---------------------------
	Vector2f _reviseOrigin = origin;
	if (CFormula::PointIsOnSegment(origin, m_cMeshPoint[adjoin_a].position, m_cMeshPoint[adjoin_b].position))
	{
		_reviseOrigin = GetOriginCheck(nFatherIndex);
	}
	
	Vector2f corss_point = CFormula::GetLintVertical(m_cMeshPoint[adjoin_a].position, m_cMeshPoint[adjoin_b].position, _reviseOrigin);
	if (!CFormula::PointIsOnSegment(corss_point, m_cMeshPoint[adjoin_a].position, m_cMeshPoint[adjoin_b].position))
	{
		corss_point = CFormula::GetPointMiddle(m_cMeshPoint[adjoin_a].position, m_cMeshPoint[adjoin_b].position);
	}
	
	bool bFind = false;	
	Vector2f cross;
	for (uint32 i = 0; i < C_TRIGON_NUM; ++i)
	{
		uint32 _a = pTrigonChild->nodeIndex[i];
		for (uint32 j = i + 1; j < C_TRIGON_NUM; ++j)
		{
			// 
			uint32 _b = pTrigonChild->nodeIndex[j];
			if (adjoin_a == _a && adjoin_b == _b)
			{
				continue;
			}

			if (adjoin_a == _b && adjoin_b == _a)
			{
				continue;
			}

			if (CFormula::IsIntersectAnt(_reviseOrigin, corss_point, m_cMeshPoint[_a].position, m_cMeshPoint[_b].position, cross))
			{
				point_a = CFormula::GetPointMiddle(m_cMeshPoint[adjoin_a].position, m_cMeshPoint[adjoin_b].position);
				point_b = CFormula::GetPointMiddle(m_cMeshPoint[_a].position, m_cMeshPoint[_b].position);
				return true;
			}
		}
	}
	
	// -------------------------------------没有射线则从起点到相邻边中点做一条射线 ----------------------------
	Vector2f err_a; err_a.setZero();
	Vector2f err_b; err_b.setZero();

	const Eigen::Vector2f middle = CFormula::GetPointMiddle(m_cMeshPoint[adjoin_a].position, m_cMeshPoint[adjoin_b].position);
	for (uint32 i = 0; i < C_TRIGON_NUM; ++i)
	{
		uint32 _a = pTrigonChild->nodeIndex[i];
		for (uint32 j = i + 1; j < C_TRIGON_NUM; ++j)
		{
			// 
			uint32 _b = pTrigonChild->nodeIndex[j];
			if (adjoin_a == _a && adjoin_b == _b)
			{
				continue;
			}

			if (adjoin_a == _b && adjoin_b == _a)
			{
				continue;
			}

			if (CFormula::IsIntersectAnt(_reviseOrigin, middle, m_cMeshPoint[_a].position, m_cMeshPoint[_b].position, cross))
			{
				point_a = middle;
				point_b = CFormula::GetPointMiddle(m_cMeshPoint[_a].position, m_cMeshPoint[_b].position);
				return true;
			}

			err_a = m_cMeshPoint[_a].position;
			err_b = m_cMeshPoint[_b].position;
		}
	}

	if (!bFind)
	{
		sprintf(g_szInfo, "bug,x=%.2f,z=%.2f,没找到射线和线段的交点. index=%d,index=%d, map=%d", origin[0], origin[1],nFatherIndex, nChildIndex, this->GetMapID());
		REPORT(g_szInfo);
	}

	point_a = middle;
	point_b = CFormula::GetPointMiddle(err_a, err_b);
	return true;
}

//********************************************************************
//函数功能: 根据父三角形和子三角形关系获得nav导航的左点和右点
//第一参数: [IN] 索引，[OUT]左右点,
//返回说明::true获得左右点
//备注说明:
//********************************************************************
bool  CNavMesh::GetTrigonLeftRightPoint(uint32 nFatherIndex, uint32 nNextIndex, Vector2f& left, Vector2f& right)const
{
	const STrigon* pTrigon = this->GetTrigon(nFatherIndex);
	const STrigon* pTrigonNext = this->GetTrigon(nNextIndex);
	if (NULL == pTrigon || NULL == pTrigonNext)
	{
		sprintf(g_szInfo, "mesh =%d, =%d超过索引最大值,map=%d", nFatherIndex, nNextIndex, this->GetMapID());
		REPORT(g_szInfo);
		return false;
	}

	ADJOIN_TRIGON point;
	this->IsBorder(*pTrigon, *pTrigonNext, &point);
	if (2 != point.size())
	{
		sprintf(g_szInfo, "bug,相邻三角形两点没有2个. index=%d,index=%d, map=%d", nFatherIndex, nNextIndex, this->GetMapID());
		REPORT(g_szInfo);
		return false;
	}
	
	// 公共边的AB两点
	const uint32 adjoin_a = point[0];
	const uint32 adjoin_b = point[1];
	bool bFindLeft = false;
	bool bFindNotPublic = false;

	const STrigon* pFindTrigon = pTrigon;
	for (uint32 i = 0, j = 0 ; i < C_TRIGON_NUM * 2; ++i, ++j)
	{
		if (j >= C_TRIGON_NUM)
		{
			j = 0;
		}

		if (!bFindNotPublic)
		{
			if (adjoin_a == pFindTrigon->nodeIndex[j] || adjoin_b == pFindTrigon->nodeIndex[j])
			{
				continue;
			}

			bFindNotPublic = true;
			continue;
		}
		

		if (!bFindLeft)
		{
			uint32 nIndex = pFindTrigon->nodeIndex[j];
			left = m_cMeshPoint[nIndex].position;
			bFindLeft = true;
			continue;
		}

		uint32 nIndex = pFindTrigon->nodeIndex[j];
		right = m_cMeshPoint[nIndex].position;
		return true;
	}
	return false;
}

//********************************************************************
//函数功能: 某个顶点索引是否属于某个三角形
//第一参数: [IN] 三角形的索引，点的索引
//返回说明::属于true
//备注说明:
//********************************************************************
bool CNavMesh::PointIsInTrigonIndex(uint32 nIndex, const Vector2f& point) const
{
	const STrigon* pTrigon = this->GetTrigon(nIndex);
	if (NULL == pTrigon)
	{
		sprintf(g_szInfo, "mesh =%d超过索引最大值,map=%d", nIndex, this->GetMapID());
		REPORT(g_szInfo);
		return false;
	}

	for (uint32 i = 0; i < C_TRIGON_NUM; ++i)
	{
		const Vector2f& position = m_cMeshPoint[pTrigon->nodeIndex[i]].position;
		if (CFormula::FloatEqual(point[0], position[0]) && CFormula::FloatEqual(point[1], position[1]))
		//if (point == m_cMeshPoint[pTrigon->nodeIndex[i]].position)
		{
			return true;
		}
	}
	return false;
}


//********************************************************************
//函数功能: 如果选中的点在三角形的边上，那从中心点出发,避免射线方向判断问题
//第一参数: 三角形索引
//返回说明: 
//备注说明: 防止 起点，左点，右点一条线
//********************************************************************
Vector2f CNavMesh::GetOriginCheck(uint32 trigonIndex) const
{
	// 第一个点和   2,3点中点做一个线段，取线段中点
	const STrigon& obj = m_cTrigon[trigonIndex];
	const MeshPoint& _origin = m_cMeshPoint[obj.nodeIndex[0]];
	Vector2f _middle = CFormula::GetPointMiddle(m_cMeshPoint[obj.nodeIndex[1]].position, m_cMeshPoint[obj.nodeIndex[2]].position);
	return CFormula::GetPointMiddle(_origin.position, _middle);
}

//********************************************************************
//函数功能: 是否相邻
//第一参数: [IN] 原始的trigon
//第二参数: [IN] 另外一个trigon
//第三参数: [OUT] 相邻的点的坐标
//返回说明: 返回true, 
//备注说明: 有任意一条边(2个点)相等，即为相邻
//********************************************************************
bool CNavMesh::IsBorder(const STrigon& trigon, const STrigon& other, ADJOIN_TRIGON *pOut)const
{
	if (NULL != pOut)
	{
		pOut->clear();
	}
	
	const STrigon* pTrigonArr[2] = {};
	pTrigonArr[0] = &trigon;
	pTrigonArr[1] = &other;

	std::map<uint32, uint8> statistics;
	std::map<uint32, uint8> ::iterator it;
	for (uint32 j = 0; j < 2; ++j)
	{
		for (uint32 i = 0; i < C_TRIGON_NUM; ++i)
		{
			uint32 nIndex = pTrigonArr[j]->nodeIndex[i];
			it = statistics.find(nIndex);
			if (statistics.end() == it)
			{
				statistics.insert(std::make_pair(nIndex, 1));
			}
			else
			{
				++it->second;
			}
		}
	}
	
	if (NULL == pOut)
	{
		// 有邻边的话，6个点数量为,1,1,2,2,有两个点重合
		if (statistics.size() > 4)
		{
			return false;
		}

		return true;
	}

	uint8 nCount = 0;
	for (it = statistics.begin(); statistics.end() != it; ++it)
	{
		if (it->second >= 2)
		{
			++nCount;
			pOut->push_back(it->first);
		}
	}

	return nCount >= 2;
}

//********************************************************************
//函数功能: 点是否在三角形的索引内
//第一参数: [IN] 点击的位置，三角形索引
//返回说明: true在三角内
//备注说明: 
//********************************************************************
bool CNavMesh::_PointIsInTrigon(const Vector2f& point, const uint32& nIndex)
{
	if (nIndex >= m_cTrigon.size())
	{
		return false;
	}
	const Vector2f& p = point;
	
	const STrigon& trigon = m_cTrigon[nIndex];
	const MeshPoint& _a = m_cMeshPoint[trigon.nodeIndex[0]];
	const MeshPoint& _b = m_cMeshPoint[trigon.nodeIndex[1]];
	const MeshPoint& _c = m_cMeshPoint[trigon.nodeIndex[2]];

	float triangleArea = CFormula::TrigonArea(_a.position, _b.position, _c.position);
	float area = CFormula::TrigonArea(point, _a.position, _b.position);
	area += CFormula::TrigonArea(point, _a.position, _c.position);
	area += CFormula::TrigonArea(point, _b.position, _c.position);

	// 算了太多的除法，减少误差范围
	float delta = fabs(triangleArea - area);
	if (delta < FLOAT_CHECK_TOLERANT)
	{
		return true;
	}

	if (delta < m_fMindis)
	{
		m_fMindis = delta;
		m_nIndex = nIndex;
	}
	return false;


//	Vector2f ab= _b.position - _a.position;
//	Vector2f ac = _c.position - _a.position;
//	Vector2f ap = p - _a.position;
//		
//#define TMP_2DCROSS(a, b)   {a[0]*b[1] - a[1]*b[0]}
//
//	float abc = TMP_2DCROSS(ab, ac);
//	float abp = TMP_2DCROSS(ab, ap);
//	float apc = TMP_2DCROSS(ap, ac);
//	float pbc = abc - abp - apc;
//#undef TMP_2DCROSS
//
//	// 算了太多的除法，减少误差范围
//	float delta = fabs(abc) - fabs(abp) - fabs(apc) -fabs(pbc);
//
//	float _de = fabs(delta);
//	if (_de < FLOAT_CHECK_TOLERANT)
//	{
//		return true;
//	}
//
//	if (_de < m_fMindis)
//	{
//		m_fMindis = _de;
//		m_nIndex = nIndex;
//	}
//	return false;
}

//********************************************************************
//函数功能: 外部绑定的staic函数
//函数作者: wgl
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
bool CNavMesh::IsCrossQuad(void *pThis, const Vector2f& leftUp, const Vector2f& rightDown, const uint32& nData)
{
	CNavMesh *pMesh = (CNavMesh*)pThis;
	return pMesh->_IsCrossQuad(leftUp, rightDown, nData);
}

bool CNavMesh::PointIsInTrigon(void *pThis, const Vector2f& point, const uint32& nData)
{
	CNavMesh *pMesh = (CNavMesh*)pThis;
	return pMesh->_PointIsInTrigon(point, nData);
}

//********************************************************************
//函数功能: 三角形是否和象限相交
//函数作者: wgl
//第一参数: [IN] 左上和右下
//返回说明: 有相交或者在象限内true
//备注说明: 
//********************************************************************  
bool CNavMesh::_IsCrossQuad(const Vector2f& leftUp, const Vector2f& rightDown, const uint32& nData)
{
	if (nData >= m_cTrigon.size())
	{
		return false;
	}

	const STrigon& obj = m_cTrigon[nData];
	
	for (uint32 i = 0 ; i < C_TRIGON_NUM; ++i)
	{
		const Vector2f& _ind = m_cMeshPoint[obj.nodeIndex[i]].position;
		if (CFormula::IsInRect(_ind, leftUp, rightDown))
		{
			return true;
		}
	}
	

	/*   2)
	     ---
	  1)|   | 3)
	    -----
		  4)

	    a --b
	    |   |
	    c---d
	
	*/
	
	EigenRect tmpRect = CFormula::GetRect(leftUp, rightDown);
	for (uint32 i = 0 ; i < C_TRIGON_NUM; ++i)
	{
		const Vector2f& _ind_a = m_cMeshPoint[obj.nodeIndex[i]].position;
		for (uint32 j = i + 1; j < C_TRIGON_NUM; ++j)
		{
			const Vector2f& _ind_b = m_cMeshPoint[obj.nodeIndex[j]].position;

			if (CFormula::LineIntersect(_ind_a, _ind_b, tmpRect._a, tmpRect._b))
			{
				return true;
			}

			if (CFormula::LineIntersect(_ind_a, _ind_b, tmpRect._a, tmpRect._c))
			{
				return true;
			}

			if (CFormula::LineIntersect(_ind_a, _ind_b, tmpRect._b, tmpRect._d))
			{
				return true;
			}

			if (CFormula::LineIntersect(_ind_a, _ind_b, tmpRect._c, tmpRect._d))
			{
				return true;
			}

		}
	}
	return false;
}

//********************************************************************
//函数功能: 根据终点和靠近的三角获得一个靠近终点的可到达点
//函数作者: wgl
//第一参数: [IN] 左上和右下
//返回说明: 
//备注说明: 
//********************************************************************  
bool CNavMesh::PointNearEnd(void *pThis, const Vector2f& point, const uint32& nData, float& distance, Vector2f& outPoint)
{
	CNavMesh *pMesh = (CNavMesh*)pThis;
	return pMesh->_PointNearEnd(point, nData, distance, outPoint);
}

bool  CNavMesh::_PointNearEnd(const Vector2f& end, const uint32& nData, float& outDistance, Vector2f& outPoint)
{
	if (nData >= m_cTrigon.size())
	{
		return false;
	}

	const STrigon& obj = m_cTrigon[nData];
	bool bFirst = true;
	float distance = 0.0f;

	Vector2f cross;
	cross.setZero();
	
	const Vector2f& middle = obj.middle;
	Vector2f _cross;
	for (uint32 i = 0 ; i < C_TRIGON_NUM; ++i)
	{
		const Vector2f& _ind_a = m_cMeshPoint[obj.nodeIndex[i]].position;
		for (uint32 j = i + 1; j < C_TRIGON_NUM; ++j)
		{
			const Vector2f& _ind_b = m_cMeshPoint[obj.nodeIndex[j]].position;
			if (!CFormula::IsIntersectAnt(middle, end, _ind_a, _ind_b, _cross))
			{
				continue;
			}

			float _newDis = CFormula::GetPointDistance(_cross, end);
			if (bFirst)
			{
				bFirst = false;
				cross = _cross;
				distance = _newDis;
				continue;
			}


			if (_newDis < distance)
			{
				distance = _newDis;
				cross = _cross;
			}
		}
	}

	if (!bFirst)
	{
		outDistance = distance;
		outPoint = cross;
		return true;
	}
	return false;
}