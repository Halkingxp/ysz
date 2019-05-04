#include "Formula.h"
#include <math.h>


#define _MAX_(a, b)  ((a) > (b) ? (a) : (b))
#define _MIN_(a, b)  ((a) < (b) ? (a) : (b))

CFormula::CFormula()
{

}

CFormula::~CFormula()
{

}

CFormula& CFormula::GetInstance()
{
	static CFormula obj; 
	return obj;
}
//********************************************************************
//函数功能: 获得三角形的面积
//第一参数: [IN] 3个点
//返回说明: 面积
//备注说明:
//********************************************************************
float CFormula::TrigonArea(const Vector2f& pos1, const Vector2f& pos2, const Vector2f& pos3)
{
	float result = pos1[0] * pos2[1] + pos2[0] * pos3[1] + pos3[0] * pos1[1] - pos2[0] * pos1[1] - pos3[0] * pos2[1] - pos1[0] * pos3[1];

	result /= 2.0f;
	return fabs(result);
}

//********************************************************************
//函数功能: 射线和线段的关系 
//第一参数: [IN] 射线, ab两点, out交点
//返回说明::相交返回true，不相交返回false
//备注说明:
//********************************************************************
bool CFormula::IsIntersectAnt(const Vector2f& ori, const Vector2f& point, const Vector2f& a, const Vector2f& b, Vector2f& corss)
{
	Vector2f out;
	bool bInter = CFormula::Inter(ori, point, a, b, out);
	if (!bInter)
	{
		return false;
	}
	
	int iInter = CFormula::HitType(a, b, out);
	if (0 != iInter)
	{
		corss = out;
		return true;
	}
	return false;
}


