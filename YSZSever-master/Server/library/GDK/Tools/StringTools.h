/*****************************************************************************
Copyright (C), 2012-2100, ^^^^^^^^. Co., Ltd.
文 件 名:  StringTools.h
作    者:  Herry  
版    本:  1.0
完成日期:  2012-8-28
说明信息:  
*****************************************************************************/
#pragma once
#include "Define.h"
#include <algorithm>

typedef std::map<String, String>    KeyValueMap;

class CStringTools
{
public:

	//********************************************************************
	//函数功能: 字节数组转十六进制字符串
	//第一参数: [IN] 字节数组
	//第二参数: [IN] 字节数组长度 strlen(szBytes)
	//返回说明: 成功, 返回十六进制字符串
	//返回说明: 失败, 返回""
	//备注说明: 
	//********************************************************************
	static String BytesToHexString(const uint8* szBytes, uint32 nLength) 
	{
		static const char HEX[16] = { '0', '1', '2', '3','4', '5', '6', '7','8', '9', 'a', 'b','c', 'd', 'e', 'f' };
		if (szBytes == NULL)
		{
			return "";
		}

		String str;
		str.reserve(nLength << 1);

		uint8 t = 0;
		uint8 a = 0;
		uint8 b = 0;
		for (uint32 i = 0; i < nLength; ++i) 
		{
			t = szBytes[i];
			a = t / 16;
			b = t % 16;
			str.append(1, HEX[a]);
			str.append(1, HEX[b]);
		}
		return str;
	}

	//********************************************************************
	//函数功能: 解析文件名和文件后缀名
	//第一参数: [IN & OUT] 文件名  例如 abc.png  解析成 abc
	//第二参数: [OUT] 解析的后缀名 例如 abc.png  解析成 .png
	//返回说明: 返回true, 解析成功
	//返回说明: 返回false, 解析失败
	//备注说明: 
	//********************************************************************
	static bool PathFindExtension(String &strFileName, String &strExtension)
	{
		String::size_type n = strFileName.rfind(".");
		if(n == std::string::npos)
		{
			return false;
		}

		strExtension = strFileName.substr(n);
		strFileName = strFileName.substr(0, n);
		return true;
	}

	//********************************************************************
	//函数功能: 将源字符串中包含的字符串替换成指定字符串
	//第一参数: [IN & OUT] 待替换的字符串
	//第二参数: [IN] 被替换的字符串
	//第三参数: [IN] 替换成目标字符串
	//备注说明: 将strString中, 包含strInvolve的字符串替换成strReplace
	//********************************************************************
	static void StringReplace(String& strString, const String & strInvolve, const String &strReplace)
	{
		String::size_type pos = 0;
		while( (pos = strString.find(strInvolve, pos)) != String::npos)
		{
			strString.replace(pos, strInvolve.length(), strReplace);
			pos += strInvolve.length();
		}
	}

	//********************************************************************
	//函数功能: 字符串转小写字符串
	//第一参数: [IN] 字符串
	//返回说明: 转成小写后的字符串
	//备注说明: 
	//********************************************************************
	static String StringToLower(const String &strString)
	{
		String strLower = strString;
		transform(strLower.begin(), strLower.end(), strLower.begin(), ::tolower);
		return strLower;
	}

	//********************************************************************
	//函数功能: 字符串转大写字符串
	//第一参数: [IN] 字符串
	//返回说明: 转成大写后的字符串
	//备注说明: 
	//********************************************************************
	static String StringToUpper(const String &strString)
	{
		String strUpper = strString;
		transform(strUpper.begin(), strUpper.end(), strUpper.begin(), ::toupper);
		return strUpper;
	}

	//********************************************************************
	//函数功能: 整型转字符串
	//第一参数: [IN] 待转换的整型值
	//返回说明: 转换后的字符串
	//备注说明: 
	//********************************************************************
	static String IntToString(int32 iValue)
	{
		static char szTmp[32] = {};
		sprintf(szTmp, "%s", (char*)(&iValue));
		// linux 没有itoa
		// itoa(iValue, szTmp, 10);

		String strValue(szTmp);
		return strValue;
	}

	//********************************************************************
	//函数功能: 字符串转整型
	//第一参数: [IN] 待转换的字符串
	//返回说明: 转换后的整型
	//备注说明: 
	//********************************************************************
	static int32 StringToInt(const String &strValue)
	{
		return atoi(strValue.c_str());
	}

