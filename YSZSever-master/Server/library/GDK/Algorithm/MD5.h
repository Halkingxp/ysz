/*****************************************************************************
Copyright (C), 2013-2015, ***. Co., Ltd.
文 件 名:  MD5.h
作    者:    
版    本:  1.0
完成日期:  2013-8-9
说明信息:  基于OpenSSL的MD5算法
*****************************************************************************/
#pragma once
#include "openssl/md5.h"
#include "Define.h"

class CMD5
{
public:
	CMD5(void);
	~CMD5(void);

public:
	void	Update(const String &strDate);
	void	Update(const uint8 *szDate, uint32 nLen);
	String	ToString(void);

private:
	MD5_CTX		m_cMD5;
	uint8		m_szData[MD5_DIGEST_LENGTH];
};