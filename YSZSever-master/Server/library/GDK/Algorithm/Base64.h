/*****************************************************************************
Copyright (C), 2012. ^^^^^^^^. Co., Ltd.
文 件 名:  Base64.h
作    者:    
版    本:  1.0
完成日期:  2012-8-2
说明信息:  
*****************************************************************************/
#pragma once
#include <string>

class CBase64
{
public:
	static char* Encode(const char* szData, unsigned int nDataLen);     // 加密, 使用完成释放内存
	static char* Decode(const char* szData, unsigned int& nResultSize); // 解密, 使用完成释放内存

    static char* OpenSSLEncode(const char* szInput, unsigned int nLength, bool isNewLine);	     // 加密, 使用完成释放内存
    static char* OpenSSLDecode(char * szInput, unsigned int nLength, bool isNewLine);			 // 解密, 使用完成释放内存
};


