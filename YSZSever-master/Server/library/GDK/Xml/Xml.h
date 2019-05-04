/*****************************************************************************
Copyright (C), 2012. ^^^^^^^^. Co., Ltd.
文 件 名:  Xml.h
作    者:    
版    本:  1.0
完成日期:  2012-8-9
说明信息:  Xml读写工具, 使用第三方引擎RapidXml

使用说明:
* 1. 标准格式的xml文件, 采用遍历方式读取数据
*    例如: 数据库导出的xml文件
*
* 2. 自定义格式的xml文件, 可通过App+Key直接读取数据
*****************************************************************************/
#pragma once

#include "rapidxml.hpp"
#include "rapidxml_utils.hpp"
#include "rapidxml_print.hpp"
#include <set>

class CXml
{
public:
	CXml(void);
	~CXml(void);

public:
	bool		SetContent(const char *szXmlData);
	bool		OpenXmlFile(const char *szPathName);
	bool		SaveXmlFile(void);
	std::string	ToString(void);
	std::string GetXmlPathName(void) { return m_strPathName; }	// 获得Xml的路径+文件名

public:
	// 读xml
	std::string ReadString(const char *szApp, const char *szKey, std::string strDefault = "");
	int			ReadInt(const char *szApp, const char *szKey, int iDefault = 0);
	bool		ReadBool(const char *szApp, const char *szKey, bool isDefault = false);
	float		ReadFloat(const char *szApp, const char *szKey, float fDefault = 0.0f);

	// 写xml
	bool		WriteString(const char *szApp, const char *szKey, char *szValue);
	bool		WriteInt(const char *szApp, const char *szKey, int iValue);
	bool		WriteBool(const char *szApp, const char *szKey, bool isValue);
	bool		WriteFloat(const char *szApp, const char *szKey, float fValue);

public:
	// 遍历读取xml
	void		Iterator(void);
	bool		IsDone(void);
	void		Next(void);
	std::string ReadString(const char *szKey, std::string strDefault = "");
	int			ReadInt(const char *szKey, int iDefault = 0);
	bool		ReadBool(const char *szKey, bool isDefault = false);
	float		ReadFloat(const char *szKey, float fDefault = 0.0f);

    rapidxml::xml_node<>* ReadNode(const char *szKey, rapidxml::xml_node<>* pDefault = NULL);
    rapidxml::xml_node<>* Iterator(rapidxml::xml_node<> *&pApp);
    rapidxml::xml_node<>* Next(rapidxml::xml_node<> *pApp);

    std::string ReadString(rapidxml::xml_node<>* p,const char *szKey, std::string strDefault = "");
    int			ReadInt(rapidxml::xml_node<>* p, const char *szKey, int iDefault = 0);

private:
	std::string					m_strPathName;	// 文件名
	std::set<std::string>		m_cStringCache;	// 字符串缓存
	rapidxml::xml_document<>	m_cDocument;	// 文档对象
	rapidxml::file<>		   *m_pFileDoc;		// 文件对象
	rapidxml::xml_node<>	   *m_pCurrApp;		// 迭代app节点
};

