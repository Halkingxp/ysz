/*****************************************************************************
Copyright (C), 2008-2009, ***. Co., Ltd.
文 件 名:  navmesh.h
作    者:  gl.wang
版    本:  1.0
完成日期:  2014-12-24
说明信息:  
*****************************************************************************/
#pragma once
#include "Define.h"
#include "Eigen/Dense"
using namespace Eigen;
#include "Formula/Formula.h"


const int C_QUAD_NUM = 4;

// 深度控制
const int C_MAX_DEPTH = 7;

// 优化存储的节点
template<class T>
struct QuadNode
{
	// auad 象限的左上和右下坐标
	Vector2f leftUp;
	Vector2f rightDown;
	std::list<T> trigonIndex;
	QuadNode<T>* pSbu[C_QUAD_NUM];
};

template<class T>
struct QuadTree
{
	QuadNode<T>* pRoot;
	uint8 depth;
};




template<class T>
class CQuadNavmesh
{
	typedef bool  (*ISCROSSQUAD)(void *, const Vector2f&, const Vector2f&, const T&);
	typedef bool  (*POINTISINTRIGON)(void *, const Vector2f&, const T&);
	typedef bool  (*POINTNEAREND)(void *, const Vector2f&, const T&, float&, Vector2f&);
public:
	CQuadNavmesh(void);
	~CQuadNavmesh(void);

public:
	bool  InitTree(uint8 nDepth, const Vector2f& leftUp, const Vector2f& rightDown);
	bool  InsertData(const T& nData);
	bool  FindData(const Vector2f& point, T& nData)const;
	void  SetBindFun(void* pThis, ISCROSSQUAD pIs, POINTISINTRIGON pInTrigon, POINTNEAREND pEnd);
	bool  GetNearEndPoint(const Vector2f& end, Vector2f& outPoint);
private:
	void  _InitLeaf(uint8 nDepth, QuadNode<T>* pNode, Vector2f leftUp, Vector2f rightDown);
	bool  _InsertNode(uint8 nDepth, const T& nData, QuadNode<T>* pNode);
	bool  _AddNode(const Vector2f& leftUp, const Vector2f& rightDown, QuadNode<T>* pNode);
	Vector2f _GetCutPoint(const Vector2f& leftUp, const Vector2f& rightDown);
	bool  _FindData(QuadNode<T>* pNode, const Vector2f& point, T& nData) const;
	void  _GetNearEndPoint(QuadNode<T>* pNode, const Vector2f& end);
	void  _Clear(QuadNode<T>* pNode);
private:

	QuadTree<T>*    m_Tree;
	void*           m_pFunPoint;
	ISCROSSQUAD     m_pIsCrossQuad;
	POINTISINTRIGON m_pPointIsInTrigon;
	POINTNEAREND    m_pNearEndPoint;
	
	bool            m_bInitCross;
	float           m_fDistance;
	Vector2f        m_cross;
};


template<class T>
CQuadNavmesh<T>::CQuadNavmesh(void)
{
	m_Tree = NULL;
	m_pFunPoint = NULL;
	m_pIsCrossQuad = NULL;
	m_pPointIsInTrigon = NULL;
	m_pNearEndPoint = NULL;

	m_bInitCross = false;
	m_fDistance = 0.0f;
	m_cross.setZero();
}

template<class T>
CQuadNavmesh<T>::~CQuadNavmesh(void)
{
	_Clear(m_Tree->pRoot);

	delete m_Tree;
	m_Tree = NULL;
}

