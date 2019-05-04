/*****************************************************************************
Copyright (C), 2013-2015, ***. Co., Ltd.
文 件 名:  SHA1.h
作    者:    
版    本:  1.0
完成日期:  2013-8-9
说明信息:  基于OpenSSL的SHA1算法
*****************************************************************************/
#pragma once
#include "openssl/sha.h"
#include "Define.h"

class SHA1
{
public:
	SHA1(void);
	~SHA1(void);

public:
	void	Update(const String &strDate);
	void	Update2(const uint8 *szDate, uint32 nLen);
	String	ToString(void);
	String	GetFinalData(void);  

private:
	SHA_CTX		m_cSHA1;
	uint8		m_szData[SHA_DIGEST_LENGTH];
};