/*****************************************************************************
Copyright (C), 2012-2013, 
文 件 名:  JsonParser.cpp
作    者:    
版    本:  1.0
完成日期:  2013-3-5
说明信息:  Json读写工具, 使用第三方引擎RapidJson, 仅支持标准JSON格式
*****************************************************************************/
#include "Json.h"
#include "Define.h"

//********************************************************************
//函数功能: 构造函数
//********************************************************************
CJson::CJson(void)
{
	SetContent("{}");
}

CJson::CJson(const char *szJsonData)
{
    if (szJsonData != NULL) 
    {
        m_cStringCache.clear();
        m_Doc.Parse<0>(szJsonData);
        if (m_Doc.HasParseError()) 
        {
            const char* szError = m_Doc.GetParseError();

            char szInfo[512] = {};
            sprintf(szInfo, "JsonParser Error: %s", szError);
            REPORT(szInfo);
        }
    }
}

CJson::~CJson(void)
{
	m_cStringCache.clear();
}

//********************************************************************
//函数功能: 设置需要解析的Json数据
//第一参数: [IN] Json字符数组
//返回说明: true,  设置成功
//返回说明: false, 设置失败. 不允许读写数据.
//备注说明: 
//********************************************************************
bool CJson::SetContent(const char *szJsonData)
{
	if (szJsonData != NULL) 
	{
		m_cStringCache.clear();
		m_Doc.Parse<0>(szJsonData);
		if (m_Doc.HasParseError()) 
		{
			const char* szError = m_Doc.GetParseError();

			char szInfo[512] = {};
			sprintf(szInfo, "JsonParser Error: %s", szError);
			REPORT(szInfo);
			return false;
		}
		return true;
	}
	return false;
}

//********************************************************************
//函数功能: 获得Json数据
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
std::string CJson::GetContent(void)
{
	Writer<StringBuffer> writer(m_StrBuf, &m_Doc.GetAllocator());
	m_Doc.Accept(writer);
	return m_StrBuf.GetString();
}
//********************************************************************
//函数功能: 获得指定Key下对应的Cjon
//第一参数: [IN] Key关键字
//第二参数: [IN] 读取失败默认返回值
//返回说明: 读取成功, 返回读取的字符串
//返回说明: 读取失败, 返回默认的字符串
//备注说明: 
//********************************************************************
std::string CJson::ReadString(const char *szKey, char *szValue /*= ""*/)
{
    if (szKey == NULL)
    {
        return szValue;
    }
    bool b = m_Doc.HasMember(szKey);
     b = m_Doc[szKey].IsString();
     b = m_Doc[szKey].IsObject();
    if (m_Doc.HasMember(szKey) && m_Doc[szKey].IsString())
    {
        return m_Doc[szKey].GetString();
    }
    return szValue;
}

const jsonobj& CJson::ReadObject(const char *szKey)
{
    if (m_Doc.HasMember(szKey) && m_Doc[szKey].IsObject())
    {
        return m_Doc[szKey];
    }
    static jsonobj obj;
    return obj;
}

//********************************************************************
//函数功能: 读取数组字段
//第一参数: 
//返回说明: 
//备注说明: obj.Size()数组长度   
//          obj[0]数组下标从0开始访问 
//          obj[1].GetInt() 或 GetString()访问下标数据
//********************************************************************
const Value& CJson::ReadArray(const char *szKey, uint32 nIndex, const char *szArrayKey)
{
    if (m_Doc.HasMember(szKey) && m_Doc[szKey].IsArray())
    {
        const Value& cArray = m_Doc[szKey];
        if (nIndex < cArray.Size())
        {
            if (cArray[nIndex].HasMember(szArrayKey))
            {
                return cArray[nIndex][szArrayKey];
            }
        }
    }
    static Value obj;
    return obj;
}

//********************************************************************
//函数功能: 获得指定Key下对应的int值
//第一参数: [IN] Key关键字
//第二参数: [IN] 读取失败默认返回值
//返回说明: 读取成功, 返回读取的int
//返回说明: 读取失败, 返回默认的int
//备注说明: 
//********************************************************************
int CJson::ReadInt(const char *szKey, int32 iDefault /*= 0*/)
{
	if (szKey == NULL)
	{
		return iDefault;
	}
	if (m_Doc.HasMember(szKey) && m_Doc[szKey].IsInt())
	{
		return m_Doc[szKey].GetInt();
	}
	return iDefault;
}

unsigned int CJson::ReadUInt32(const char *szKey, int32 iDefault)
{
	if (szKey == NULL)
	{
		return iDefault;
	}
	if (m_Doc.HasMember(szKey) && m_Doc[szKey].IsUint())
	{
		return m_Doc[szKey].GetUint();
	}
	return iDefault;
}


uint64 CJson::ReadUInt64(const char *szKey, int64 iDefault /*= 0*/)
{
    if (szKey == NULL)
    {
        return iDefault;
    }
    if (m_Doc.HasMember(szKey) && m_Doc[szKey].IsUint64())
    {
        return m_Doc[szKey].IsUint64();
    }
    return iDefault;
}

//********************************************************************
//函数功能: 获得指定Key下对应的bool值
//第一参数: [IN] Key关键字
//第二参数: [IN] 读取失败默认返回值
//返回说明: 读取成功, 返回读取的bool
//返回说明: 读取失败, 返回默认的bool
//********************************************************************
bool CJson::ReadBool(const char *szKey, bool isDefault /*= false*/)
{
	if (szKey == NULL)
	{
		return isDefault;
	}

	if (m_Doc.HasMember(szKey) && m_Doc[szKey].IsBool())
	{
		return m_Doc[szKey].GetBool();
	}
	return isDefault;
}