template<class T>
void CQuadNavmesh<T>::_Clear(QuadNode<T>* pNode)
{
	pNode->trigonIndex.clear();

	for (int i = 0 ; i < C_QUAD_NUM; ++i)
	{
		if (NULL != pNode->pSbu[i])
		{
			_Clear(pNode->pSbu[i]);
			delete pNode->pSbu[i];
			pNode->pSbu[i] = NULL;
		}
	}
	

}
//********************************************************************
//函数功能: 各种交给对象判断的绑定函数
//函数作者: wgl
//第一参数: [IN] this, func
//返回说明: 
//备注说明: 
//********************************************************************  
template<class T>
void  CQuadNavmesh<T>::SetBindFun(void* pThis, ISCROSSQUAD pIs, POINTISINTRIGON pInTrigon, POINTNEAREND pEnd)
{
	m_pFunPoint = pThis;
	m_pIsCrossQuad = pIs;
	m_pPointIsInTrigon = pInTrigon;
	// 没有u3d的不可到达三角的补丁优化
	m_pNearEndPoint = pEnd;
}
//********************************************************************
//函数功能: 初始化设置树的深度，地图的左上角和右下角
//函数作者: wgl
//第一参数: [IN] 深度，大小数据
//返回说明: 
//备注说明: 
//********************************************************************  
template<class T>
bool CQuadNavmesh<T>::InitTree(uint8 nDepth, const Vector2f& leftUp, const Vector2f& rightDown)
{
	if (NULL != m_Tree)
	{
		return true;
	}

	m_Tree = new QuadTree<T>;
	if (NULL == m_Tree)
	{
		return false;
	}

	if (nDepth < 1)
	{
		nDepth = 1;
	}

	if (nDepth > C_MAX_DEPTH)
	{
		nDepth = C_MAX_DEPTH;
	}
	
	m_Tree->depth = nDepth;
	m_Tree->pRoot = new QuadNode<T>;
	m_Tree->pRoot->leftUp.setZero();
	m_Tree->pRoot->rightDown.setZero();

	for (int i = 0 ; i < C_QUAD_NUM; ++i)
	{
		m_Tree->pRoot->pSbu[i] = NULL;
	}
	
	// 按照depth扩展完毕先
	_InitLeaf(m_Tree->depth, m_Tree->pRoot, leftUp, rightDown);
	return true;
}


//********************************************************************
//函数功能: 初始化设置树的叶子
//函数作者: wgl
//第一参数: 
//返回说明: 
//备注说明: 矩形分割不支持X向上，向下的坐标系，
//********************************************************************  
template<class T>
void  CQuadNavmesh<T>::_InitLeaf(uint8 nDepth, QuadNode<T>* pNode, Vector2f leftUp, Vector2f rightDown)
{
	if (0 == nDepth)
	{
		pNode->leftUp = leftUp;
		pNode->rightDown = rightDown;
		for (int i = 0 ; i < C_QUAD_NUM; ++i)
		{
			pNode->pSbu[i] = NULL;
		}
		return;
	}
	/*   
	 不同的起点，左上和右下不同
	      2 | 1
	      --+--
		  3 | 4
	      
	*/
	Vector2f cut = CFormula::GetCutPoint(leftUp, rightDown);
	EigenRect quad_2 = CFormula::GetRect(leftUp, cut);
	EigenRect quad_4 = CFormula::GetRect(cut, rightDown);
	
	Vector2f cutLeftUp[C_QUAD_NUM];
	Vector2f cutRightDown[C_QUAD_NUM];
	cutLeftUp[0] = quad_2._b;
	cutRightDown[0] = quad_4._b;	
	cutLeftUp[1] = leftUp;
	cutRightDown[1] = cut;
	cutLeftUp[2] = quad_2._c;
	cutRightDown[2] = quad_4._c;
	cutLeftUp[3] = cut;
	cutRightDown[3] = rightDown;

	pNode->leftUp = leftUp;
	pNode->rightDown = rightDown;
	for (int i = 0 ; i < C_QUAD_NUM; ++i)
	{
		//printf("%d x=%.2f,y=%.2f,  x=%.2f,y=%.2f\n", i + 1, cutLeftUp[i][0], cutLeftUp[i][1], cutRightDown[i][0], cutRightDown[i][1]);
		pNode->pSbu[i] = new QuadNode<T>;
		_InitLeaf(nDepth - 1, pNode->pSbu[i], cutLeftUp[i], cutRightDown[i]);
	}
	
}

//********************************************************************
//函数功能: 插入节点
//函数作者: wgl
//第一参数: [IN] 三角形的索引，三角形的数据
//返回说明: 
//备注说明: root也存储数据，防止切割正好横跨4个象限的东西
//********************************************************************
template<class T>
bool CQuadNavmesh<T>::InsertData(const T& nData)
{
	return _InsertNode(m_Tree->depth, nData, m_Tree->pRoot);
}

