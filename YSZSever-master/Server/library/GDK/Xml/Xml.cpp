/*****************************************************************************
Copyright (C), 2012-2013, ^^^^^^^^. Co., Ltd.
文 件 名:  Xml.cpp
作    者:    
版    本:  1.0
完成日期:  2012-8-9
说明信息:  Xml读写工具, 使用第三方引擎RapidXml
*****************************************************************************/
#include "Xml.h"
#include "rapidxml.hpp"
#include "rapidxml_utils.hpp"
#include "rapidxml_print.hpp"
#include <string.h>

//********************************************************************
//函数功能: 构造函数
//第一参数: [IN] xml相对路径+文件名
//返回说明: 
//备注说明: 文件名不能为空指针, 必须以'/0'为结束符
//********************************************************************
CXml::CXml(void)
{
	m_pFileDoc = NULL;
	m_pCurrApp = NULL;
}

CXml::~CXml(void)
{
	if (m_pFileDoc != NULL)
	{
		delete m_pFileDoc;
		m_pFileDoc = NULL;
	}

	m_cStringCache.clear();
}

bool CXml::SetContent(const char *szXmlData)
{
	if (szXmlData == NULL)
	{
		return false;
	}

	try
	{
		m_cDocument.parse<0>((char*)szXmlData);
		return true;
	}
	catch (...)
	{
		return false;
	}
}

//********************************************************************
//函数功能: 打开Xml文件
//第一参数: 
//返回说明: xml相对路径+文件名
//备注说明: 文件名不能为空指针, 必须以'/0'为结束符
//********************************************************************
bool CXml::OpenXmlFile(const char *szPathName)
{
	// 记录文件名
	if (szPathName == NULL)
	{
		return false;
	}
	m_strPathName = szPathName;
	m_cStringCache.clear();

	// 重新加载
	if (m_pFileDoc != NULL)
	{
		m_cDocument.clear();

		delete m_pFileDoc;
		m_pFileDoc = NULL;
	}

	try
	{
		// 文件不存在, 或者new失败, 都会捕捉到异常
		m_pFileDoc = new rapidxml::file<>(m_strPathName.c_str());
		m_cDocument.parse<0>(m_pFileDoc->data());
		return true;
	}
	catch (...)
	{
		// 写入ROOT
		rapidxml::xml_node<>* pRoot = m_cDocument.allocate_node(rapidxml::node_element, "ROOT", " "); 
		if (pRoot == NULL)
		{
			return false;
		}
		m_cDocument.append_node(pRoot);
		return true;
	}
}

std::string CXml::ToString(void)
{
	return m_cDocument.value();
}

//********************************************************************
//函数功能: 写入文件
//第一参数: [IN] 文件路径+文件名
//返回说明: true  写入成功
//返回说明: false 写入失败
//备注说明: 
//********************************************************************
bool CXml::SaveXmlFile(void)
{
	try
	{
		std::ofstream out(m_strPathName.c_str());  
		out << m_cDocument;
		out.close();
		return true;
	}
	catch(...)
	{
		return false;
	}
}
//********************************************************************
//函数功能: 获得指定App下对应Key的字符串
//第一参数: [IN] App关键字
//第二参数: [IN] Key关键字
//第三参数: [IN] 读取失败默认返回值
//返回说明: 读取成功, 返回读取的字符串
//返回说明: 读取失败, 返回默认的字符串
//备注说明: 
//********************************************************************
std::string CXml::ReadString(const char *szApp, const char *szKey, std::string strDefault /*= ""*/)
{
	if (szApp == NULL || szKey == NULL)
	{
		return strDefault;
	}
	rapidxml::xml_node<> *pRoot = m_cDocument.first_node();
	if (pRoot == NULL)	{ return strDefault; }

	rapidxml::xml_node<> *pApp = pRoot->first_node(szApp);
	if (pApp == NULL)	{ return strDefault; }

	rapidxml::xml_node<> *pKey = pApp->first_node(szKey);
	if (pKey == NULL)	{ return strDefault; }

	return pKey->value();
}

