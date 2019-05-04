/*****************************************************************************
Copyright (C), 2013-2015, ***. Co., Ltd.
文 件 名:  HMacSha1.h
作    者:    
版    本:  1.0
完成日期:  2013-11-05
说明信息:  基于OpenSSL的HMacSha1算法
*****************************************************************************/
#pragma once
#include <openssl/hmac.h>
#include <openssl/sha.h>
#include "Define.h"

class CHMacSha1
{
public:
	CHMacSha1(const String &strKey);
	~CHMacSha1(void);

public:
	void	Update(const String &strDate);
	String	ToString(void);
    uint8*  ToData();

private:
	HMAC_CTX	m_cCTX;
	String		m_strKey;
	uint8		m_szData[SHA_DIGEST_LENGTH];
};