    //********************************************************************
	//函数功能: 字符串转浮点型
	//第一参数: [IN] 待转换的字符串
	//返回说明: 转换后的整型
	//备注说明: 
	//********************************************************************
	static float StringToFloat(const String &strValue)
	{
		return (float)atof(strValue.c_str());
	}

	//********************************************************************
	//函数功能: 安全的字符串写入函数
	//第一参数: [IN] 写入的字符串数组
	//第二参数: [IN] 写入的字符串数组长度, 传sizeof()长度
	//第三参数: [IN] 格式以及动态参数
	//返回说明: >0  返回拷贝长度
	//返回说明: <=0 拷贝失败
	//备注说明: 如果有内存越界写入, 程序正常终止时, 会有提示
	//********************************************************************
	static int32 SafeSprintf(char *szBuffer, uint32 nBufferSize, const char *szFormat...)
	{
		if (szBuffer == NULL || szFormat == NULL)
		{
			return 0;
		}

		va_list ap;
		va_start(ap, szFormat);
		int iLen = (uint32)vsnprintf(szBuffer, nBufferSize, szFormat, ap);
		va_end(ap);

		return iLen;
	};


	//********************************************************************
	//函数功能: 安全的字符串拷贝
	//
	//第一参数: [IN] 目标串首地址
	//第二参数: [IN] 目标串长度 (包括结束符 即 sizeof(pDes) 的长度)
	//第三参数: [IN] 源串首地址
	//
	//返回说明: 返回拷贝长度, (不包括结束符 即 strlen(pDes) 的长度)
	//返回说明: 异常情况返回值为0, 表示拷贝失败
	//
	//异常说明: 1. 目标串或源串为空指针  返回0
	//异常说明: 2. 自我拷贝				 返回0
	//异常说明: 3. 重叠内存拷贝			 返回0
	//
	//备注说明: 1. 源串必须是以'\0'结束的字符串.
	//备注说明: 2. 拷贝完成后目标串始终以'\0'结束.
	//********************************************************************
	static uint32 SafeStrcpy(char *pDes, uint32 nDesSize, const char *pSrc)
	{
		//空指针检查, 自我拷贝检查
		if (pDes == NULL || pSrc == NULL || pDes == pSrc)
		{
			return 0;
		}
		//避免重叠内存拷贝
		if (pDes < pSrc + nDesSize && pSrc < pDes + nDesSize)
		{
			return 0;
		}
		uint32 nCopySize = 0;
		while (nCopySize + 1 < nDesSize && pSrc[nCopySize] != '\0')
		{
			pDes[nCopySize] = pSrc[nCopySize];
			nCopySize++;
		}
		pDes[nCopySize] = '\0';
		return nCopySize;
	}

	//********************************************************************
	//函数功能: 字符串解析
	//第一参数: [IN] 待解析的字符串
	//第二参数: [IN] 切割字符
	//返回说明: 解析后的内容
	//返回说明: 
	//********************************************************************
	static STRING_VECTOR Tokenizer(const String &strData, const char cDelimiter)
	{
		STRING_VECTOR vec;
		vec.clear();

		std::string s;
		for (uint32 i = 0; i < (uint32)strData.length(); i++)
		{
			if (strData[i] != cDelimiter)
			{
				s += strData[i];
			}
			else
			{
				if (s.length() > 0)
				{
					vec.push_back(s);
				}
				s = "";
			}
		}
		if (s.length() > 0)
		{
			vec.push_back(s);
		}
		return vec;
	};
	
	//********************************************************************
	//函数功能: x_www_form_urlencoded序列化
	//第一参数: [IN] key
	//第二参数: [IN] value
    //第三参数: [IN] 需要连续组装的字符串，默认值为新字符串
	//返回说明: 序列化后的内容
	//返回说明: 
	//********************************************************************
	static std::string Serialize_x_www_form_urlencoded(const String &key, const String &value, const String &src = "")
	{
		String strTemp = src;
		String kv = key+'='+value;
		if (strTemp == "")
		{
			return kv;
		}
		else
		{
			strTemp = strTemp + '&';
			strTemp = strTemp + kv;
		}

		return strTemp;
	}