//********************************************************************
//函数功能: 获得指定App下对应Key的int值
//第一参数: [IN] App关键字
//第二参数: [IN] Key关键字
//第三参数: [IN] 读取失败默认返回值
//返回说明: 读取成功, 返回读取的int
//返回说明: 读取失败, 返回默认的int
//备注说明: 
//********************************************************************
int CXml::ReadInt(const char *szApp, const char *szKey, int iDefault /*= 0*/)
{
	if (szApp == NULL || szKey == NULL)
	{
		return iDefault;
	}
	rapidxml::xml_node<> *pRoot = m_cDocument.first_node();
	if (pRoot == NULL)	 { return iDefault; }

	rapidxml::xml_node<> *pApp = pRoot->first_node(szApp);
	if (pApp == NULL)	 { return iDefault; }

	rapidxml::xml_node<> *pKey = pApp->first_node(szKey);
	if (pKey == NULL)	 { return iDefault; }

	const char *szValue = pKey->value();
	if (szValue == NULL) { return iDefault; }

	int iValue = atoi(szValue);
	return iValue;
}

//********************************************************************
//函数功能: 获得指定App下对应Key的bool值
//第一参数: [IN] App关键字
//第二参数: [IN] Key关键字
//第三参数: [IN] 读取失败默认返回值
//返回说明: 读取成功, 返回读取的bool
//返回说明: 读取失败, 返回默认的bool
//备注说明: xml里面可以填写 true, false, TRUE, FALSE, 0, 1
//********************************************************************
bool CXml::ReadBool(const char *szApp, const char *szKey, bool isDefault /*= false*/)
{
	if (szApp == NULL || szKey == NULL)
	{
		return isDefault;
	}
	rapidxml::xml_node<> *pRoot = m_cDocument.first_node();
	if (pRoot == NULL)	 { return isDefault; }

	rapidxml::xml_node<> *pApp = pRoot->first_node(szApp);
	if (pApp == NULL)	 { return isDefault; }

	rapidxml::xml_node<> *pKey = pApp->first_node(szKey);
	if (pKey == NULL)	 { return isDefault; }

	const char *szValue = pKey->value();
	if (szValue == NULL) { return isDefault; }

	if (strcmp(szValue, "true") == 0 || strcmp(szValue, "yes") == 0  || 
		strcmp(szValue, "TRUE") == 0 ||	strcmp(szValue, "YES") == 0  || 
		strcmp(szValue, "1") == 0)
	{
		return true;
	}
	else
	{
		return false;
	}
}

//********************************************************************
//函数功能: 获得指定App下对应Key的float值
//第一参数: [IN] App关键字
//第二参数: [IN] Key关键字
//第三参数: [IN] 读取失败默认返回值
//返回说明: 读取成功, 返回读取的float
//返回说明: 读取失败, 返回默认的float
//备注说明: 
//********************************************************************
float CXml::ReadFloat(const char *szApp, const char *szKey, float fDefault /*= 0.0f*/)
{
	if (szApp == NULL || szKey == NULL)
	{
		return fDefault;
	}
	rapidxml::xml_node<> *pRoot = m_cDocument.first_node();
	if (pRoot == NULL)	 { return fDefault; }

	rapidxml::xml_node<> *pApp = pRoot->first_node(szApp);
	if (pApp == NULL)	 { return fDefault; }

	rapidxml::xml_node<> *pKey = pApp->first_node(szKey);
	if (pKey == NULL)	 { return fDefault; }

	const char *szValue = pKey->value();
	if (szValue == NULL) { return fDefault; }

	float fValue = (float)atof(szValue);
	return fValue;
}