//********************************************************************
//函数功能: 插入节点
//函数作者: wgl
//第一参数: [IN] 三角形的索引，三角形的矩形包围框
//返回说明: 
//备注说明: 矩形简单点，最多遍历的时候某些奇葩三角形会多判断一下,不会产生bug
//********************************************************************
template<class T>
bool  CQuadNavmesh<T>::_InsertNode(uint8 nDepth, const T& nData, QuadNode<T>* pNode)
{
	if (0 == nDepth)
	{
		pNode->trigonIndex.push_back(nData);
		return true;
	}

	bool bSaveFather = false;
	uint8 nCrossNum = 0;

	int iCrossIndex = -1;
	for (int i = 0 ; i < C_QUAD_NUM; ++i)
	{
		if (NULL == pNode->pSbu[i])
		{
			continue;
		}

		QuadNode<T> *pTmpNode = pNode->pSbu[i];
		if ((*m_pIsCrossQuad)(m_pFunPoint, pTmpNode->leftUp, pTmpNode->rightDown, nData))
		{
			iCrossIndex = i;
			++nCrossNum;
		}


		// 一个多边形跨越多个象限，直接存储在父节点
		if (nCrossNum >= 2)
		{
			pNode->trigonIndex.push_back(nData);
			return true;
		}
	}
	if (-1 == iCrossIndex)
	{
		return false;
	}
	
	return _InsertNode(nDepth - 1, nData, pNode->pSbu[iCrossIndex]);
}

//********************************************************************
//函数功能: 寻找节点中的数据
//函数作者: wgl
//第一参数: [IN] 位置, [out]节点的索引数据
//返回说明: false找不到，true找到为out赋值
//备注说明: 
//********************************************************************  
template<class T>
bool  CQuadNavmesh<T>::FindData(const Vector2f& point, T& nData) const
{
	return _FindData(m_Tree->pRoot, point, nData);
}

template<class T>
bool CQuadNavmesh<T>::_FindData(QuadNode<T>* pNode, const Vector2f& point, T& nData) const
{
	if (NULL == pNode)
	{
		return false;
	}
	for (std::list<uint32>::iterator it = pNode->trigonIndex.begin(); pNode->trigonIndex.end() != it; ++it)
	{
		const T& nIndex = *it;
		if ((*m_pPointIsInTrigon)(m_pFunPoint, point, nIndex))
		{
			nData = nIndex;
			return true;
		}
	}

	for (int i = 0 ; i < C_QUAD_NUM; ++i)
	{
		if (NULL == pNode->pSbu[i])
		{
			continue;
		}

		if (CFormula::IsInRect(point, pNode->pSbu[i]->leftUp, pNode->pSbu[i]->rightDown))
		{
			return _FindData(pNode->pSbu[i], point, nData);
		}

	}

	return false;
}


//********************************************************************
//函数功能: 寻找靠近不可到达点接近最近的点
//函数作者: wgl
//第一参数: [IN] 位置, [out]点
//返回说明: false找不到，true找到为out赋值
//备注说明: 接近最近不是一定最近
//********************************************************************  
template<class T>
bool CQuadNavmesh<T>::GetNearEndPoint(const Vector2f& end, Vector2f& outPoint)
{
	m_bInitCross = false;
	_GetNearEndPoint(m_Tree->pRoot, end);
	if (m_bInitCross)
	{
		outPoint = m_cross;
	}
	
	return m_bInitCross;
}

template<class T>
void CQuadNavmesh<T>::_GetNearEndPoint(QuadNode<T>* pNode, const Vector2f& end)
{
	if (NULL == pNode)
	{
		return;
	}

	float fDis = 0.0f;
	Vector2f nearCross;
	for (std::list<uint32>::iterator it = pNode->trigonIndex.begin(); pNode->trigonIndex.end() != it; ++it)
	{
		const T& nIndex = *it;
		if ((*m_pNearEndPoint)(m_pFunPoint, end, nIndex, fDis, nearCross))
		{
			if (!m_bInitCross)
			{
				m_fDistance = fDis;
				m_cross = nearCross;
				m_bInitCross = true;
			}
			else
			{
				if (fDis < m_fDistance)
				{
					m_fDistance = fDis;
					m_cross = nearCross;
				}
			}
		}
	}

	for (int i = 0 ; i < C_QUAD_NUM; ++i)
	{
		if (NULL == pNode->pSbu[i])
		{
			continue;
		}
		
		_GetNearEndPoint(pNode->pSbu[i], end);
	}
}