//********************************************************************
//函数功能: 射线和线段的关系 ,先判断直线是否相交，
//第一参数: [IN] 射线起点，方向点， ab两点,  out点
//返回说明::相交为true, 获得交点
//备注说明:
//********************************************************************
bool CFormula::Inter(const Vector2f& origin, const Vector2f& point, const Vector2f& a, const Vector2f& b, Vector2f& outPoint)
{ 
	float x0 = origin[0], y0 = origin[1];
	float x1 = point[0], y1 = point[1];
	float x2 = a[0], y2 = a[1];
	float x3 = b[0], y3 = b[1];

	float k1 = 0.0f, b1 = 0.0f, k2 = 0.0f, b2 = 0.0f;/*斜率和Y轴截距 y = kx + b */
	bool lim1 = false, lim2 = false;//是否垂直X轴
	/* 判断2条直线是否垂直x轴 */
	if (!CFormula::FloatEqual(x1, x0))
	//if(x1 != x0)
	{
		k1 = (y1 - y0) / (x1 - x0); /* 斜率 */
		b1 = y0 - k1 * x0;  /* 截距 */
	}
	else 
	{
		lim1 = true; 
	}

	if (!CFormula::FloatEqual(x3, x2))
	//if(x3 != x2)
	{
		k2 = (y3-y2) / (x3-x2);
		b2 = y2 - k2*x2;
	} 
	else 
	{
		lim2 = true; /* true表示垂直X轴 */
	}

	//都不垂直于X轴 
	if(!lim1 && !lim2)
	{
		if (CFormula::FloatEqual(k1, k2))
		//if(k1 == k2) /* 斜率相同 */
		{
			/* 斜率,截矩都相同可能相交，可能交点在线段的某一个端点 */
			/* 射线方向背离线段时，不相交 */
			/* 射线方向朝线段时，离射线源点距离近的线段端点为实际交点 */
			if (CFormula::FloatEqual(b1, b2))
			//if(b1 == b2)
			{
				/* 射线源点坐标为所有坐标中最大或最小*/
				/* 由于斜率相同，x, y同时为最值，判断一个即可 */
				if (x0 > x1 && x0 > x2 && x0 > x3)
				{
					outPoint[0] = (x2 > x3) ? x2 : x3;
					outPoint[1] = k1 * outPoint[0] + b1;
					return true;
				}
				else if(x0 < x1 && x0 < x2 && x0 < x3)
				{
					outPoint[0] = (x2 < x3) ? x2 : x3;
					outPoint[1] = k1 * outPoint[0] + b1;
					return true;
				}
				return false;
			}
			/* b1==b2 平行无交点 */
			return false;
		}/* end of if(k1 == k2) */
		else /* 斜率不同 */
		{
			outPoint[0] = (b2 - b1) / (k1 - k2); 
			outPoint[1] = k1 * outPoint[0] + b1; 

			/* 实际交点在射线正方向上 */
			if(((x0 - x1) > 0 && (x0 - outPoint[0]) > 0) || ((x0 - x1) < 0 && (x0 - outPoint[0]) < 0) || ((y0 - y1) > 0 && (y0 - outPoint[1]) > 0)
				|| ((y0 - y1) < 0 && (y0 - outPoint[1]) < 0))
			{
				return true;
			}
			return false;
		}         
	}/* end of if(!lim1 && !lim2) */

	//2直线全垂直X轴，斜率无穷大
	if(lim1 && lim2) 
	{ 
		/* x0==x1, x2==x3 */
		/* 可能不相交，可能交点在线段的某一个端点 */
		if (CFormula::FloatEqual(x0, x2))
		//if(x0 == x2)
		{
			if (y0 < y1 && y0 < y2 && y0 < y3)
			{
				outPoint[0] = x0;
				outPoint[1] = (y2 < y3) ? y2 : y3;
				return true;
			}
			if (y0 > y1 && y0 > y2 && y0 > y3)
			{
				outPoint[0] = x0;
				outPoint[1] = (y2 > y3) ? y2 : y3;
				return true;
			}           
			return false;
		}
		/* x0 != x2 平行无交点 */
		return false; 
	}/* end of if(lim1 && lim2) */

	/* 射线垂直X轴 */   
	if(lim1 && !lim2)
	{ 
		outPoint[0] = x1; 
		outPoint[1] = k2 * outPoint[0] + b2; 
		/* 实际交点在射线正方向上 */
		if(((x0 - x1) > 0 && (x0 - outPoint[0]) > 0) || ((x0 - x1) < 0 && (x0 - outPoint[0]) < 0) || ((y0 - y1) > 0 && (y0 - outPoint[1]) > 0) || 
			((y0 - y1) < 0 && (y0 - outPoint[1]) < 0))
		{
			return true;
		}
		//return true; 
	}

	/* 线段所在直线垂直x轴 */
	if (!lim1 && lim2)
	{ 
		outPoint[0] = x3; 
		outPoint[1] = k1 * outPoint[0] + b1;
		/* 实际交点在射线正方向上 */
		if(((x0 - x1) > 0 && (x0 - outPoint[0]) > 0) || ((x0 - x1) < 0 && (x0 - outPoint[0]) < 0)
			|| ((y0 - y1) > 0 && (y0 - outPoint[1]) > 0) || ((y0 - y1) < 0 && (y0 - outPoint[1]) < 0))
		{
			return true;
		}
		//return true; 
	} 

	/* 缺省返回假 */
	return false; 
} 