//********************************************************************
//函数功能: 在App指定的Key下写入字符串
//第一参数: [IN] App关键字
//第二参数: [IN] Key关键字
//第三参数: [IN] 写入值
//返回说明: 写入成功, 返回true
//返回说明: 写入失败, 返回false
//备注说明: 
//********************************************************************
bool CXml::WriteString(const char *szApp, const char *szKey, char *szValue)
{
	if (szApp == NULL || szKey == NULL || szValue == NULL)
	{
		return false;
	}

	// 因为解析器中保存的字符串值都只是指针而已，所以这里需要把外部传来的 app\key\value 都缓存一下
	std::set<std::string>::iterator iterApp = m_cStringCache.find(szApp);
	if (iterApp == m_cStringCache.end())
	{
		m_cStringCache.insert(szApp);
		iterApp = m_cStringCache.find(szApp);
		if (iterApp == m_cStringCache.end())
		{
			return false;
		}
	}
	std::set<std::string>::iterator iterKey = m_cStringCache.find(szKey);
	if (iterKey == m_cStringCache.end())
	{
		m_cStringCache.insert(szKey);
		iterKey = m_cStringCache.find(szKey);
		if (iterKey == m_cStringCache.end())
		{
			return false;
		}
	}
	std::set<std::string>::iterator iterValue = m_cStringCache.find(szValue);
	if (iterValue == m_cStringCache.end())
	{
		m_cStringCache.insert(szValue);
		iterValue = m_cStringCache.find(szValue);
		if (iterValue == m_cStringCache.end())
		{
			return false;
		}
	}

	rapidxml::xml_node<>* pRoot = m_cDocument.first_node();
	if (pRoot == NULL)	
	{ 
		return false; 
	}

	rapidxml::xml_node<>* pApp = pRoot->first_node(iterApp->c_str());
	if (pApp == NULL)
	{
		pApp = m_cDocument.allocate_node(rapidxml::node_element, iterApp->c_str(), " "); 
		if (pApp == NULL)
		{
			return false;
		}
		pRoot->append_node(pApp);
	}

	rapidxml::xml_node<>* pKey = pApp->first_node(iterKey->c_str());
	if (pKey != NULL)
	{
		pApp->remove_node(pKey);
		pKey = NULL;
	}

	pKey = m_cDocument.allocate_node(rapidxml::node_element, iterKey->c_str(), iterValue->c_str()); 
	if (pKey == NULL)
	{
		return false;
	}
	pApp->append_node(pKey);
	return true;
}
//********************************************************************
//函数功能: 在App指定的Key下写入整型
//第一参数: [IN] App关键字
//第二参数: [IN] Key关键字
//第三参数: [IN] 写入值
//返回说明: 写入成功, 返回true
//返回说明: 写入失败, 返回false
//备注说明: 
//********************************************************************
bool CXml::WriteInt(const char *szApp, const char *szKey, int iValue)
{
	static char szValue[32] = {};
	sprintf(szValue, "%d", iValue);

	return WriteString(szApp, szKey, szValue);
}
//********************************************************************
//函数功能: 在App指定的Key下写入布尔型
//第一参数: [IN] App关键字
//第二参数: [IN] Key关键字
//第三参数: [IN] 写入值
//返回说明: 写入成功, 返回true
//返回说明: 写入失败, 返回false
//备注说明: 
//********************************************************************
bool CXml::WriteBool(const char *szApp, const char *szKey, bool isValue)
{
	char szValue[32] = "false";
	if (isValue)
	{
		sprintf(szValue, "%s", "true");
	}
	return WriteString(szApp, szKey, szValue);
}
//********************************************************************
//函数功能: 在App指定的Key下写入浮点型
//第一参数: [IN] App关键字
//第二参数: [IN] Key关键字
//第三参数: [IN] 写入值
//返回说明: 写入成功, 返回true
//返回说明: 写入失败, 返回false
//备注说明: 
//********************************************************************
bool CXml::WriteFloat(const char *szApp, const char *szKey, float fValue)
{
	static char szValue[32] = {};
	sprintf(szValue, "%.2f", fValue);

	return WriteString(szApp, szKey, szValue);
}



//********************************************************************
//函数功能: 迭代初始化
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CXml::Iterator(void)
{
	rapidxml::xml_node<> *pRoot = m_cDocument.first_node();
	m_pCurrApp = NULL;
	if (pRoot != NULL)
	{
		m_pCurrApp = pRoot->first_node();
	}
}

//********************************************************************
//函数功能: 是否迭代完毕
//第一参数: 
//返回说明: 完毕,   返回true
//返回说明: 未完毕, 返回false
//备注说明: 
//********************************************************************
bool CXml::IsDone(void)
{
	return (m_pCurrApp == NULL);
}

//********************************************************************
//函数功能: 移动到下一App节点
//第一参数: 
//返回说明: 
//备注说明: 读取完当前App数据后, 再调用此函数
//********************************************************************
void CXml::Next(void)
{
	if (m_pCurrApp != NULL)
	{
		m_pCurrApp = m_pCurrApp->next_sibling();
	}
}

rapidxml::xml_node<>* CXml::Next(rapidxml::xml_node<> *pApp)
{
    if (pApp != NULL)
    {
        return pApp->next_sibling();
    }
    return NULL;
}

//********************************************************************
//函数功能: 获得指定App下对应Key的字符串
//第一参数: [IN] Key关键字
//第二参数: [IN] 读取失败默认返回值
//返回说明: 读取成功, 返回读取的字符串
//返回说明: 读取失败, 返回默认的字符串
//备注说明: 
//********************************************************************
std::string CXml::ReadString(const char *szKey, std::string strDefault /*= ""*/)
{
	if (szKey == NULL || m_pCurrApp == NULL)
	{
		return strDefault;
	}

	rapidxml::xml_node<> *pKey = m_pCurrApp->first_node(szKey);
	if (pKey == NULL)	{ return strDefault; }

	return pKey->value();
}