    //********************************************************************
	//函数功能: x_www_form_urlencoded反序列化
    //第一参数: [IN] 反序列化的字符串
	//返回说明: 序列化后的内容
	//返回说明: 
	//********************************************************************
	static KeyValueMap Deserialize_x_www_form_urlencoded(const String &src)
	{
		KeyValueMap map;
        int p1 = 0;     // = 所在位置
        int p2 = 0;     // & 所在位置
        int ret = 0;
        while(1)
        {
            p2 = src.find('&', p2);
            int LastP1 = p1;
            p1 = src.find('=', p1);
            if (p2 == String::npos)
            {
                String key = src.substr(LastP1, p1 - LastP1);
                p1++;
                String value = src.substr(p1, src.length());
                map.insert(std::make_pair(key, value));
                break;
            } 
            else
            {
                String key = src.substr(LastP1, p1 - LastP1);
                p1++;
                String value = src.substr(p1, p2 - p1);
                map.insert(std::make_pair(key, value));
                p1 = p2 + 1;
                p2++;
            }
        }
		return map;
	}
    //********************************************************************
	//函数功能: x_www_form_urlencoded反序列化后, 读取对应Key的Value
	//返回说明: 
	//********************************************************************
    static String GetValue(const KeyValueMap& map, const String& key)
    {
        KeyValueMap::const_iterator it = map.find(key);
        if (it != map.end())
        {
            return it->second;
        }
        return "";
    }

    //********************************************************************
	//函数功能: urlencode
    //第一参数: [IN] 需要encode的字符串
	//返回说明: 序列化后的内容
	//返回说明: 
	//********************************************************************
    static String UrlEncode(const String& szToEncode) 
    { 

        String src = szToEncode; 
        char hex[] = "0123456789ABCDEF"; 
        String dst; 
        for (size_t i = 0; i < src.size(); ++i)
        { 
            unsigned char cc = src[i]; 
            if (isascii(cc)) 
            { 
                if (cc == ' ') 
                { 
                    dst += "%20"; 

                } 
                else
                    dst += cc; 
            } 
            else
            { 

                unsigned char c = static_cast<unsigned char>(src[i]);
                dst += '%'; 
                dst += hex[c / 16]; 
                dst += hex[c % 16];
            } 

        } 
        return dst; 
    }  

    //********************************************************************
	//函数功能: urldecode
    //第一参数: [IN] 需要decode的字符串
	//返回说明: 序列化后的内容
	//返回说明: 
	//********************************************************************
    static String UrlDecode(const String& szToDecode) 
    { 
        String result; 
        int hex = 0; 
        for (size_t i = 0; i < szToDecode.length(); ++i) 
        { 
            switch (szToDecode[i]) 
            { 
            case '+': 
                result += ' '; 
                break; 
            case '%': 
                if (isxdigit(szToDecode[i + 1]) && isxdigit(szToDecode[i + 2])) 
                {
                    String hexStr = szToDecode.substr(i + 1, 2); 
                    hex = strtol(hexStr.c_str(), 0, 16);
                    //字母和数字[0-9a-zA-Z]、一些特殊符号[$-_.+!*'(),] 、以及某些保留字[$&+,/:;=?@] 

                    //可以不经过编码直接用于URL 
                    if (!((hex >= 48 && hex <= 57) || //0-9 
                        (hex >=97 && hex <= 122) ||   //a-z 
                        (hex >=65 && hex <= 90) ||    //A-Z 
                        //一些特殊符号及保留字[$-_.+!*'(),]  [$&+,/:;=?@] 
                        hex == 0x21 || hex == 0x24 || hex == 0x26 || hex == 0x27 || hex == 0x28 || hex == 0x29 
                        || hex == 0x2a || hex == 0x2b|| hex == 0x2c || hex == 0x2d || hex == 0x2e || hex == 0x2f 
                        || hex == 0x3A || hex == 0x3B|| hex == 0x3D || hex == 0x3f || hex == 0x40 || hex == 0x5f 
                        )) 
                    { 
                        result += char(hex);
                        i += 2; 
                    } 
                    else result += '%'; 
                }else { 
                    result += '%'; 
                } 
                break; 
            default: 
                result += szToDecode[i]; 
                break; 
            } 

        } 
        return result; 
    } 
};
