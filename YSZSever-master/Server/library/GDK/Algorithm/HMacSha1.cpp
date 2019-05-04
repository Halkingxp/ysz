/*****************************************************************************
Copyright (C), 2013-2015, ***. Co., Ltd.
文 件 名:  HMacSha1.cpp
作    者:     
版    本:  1.0
完成日期:  2013-11-5
说明信息:  
*****************************************************************************/
#include "HMacSha1.h"


CHMacSha1::CHMacSha1(const String &strKey)
{
	m_strKey = strKey;
	HMAC_CTX_init(&m_cCTX);
	HMAC_Init_ex(&m_cCTX, (uint8 *)m_strKey.c_str(), m_strKey.length(), EVP_sha1(), NULL);
}

CHMacSha1::~CHMacSha1(void)
{
	HMAC_CTX_cleanup(&m_cCTX);
}

//********************************************************************
//函数功能: 更新数据
//第一参数: [IN] 需要加密的字符串
//返回说明: 
//备注说明: 
//********************************************************************
void CHMacSha1::Update(const String &strDate)
{
	HMAC_Update(&m_cCTX, (uint8 *)strDate.c_str(), strDate.length());
}

//********************************************************************
//函数功能: 完成加密, 返回十六进制加密后的字符串
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
String CHMacSha1::ToString(void)
{
	uint32 nLength = 0;
	HMAC_Final(&m_cCTX, m_szData, &nLength);
	HMAC_CTX_init(&m_cCTX);
	HMAC_Init_ex(&m_cCTX, (uint8 *)m_strKey.c_str(), m_strKey.length(), EVP_sha1(), NULL);

	String strData = CStringTools::BytesToHexString(m_szData, SHA_DIGEST_LENGTH);//(char*)m_szData;//
	return strData;
}


//********************************************************************
//函数功能: 完成加密, 返回源串
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
uint8* CHMacSha1::ToData(void)
{
	uint32 nLength = 0;
	HMAC_Final(&m_cCTX, m_szData, &nLength);
	HMAC_CTX_init(&m_cCTX);
	HMAC_Init_ex(&m_cCTX, (uint8 *)m_strKey.c_str(), m_strKey.length(), EVP_sha1(), NULL);

    return m_szData;
}