std::string CXml::ReadString(rapidxml::xml_node<>* p,const char *szKey, std::string strDefault /*= ""*/)
{
    if (szKey == NULL || p == NULL)
    {
        return strDefault;
    }

    rapidxml::xml_node<> *pKey = p->first_node(szKey);
    if (pKey == NULL)	{ return strDefault; }

    return pKey->value();
}

//********************************************************************
//函数功能: 获得指定App下对应Key的int值
//第一参数: [IN] Key关键字
//第二参数: [IN] 读取失败默认返回值
//返回说明: 读取成功, 返回读取的int
//返回说明: 读取失败, 返回默认的int
//备注说明: 
//********************************************************************
int CXml::ReadInt(const char *szKey, int iDefault /*= 0*/)
{
	if (szKey == NULL || m_pCurrApp == NULL)
	{
		return iDefault;
	}

	rapidxml::xml_node<> *pKey = m_pCurrApp->first_node(szKey);
	if (pKey == NULL)	 { return iDefault; }

	const char *szValue = pKey->value();
	if (szValue == NULL) { return iDefault; }

	int iValue = atoi(szValue);
	return iValue;
}

int CXml::ReadInt(rapidxml::xml_node<>* p, const char *szKey, int iDefault /*= 0*/)
{
    if (szKey == NULL || p == NULL)
    {
        return iDefault;
    }

    rapidxml::xml_node<> *pKey = p->first_node(szKey);
    if (pKey == NULL)	 { return iDefault; }

    const char *szValue = pKey->value();
    if (szValue == NULL) { return iDefault; }

    int iValue = atoi(szValue);
    return iValue;
}

//********************************************************************
//函数功能: 获得指定App下对应Key的bool值
//第一参数: [IN] Key关键字
//第二参数: [IN] 读取失败默认返回值
//返回说明: 读取成功, 返回读取的bool
//返回说明: 读取失败, 返回默认的bool
//备注说明: xml里面可以填写 true, false, TRUE, FALSE, 0, 1
//********************************************************************
bool CXml::ReadBool(const char *szKey, bool isDefault /*= false*/)
{
	if (szKey == NULL || m_pCurrApp == NULL)
	{
		return isDefault;
	}
	rapidxml::xml_node<> *pKey = m_pCurrApp->first_node(szKey);
	if (pKey == NULL)	 { return isDefault; }

	const char *szValue = pKey->value();
	if (szValue == NULL) { return isDefault; }

	if (strcmp(szValue, "true") == 0 || strcmp(szValue, "yes") == 0  || 
		strcmp(szValue, "TRUE") == 0 ||	strcmp(szValue, "YES") == 0  || 
		strcmp(szValue, "1") == 0)
	{
		return true;
	}
	else
	{
		return false;
	}
}

//********************************************************************
//函数功能: 获得指定App下对应Key的float值
//第一参数: [IN] Key关键字
//第二参数: [IN] 读取失败默认返回值
//返回说明: 读取成功, 返回读取的float
//返回说明: 读取失败, 返回默认的float
//备注说明: 
//********************************************************************
float CXml::ReadFloat(const char *szKey, float fDefault /*= 0.0f*/)
{
	if (szKey == NULL || m_pCurrApp == NULL)
	{
		return fDefault;
	}
	rapidxml::xml_node<> *pKey = m_pCurrApp->first_node(szKey);
	if (pKey == NULL)	 { return fDefault; }

	const char *szValue = pKey->value();
	if (szValue == NULL) { return fDefault; }

	float fValue = (float)atof(szValue);
	return fValue;
}

rapidxml::xml_node<>* CXml::ReadNode(const char *szKey, rapidxml::xml_node<>* pDefault)
{
    if (szKey == NULL)
    {
        return pDefault;
    }
    rapidxml::xml_node<> *pRoot = m_cDocument.first_node();
    if (pRoot == NULL)	{ return pDefault; }

    rapidxml::xml_node<> *pKey = pRoot->first_node(szKey);
    if (pKey == NULL)	 { return pDefault; }

    return pKey;
}

rapidxml::xml_node<>* CXml::Iterator(rapidxml::xml_node<> *&pApp)
{
    if (pApp == NULL)
    {
        return NULL;
    }
    rapidxml::xml_node<>* ret = pApp->first_node();
    return ret;
}
