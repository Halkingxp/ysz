/*****************************************************************************
Copyright (C), 2012-2100, ^^^^^^^^. Co., Ltd.
文 件 名:  StringFilter.h
作    者:  
版    本:  1.0
完成日期:  2013-6
说明信息:  字符串过滤, 
           13.6.28修复非UTF-8的处理不当问题
*****************************************************************************/
#pragma once
#include <map>
#include "Define.h"
#include <vector>

class CStringFilter
{
	typedef std::vector<String>				WordVector; // 屏蔽词
	typedef std::map<String, WordVector>	FilterMap;	// 屏蔽字表

public:
	static CStringFilter& GetInstance(void);

	int  AddFilterWords(const String &str);			// 添加屏蔽字, 初始化用
	int  Filter(String &str);						// 将屏蔽字替换成*
	bool HasForbiddenWord(const String &str);		// 是否包含屏蔽字

private:
	CStringFilter(void);
	~CStringFilter(void);
	uint8 _BytesOfUtf8(String str,uint32 index);										// 不知道啥功能

private:
	FilterMap m_cFilterMap;			
};

#define sStringFilter CStringFilter::GetInstance()