//********************************************************************
//函数功能: 获得指定Key下对应的float值
//第一参数: [IN] Key关键字
//第二参数: [IN] 读取失败默认返回值
//返回说明: 读取成功, 返回读取的float
//返回说明: 读取失败, 返回默认的float
//备注说明: 
//********************************************************************
float CJson::ReadFloat(const char *szKey, float fDefault /*= 0.0f*/)
{
	if (szKey == NULL)
	{
		return fDefault;
	}

	if (m_Doc.HasMember(szKey) && m_Doc[szKey].IsDouble())
	{
		return (float)m_Doc[szKey].GetDouble();
	}
	return fDefault;
}

//********************************************************************
//函数功能: 写入指定Key和对应的值
//第一参数: [IN] 指定的Key
//第一参数: [IN] 对应的值
//返回说明: 
//备注说明: 
//********************************************************************
void CJson::WriteString(const char *szKey, const char *szValue)
{
	if (szKey == NULL || szValue == NULL)
	{
		return;
	}

	std::set<std::string>::iterator iterKey = m_cStringCache.find(szKey);
	if (iterKey == m_cStringCache.end())
	{
		m_cStringCache.insert(szKey);
		iterKey = m_cStringCache.find(szKey);
		if (iterKey == m_cStringCache.end())
		{
			return;
		}
	}
	std::set<std::string>::iterator iterValue = m_cStringCache.find(szValue);
	if (iterValue == m_cStringCache.end())
	{
		m_cStringCache.insert(szValue);
		iterValue = m_cStringCache.find(szValue);
		if (iterValue == m_cStringCache.end())
		{
			return;
		}
	}

	m_Doc.AddMember(iterKey->c_str(), iterValue->c_str(), m_Doc.GetAllocator());
}
//********************************************************************
//函数功能: 写入指定Key和对应的值
//第一参数: [IN] 指定的Key
//第一参数: [IN] 对应的值
//返回说明: 
//备注说明: 
//********************************************************************
void CJson::WriteInt(const char *szKey, int32 iValue)
{
	if (szKey == NULL)
	{
		return;
	}

	std::set<std::string>::iterator iterKey = m_cStringCache.find(szKey);
	if (iterKey == m_cStringCache.end())
	{
		m_cStringCache.insert(szKey);
		iterKey = m_cStringCache.find(szKey);
		if (iterKey == m_cStringCache.end())
		{
			return;
		}
	}

	m_Doc.AddMember(iterKey->c_str(), iValue, m_Doc.GetAllocator());
}

void CJson::WriteUInt(const char *szKey, uint32 nValue)
{
	if (szKey == NULL)
	{
		return;
	}

	std::set<std::string>::iterator iterKey = m_cStringCache.find(szKey);
	if (iterKey == m_cStringCache.end())
	{
		m_cStringCache.insert(szKey);
		iterKey = m_cStringCache.find(szKey);
		if (iterKey == m_cStringCache.end())
		{
			return;
		}
	}

	m_Doc.AddMember(iterKey->c_str(), nValue, m_Doc.GetAllocator());
}

//********************************************************************
//函数功能: 写入指定Key和对应的值
//第一参数: [IN] 指定的Key
//第一参数: [IN] 对应的值
//返回说明: 
//备注说明: 
//********************************************************************
void CJson::WriteBool(const char *szKey, bool isValue)
{
	if (szKey == NULL)
	{
		return;
	}

	std::set<std::string>::iterator iterKey = m_cStringCache.find(szKey);
	if (iterKey == m_cStringCache.end())
	{
		m_cStringCache.insert(szKey);
		iterKey = m_cStringCache.find(szKey);
		if (iterKey == m_cStringCache.end())
		{
			return;
		}
	}

	m_Doc.AddMember(iterKey->c_str(), isValue, m_Doc.GetAllocator());
}
//********************************************************************
//函数功能: 写入指定Key和对应的值
//第一参数: [IN] 指定的Key
//第一参数: [IN] 对应的值
//返回说明: 
//备注说明: 
//********************************************************************
void CJson::WriteFloat(const char *szKey, float fValue)
{
	if (szKey == NULL)
	{
		return;
	}

	std::set<std::string>::iterator iterKey = m_cStringCache.find(szKey);
	if (iterKey == m_cStringCache.end())
	{
		m_cStringCache.insert(szKey);
		iterKey = m_cStringCache.find(szKey);
		if (iterKey == m_cStringCache.end())
		{
			return;
		}
	}

	m_Doc.AddMember(iterKey->c_str(), fValue, m_Doc.GetAllocator());
}

void CJson::WriteObject(const char *szKey, jsonobj& obj)
{
    if (szKey == NULL)
    {
        return;
    }

    std::set<std::string>::iterator iterKey = m_cStringCache.find(szKey);
    if (iterKey == m_cStringCache.end())
    {
        m_cStringCache.insert(szKey);
        iterKey = m_cStringCache.find(szKey);
        if (iterKey == m_cStringCache.end())
        {
            return;
        }
    }

    m_Doc.AddMember(iterKey->c_str(), obj, m_Doc.GetAllocator());
}