//********************************************************************
//函数功能: 交点的类型
//第一参数: [IN] 射线起点，方向点， ab两点,  out点
//返回说明::/* 0:交点在线段之外，1:交点在线段之内(不含顶点)，2:交点为2顶点之一 */
//备注说明:
//********************************************************************
int CFormula::HitType(const Vector2f& a, const Vector2f& b, const Vector2f& outPoint)
{
	float xmin = (a[0] < b[0]) ? a[0] : b[0];
	float xmax = (a[0] > b[0]) ? a[0] : b[0];
	float ymin = (a[1] < b[1]) ? a[1] : b[1];
	float ymax = (a[1] > b[1]) ? a[1] : b[1];

	/* 线段为斜边 */
	if (!CFormula::FloatEqual(xmin, xmax) && !CFormula::FloatEqual(ymin, ymax))
	//if (xmin != xmax && ymin != ymax)
	{
		/* 线段内(不含顶点) */
		if (outPoint[0] > xmin && outPoint[0] < xmax && outPoint[1] > ymin && outPoint[1] < ymax)
		{
			return 1;
		}
		/* 顶点上 */
		if ((CFormula::FloatEqual(outPoint[0], a[0]) && CFormula::FloatEqual(outPoint[1], a[1])) 
			|| (CFormula::FloatEqual(outPoint[0], b[0]) && CFormula::FloatEqual(outPoint[1], b[1]))  )
		//if((outPoint[0] == a[0] && outPoint[1] == a[1]) || (outPoint[0] == b[0] && outPoint[1] == b[1]))
		{
			return 2;
		}
	}   

	/* 线段平行x轴 */
	if (CFormula::FloatEqual(ymin, ymax))
	//if (ymin == ymax)
	{
		if (outPoint[0] > xmin && outPoint[0] < xmax)
		{
			return 1;
		}

		if (CFormula::FloatEqual(outPoint[0], xmin) || CFormula::FloatEqual(outPoint[0], xmax))
		//if (outPoint[0] == xmin || outPoint[0] == xmax)
		{
			return 2;
		}
	}

	/* 线段平行y轴 */
	if (CFormula::FloatEqual(xmin, xmax))
	//if(xmin == xmax)
	{
		if (outPoint[1] > ymin && outPoint[1] < ymax)
		{
			return 1;
		}

		if (CFormula::FloatEqual(outPoint[1], ymin) || CFormula::FloatEqual(outPoint[1], ymax))
		//if (outPoint[1] == ymin || outPoint[1] == ymax)
		{
			return 2;
		}
	}

	return 0;
}

// 自带的精度太高~, 0.00001都不想等
bool CFormula::FloatEqual(float a, float b)
{
	float x = a - b;
	if (x >= -FLOAT_FAULT_TOLERANT && x <= FLOAT_FAULT_TOLERANT)
	{
		return true;
	}
	return false;
}

/*
设有向线段AB，两端点A（ax, ay）,B(bx,by)
另一点C(cx,cy)
AB   A->B方向的一条射线
if(f > 0)
	点C位于有向线段AB的左侧
else if(f == 0)
	点C位于有向线段AB上（也有可能在延长线上）
else
	点C位于有向线段AB的右侧
*/
uint8 CFormula::GetLineDirection(const Vector2f& A, const Vector2f& B, const Vector2f& C)
{	
	float f = (B[0] - A[0]) * (C[1] - A[1]) - (C[0] - A[0]) * (B[1] - A[1]);
	if (fabs(f) < FLOAT_FAULT_TOLERANT)
	{
		return E_Line_Direction_Online;
	}
	if (f > 0)
	{
		return E_Line_Direction_Left;
	}
	return E_Line_Direction_Right;
}

/*
如果AB*AC>0,则三角形ABC是逆时针的
如果AB*AC<0,则三角形ABC是顺时针的
如果……  =0，则说明三点共线，
*/
float CFormula::GetDeltaSequence(const Vector2f& A, const Vector2f& B, const Vector2f& C)
{
	Vector2f AB(B - A);
	Vector2f AC(C - A);
	float f = AB[0] * AC[1] - AB[1] * AC[0];
	return f;
}

//********************************************************************
//函数功能: 获得两点之间的中点坐标
//第一参数: [IN] 两个点的位置
//返回说明: 中点坐标
//备注说明: 
//********************************************************************
Vector2f CFormula::GetPointMiddle(const Vector2f& a, const Vector2f& b)
{
	Vector2f middle;
	middle[0] = (a[0] + b[0]) / 2;
	middle[1] = (a[1] + b[1]) / 2;
	return middle;
}

