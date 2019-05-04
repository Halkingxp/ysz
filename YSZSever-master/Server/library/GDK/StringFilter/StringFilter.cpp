/*****************************************************************************
Copyright (C), 2013-2015, ***. Co., Ltd.
文 件 名:  StringFilter.cpp
作    者:   
版    本:  1.0
完成日期:  2014-2-28
说明信息:  
*****************************************************************************/
#include "StringFilter.h"
#include "Define.h"
#include "Tools/StringTools.h"

CStringFilter::CStringFilter(void)
{
}

CStringFilter::~CStringFilter(void)
{
}

uint8 CStringFilter::_BytesOfUtf8(String str,uint32 index)
{
	if(index > str.size())
		return 0;
	if(!(str[index] & (1 << 7)))
		return 1;
	else if(!(str[index] & (1 << 5)))
		return 2;
	else if(!(str[index] & (1 << 4)))
		return 3;
	else if(!(str[index] & (1 << 3)))
		return 4;
	else
		return 0;
}

//********************************************************************
//函数功能: 添加屏蔽词, 初始化用, 有多少屏蔽词就添加多少次
//第一参数: [IN] 屏蔽词
//返回说明: 
//备注说明: 对于首字相同的关键字，如：打人、打架、打劫，将会被装在一个vector中
//备注说明: 屏蔽词由数据库决定唯一性
//********************************************************************
int CStringFilter::AddFilterWords(const String &str)
{
	String strWord = str;
	String strKey;			// 首字
	uint8 bytes = 1;
	
	bytes = _BytesOfUtf8(strWord, 0);
	if (bytes == 1)
	{
		strWord = CStringTools::StringToLower(strWord);
	}
	if (strWord.empty())
	{
		return 0;
	}
	strKey = strWord.substr(0, bytes);

	//首字相同的一组屏蔽字装入完毕
	FilterMap::iterator it = m_cFilterMap.find(strKey);
	if (m_cFilterMap.end() == it)
	{
		WordVector filterWords;
		filterWords.push_back(strWord);
		m_cFilterMap.insert(FilterMap::value_type(strKey, filterWords));
	}
	else
	{
		it->second.push_back(strWord);
	}
	return 0;
}

//********************************************************************
//函数功能: 将屏蔽字替换成*
//第一参数: 输入and输出
//返回说明: 无特殊含义
//备注说明: 
//********************************************************************
int CStringFilter::Filter(String &str)
{				
	/*
	* 
	* 对于一句话，遍历其每个字符，以此字符为键到屏蔽字map里查
	* 询，看是否存在以此字符为首字的屏蔽字组，如果存在再与这组
	* 屏蔽字逐个比较，如果匹配，则用替换字符串替换该词，然后从
	* 下一个未被检查的字符开始继续检查
	*
	*/
	if((int)str.size() <= 0)
	{
		return 0;
	}

	uint8 bytes = 1;
	int	index = 0;	
	String tmpWstr;
	String tmpHeadWord;
	String replaceWStr;
	tmpWstr.clear();
	tmpHeadWord.clear();
	FilterMap::iterator	iter;
	while(index < (int)str.size())														
	{
		bytes = _BytesOfUtf8(str,index);
		if (0 == bytes)
		{
			sprintf(g_szInfo, "字符串不是utf-8的");
			REPORT(g_szInfo);
			str.replace(str.begin(), str.end(), str.size(), '*');
			return 0;
		}
		tmpHeadWord = str.substr(index,bytes);
		if(bytes == 1)
			tmpHeadWord = CStringTools::StringToLower(tmpHeadWord);
		if(tmpWstr != tmpHeadWord)
		{
			iter = m_cFilterMap.find(tmpHeadWord);
			tmpWstr = tmpHeadWord;
		}
		if(iter != m_cFilterMap.end())//找到一组屏蔽字
		{
			uint32 i = 0;
			for(;i != iter->second.size();++i)//与组内屏蔽字逐个比较
			{
				if(iter->second[i].empty())
					continue;
				String cmpStr = str.substr(index,iter->second[i].size());
				if(bytes == 1)
					cmpStr = CStringTools::StringToLower(cmpStr);
                if(cmpStr == iter->second[i])//找到屏蔽字，替换
                {
                    replaceWStr = "";
                    int _offByUtf8 = 0;
                    for (int k = 0; k < (int32)cmpStr.size(); ++k)
                    {
                        replaceWStr += "*";
                        int byOfUtf8 = (int)_BytesOfUtf8(cmpStr, _offByUtf8);
                        _offByUtf8 += byOfUtf8;
                        if (_offByUtf8 >= (int32)cmpStr.size())
                        {
                            break;
                        }

                    }                
                    str.replace(index,iter->second[i].size(),replaceWStr);						
                    break;
                }
			}
			//重新定位扫描位置
			if(i != iter->second.size())		
			{
				index += replaceWStr.size();
			}
			else
			{
				index += bytes;
			}
			
		}
		else
		{
			index += bytes;
		}
	}

	return 0;
}

//********************************************************************
//函数功能: 是否包含屏蔽字
//第一参数: 字符串
//返回说明: true有违禁字符串
//备注说明: 
//********************************************************************
bool CStringFilter::HasForbiddenWord(const String &str)
{							
	if((int)str.size() <= 0)
	{
		return false;
	}

	int index = 0;
	while(index < (int)str.size())														
	{
		uint8 bytes = _BytesOfUtf8(str,index);
		if (0 == bytes)
		{
			sprintf(g_szInfo, "has违禁字 字符串不是utf-8的");
			REPORT(g_szInfo);
			return true;
		}
		String strHeadWord = str.substr(index,bytes);
		if(bytes == 1)
			strHeadWord = CStringTools::StringToLower(strHeadWord);
		FilterMap::iterator	iter = m_cFilterMap.find(strHeadWord);
		if(iter != m_cFilterMap.end())//在map中找到一组屏蔽字
		{
			uint32 i = 0;
			for(;i != iter->second.size(); ++i)//与组内屏蔽字逐个比较
			{
				if(iter->second[i].empty())
					continue;
				String cmpStr = str.substr(index,iter->second[i].size());
				if(bytes == 1)
					cmpStr = CStringTools::StringToLower(cmpStr);
				if(cmpStr == iter->second[i])//找到屏蔽字
				{
					return true;
				}
			}
		}
		index += bytes;
	}
	return false;
}

CStringFilter& CStringFilter::GetInstance(void)
{
	static CStringFilter object;
	return object;
}