//********************************************************************
//函数功能: 获得两点之间的距离
//第一参数: [IN] 两个点的位置
//返回说明: 距离
//备注说明: 
//********************************************************************
float CFormula::GetPointDistance(const Vector2f& a, const Vector2f& b)
{
	float _x1 = a[0] - b[0];
	float _y1 = a[1] - b[1];

	_x1 *= _x1;
	_y1 *= _y1;
	float result = _x1 + _y1;
	result = sqrtf(result);
	return result;
}

//********************************************************************
//函数功能: 判断点是否在线段上
//第一参数: [IN] 判断的点，线段AB两点
//返回说明: true在线段上
//备注说明: 
//********************************************************************
bool CFormula::PointIsOnSegment(const Vector2f& point,  const Vector2f& A, const Vector2f& B)
{
	float pa = CFormula::GetPointDistance(point, A);
	float pb = CFormula::GetPointDistance(point, B);
	float ab = CFormula::GetPointDistance(A, B);

	float result = pa + pb - ab;
	if (fabs(result) < FLOAT_FAULT_TOLERANT)
	{
		return true;
	}
	return false;
}

//********************************************************************
//函数功能: 找出两点线段上的一点
//第一参数: [IN] AB两点，要求的点，到A点的距离，AB的长度
//返回说明: 得到的点
//备注说明: 
//********************************************************************
Vector2f CFormula::GetPointInSegment(const Vector2f& A, const Vector2f& B, float Alen, float ABlen)
{
	float fx = (Alen * (B[0] - A[0]) / ABlen) + A[0];
	float fz = (Alen * (B[1] - A[1]) / ABlen) + A[1];

	return Vector2f(fx, fz);
}

//********************************************************************
//函数功能: 根据两点求出垂线过第三点的直线的交点
//第一参数: [IN] AB两点，直线外一点
//返回说明: 返回点到直线的垂直交点坐标 
//备注说明: 
//********************************************************************
Vector2f CFormula::GetLintVertical(const Vector2f &pt1, const Vector2f &pt2, const Vector2f &point)
{
	// 先判断x平行和Y平行
	if (CFormula::FloatEqual(pt1[0], pt2[0]))
	{
		return Vector2f(pt2[0], point[1]);
	}
	if (CFormula::FloatEqual(pt1[1], pt2[1]))
	{
		return Vector2f(point[0], pt2[1]);
	}

	// ax0 + b = y0;  ax1 + b = y1;  ax0-ax1=y0-y1; a = (y0-y1)/x0-x1
    float A = (pt1[1]-pt2[1])/(pt1[0]- pt2[0]);  
    float B = (pt1[1]-A*pt1[0]);  
    /// > 0 = ax +b -y;  对应垂线方程为 -x -ay + m = 0;(mm为系数)  
    /// > A = a; B = b; 
	// m = x + ay
    float m = point[0] + A*point[1];  
  
	/*
	ax+b-y=0; -ax -a*a*y + am = 0
	0=b-a*a*y-y+am; -b-am=y(-(a*a) - 1);
	y = (-b-am)/-(a*a) - 1; y = b+am / a*a + 1
	*/
    /// 求两直线交点坐标
	/*
	// y=ax+b;-x -ay + m = 0
	-x-a(ax+b) + m = 0;
	x(-1-a*a)-ab+m=0;
	x=(-m+ab)/(-1-a*a);
	x = (m-ab)/(1+a*a)
	*/
    Vector2f ptCross;  
    ptCross[0] = (m - A * B) / (A * A + 1);  
    ptCross[1] = A * ptCross[0] + B;
    return ptCross;  
}


/********************************************************
 *                                                      *
 *  返回(P1-P0)*(P2-P0)的叉积。                         *
 *  若结果为正，则<P0,P1>在<P0,P2>的顺时针方向；        *
 *  若为0则<P0,P1><P0,P2>共线；                         *
 *  若为负则<P0,P1>在<P0,P2>的在逆时针方向;             *
 *  可以根据这个函数确定两条线段在交点处的转向,         *
 *  比如确定p0p1和p1p2在p1处是左转还是右转，只要求      *
 *  (p2-p0)*(p1-p0)，若<0则左转，>0则右转，=0则共线     *
 *                                                      *
\********************************************************/
float CFormula::Multiply(const Vector2f& p1,const Vector2f& p2,const Vector2f& p0)
{
    return((p1[0] - p0[0]) * (p2[1] - p0[1]) - (p2[0] - p0[0]) * (p1[1] - p0[1]));    
}


//********************************************************************
//函数功能: 确定两条线段p, other是否相交
//函数作者: wgl
//第一参数: [IN] 4点
//返回说明:                                              /   /
//备注说明: 
//******************************************************************** 
bool CFormula::LineIntersect(const Vector2f& p1, const Vector2f& p2, const Vector2f& other1, const Vector2f& other2)
{
#define  p1_x  p1[0]
#define  p1_y  p1[1]
#define p2_x  p2[0]
#define p2_y  p2[1]
#define other1_x  other1[0]
#define other1_y  other1[1]
#define other2_x  other2[0]
#define other2_y  other2[1]

    return( (_MAX_(p1_x, p2_x) >= _MIN_(other1_x, other2_x)) &&
            (_MAX_(other1_x, other2_x) >= _MIN_(p1_x, p2_x)) &&
            (_MAX_(p1_y, p2_y) >= _MIN_(other1_y, other2_y)) &&
            (_MAX_(other1_y, other2_y) >= _MIN_(p1_y, p2_y)) &&
            (Multiply(other1, p2, p1) * Multiply(p2, other2, p1) >= 0) &&
            (Multiply(p1, other2, other1) * Multiply(other2, p2, other1) >= 0));

#undef p1_x
#undef p1_y
#undef p2_x
#undef p2_y
#undef other1_x
#undef other1_y
#undef other2_x
#undef other2_y

}


//********************************************************************
//函数功能: 点是否在矩形范围内
//函数作者: wgl
//第一参数: [IN] 点和矩形左上右下
//返回说明:                                              /   /
//备注说明: min,max防止 坐标系问题, 正常的矩形，不是斜的/   /
//******************************************************************** 
bool  CFormula::IsInRect(const Vector2f& point, const Vector2f& leftUp, const Vector2f& rightDown)
{
	float x1 = _MIN_(leftUp[0], rightDown[0]);
	float x2 = _MAX_(leftUp[0], rightDown[0]);

	float y1 = _MIN_(leftUp[1], rightDown[1]);
	float y2 = _MAX_(leftUp[1], rightDown[1]);
	if (point[0] >=  x1 &&  point[0] <=  x2 && point[1] >= y1 &&  point[1] <= y2)
	{
		return true;
	}

	return false;
}

#undef _MIN_
#undef _MAX_

//********************************************************************
//函数功能: 根据左上和右下获得一个矩形
//函数作者: wgl
//第一参数: [IN] 矩形左上右下点
//返回说明:                                              /   /
//备注说明: 矩形分割不支持X向上，向下的坐标系，
//******************************************************************** 
EigenRect CFormula::GetRect(const Vector2f& leftUp, const Vector2f& rightDown)
{
	EigenRect rect;
	rect._a = leftUp;
	rect._d = rightDown;
	rect._b = Vector2f(rightDown[0], leftUp[1]);
	rect._c = Vector2f(leftUp[0], rightDown[1]);
	return rect;
}

//********************************************************************
//函数功能: 矩形切割后的中心点
//函数作者: wgl
//第一参数: [IN] 左上和右下
//返回说明:                                              /   /
//备注说明: 
//********************************************************************  
Vector2f CFormula::GetCutPoint(const Vector2f& leftUp, const Vector2f& rightDown)
{
	Vector2f tmp;
	tmp[0] = leftUp[0] + rightDown[0];
	tmp[1] = leftUp[1] + rightDown[1];

	tmp[0] /= 2;
	tmp[1] /= 2;
	return tmp;
}