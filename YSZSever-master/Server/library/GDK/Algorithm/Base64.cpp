/*****************************************************************************
Copyright (C), 2012. ^^^^^^^^. Co., Ltd.
文 件 名:  Base64.cpp
作    者:   
版    本:  1.0
完成日期:  2012-8-2
说明信息:  
*****************************************************************************/
#include "Base64.h"
#include <string.h> 
#include <openssl/evp.h>
#include <openssl/bio.h>
#include <openssl/buffer.h>

static const char s_szEncodeDictionary[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static char s_szDecodeDictionary[256];

static void InitBase64DecodeTable()
{   
    int i = 0;
    for (i = 0; i < 256; ++i) s_szDecodeDictionary[i] = (char)0x80;
    // default value: invalid

    for (i = 'A'; i <= 'Z'; ++i) s_szDecodeDictionary[i] = 0 + (i - 'A');
    for (i = 'a'; i <= 'z'; ++i) s_szDecodeDictionary[i] = 26 + (i - 'a');
    for (i = '0'; i <= '9'; ++i) s_szDecodeDictionary[i] = 52 + (i - '0');
    s_szDecodeDictionary[(char)'+'] = 62;
    s_szDecodeDictionary[(char)'/'] = 63;
    s_szDecodeDictionary[(char)'='] = 0;
}

//********************************************************************
//函数功能: 加密
//第一参数: [IN] 待加密的字符串
//第二参数: [IN] 待加密的字符串长度
//返回说明: 返回加密后的字符串
//备注说明: 使用完成, 需施放返回的字符串内存
//********************************************************************
char* CBase64::Encode(const char* szData, unsigned int nDataLen)
{
    char const* orig = (char const*)szData; // in case any input bytes have the MSB set
    unsigned int origLength = nDataLen;

    unsigned const numOrig24BitValues = origLength / 3;
    bool havePadding = origLength > numOrig24BitValues * 3;
    bool havePadding2 = origLength == numOrig24BitValues * 3 + 2;
    unsigned const numResultBytes = 4 * (numOrig24BitValues + havePadding);
    char* result = new char[numResultBytes + 1]; // allow for trailing '/0'

    // Map each full group of 3 input bytes into 4 output base-64 characters:
    unsigned i = 0;
    for (i = 0; i < numOrig24BitValues; ++i) 
    {
        result[4 * i + 0] = s_szEncodeDictionary[(orig[3 * i]>>2) & 0x3F];
        result[4 * i + 1] = s_szEncodeDictionary[(((orig[3 * i] & 0x3) << 4) | (orig[3 * i + 1] >> 4)) & 0x3F];
        result[4 * i + 2] = s_szEncodeDictionary[((orig[3 * i + 1] << 2) | (orig[3 * i + 2] >> 6)) & 0x3F];
        result[4 * i + 3] = s_szEncodeDictionary[orig[3 * i + 2] & 0x3F];
    }

    // Now, take padding into account.  (Note: i == numOrig24BitValues)
    if (havePadding) 
    {
        result[4 * i + 0] = s_szEncodeDictionary[(orig[3 * i] >> 2) & 0x3F];
        if (havePadding2)
        {
            result[4 * i + 1] = s_szEncodeDictionary[(((orig[3 * i] & 0x3) << 4) | (orig[3 * i + 1] >> 4)) & 0x3F];
            result[4 * i + 2] = s_szEncodeDictionary[(orig[3 * i + 1] << 2) & 0x3F];
        } 
        else 
        {
            result[4 * i + 1] = s_szEncodeDictionary[((orig[3 * i] & 0x3) << 4) & 0x3F];
            result[4 * i + 2] = '=';
        }
        result[4 * i + 3] = '=';
    }

    result[numResultBytes] = 0;
    return result;
}  

//********************************************************************
//函数功能: 解密
//第一参数: [IN] 加密过的字符串
//第二参数: [OUT] 返回解密后的字符串长度
//返回说明: 返回原文字符串
//备注说明: 使用完成, 需施放返回的字符串内存
//********************************************************************
char* CBase64::Decode(const char* szData, unsigned int& nResultSize)
{
    static bool haveInitedBase64DecodeTable = false;
    if (!haveInitedBase64DecodeTable)
    {
        InitBase64DecodeTable();
        haveInitedBase64DecodeTable = true;
    }

    size_t len = strlen(szData);
    char* out = new char[len + 1]; // ensures we have enough space

    int k = 0;
    int const jMax = len - 3;
    // in case "in" is not a multiple of 4 bytes (although it should be)
    for (int j = 0; j < jMax; j += 4) 
    {
        char inTmp[4], outTmp[4];
        for (int i = 0; i < 4; ++i) 
        {
            inTmp[i] = szData[i+j];
            outTmp[i] = s_szDecodeDictionary[(char)inTmp[i]];
            if ((outTmp[i] & 0x80) != 0) outTmp[i] = 0; // pretend the input was 'A'
        }

        out[k++] = (outTmp[0] << 2) | (outTmp[1] >> 4);
        out[k++] = (outTmp[1] << 4) | (outTmp[2] >> 2);
        out[k++] = (outTmp[2] << 6) | outTmp[3];
    }

    // Trim Trailing Zeros
    while (k > 0 && out[k-1] == 0)
    {   
        --k;
    }

    nResultSize = k;
    char* result = new char[nResultSize];
    memmove(result, out, nResultSize);
    delete[] out;
    return result;
}  

//********************************************************************
//函数功能: 加密
//第一参数: [IN] 源串
//第二参数: [IN] 长度
//第三参数: [IN] 是否换行(如果需要每64个字符换行一次，整个编码后的字符末尾也有换行，java的sdk默认不带换行)
//备注说明: 使用完成, 需施放返回的字符串内存
//********************************************************************
char * CBase64::OpenSSLEncode(const char * szInput, unsigned int nLength, bool isNewLine)
{  
    BIO * bmem = NULL;  
    BIO * b64 = NULL;  
    BUF_MEM * bptr = NULL;  

    b64 = BIO_new(BIO_f_base64());  
    if(!isNewLine) 
	{  
        BIO_set_flags(b64, BIO_FLAGS_BASE64_NO_NL);  
    }  
    bmem = BIO_new(BIO_s_mem());  
    b64 = BIO_push(b64, bmem);  
    BIO_write(b64, szInput, nLength);  
    BIO_flush(b64);  
    BIO_get_mem_ptr(b64, &bptr);  

    char * buff = (char *)malloc(bptr->length + 1);  
    memcpy(buff, bptr->data, bptr->length);  
    buff[bptr->length] = 0;  

    BIO_free_all(b64);  

    return buff;  
}  

//********************************************************************
//函数功能: 解密
//第一参数: [IN] 加密过的字符串
//第二参数: [OUT] 返回解密后的字符串长度
//第三参数: [IN] 是否换行(如果需要每64个字符换行一次，整个编码后的字符末尾也有换行，java的sdk默认不带换行)
//备注说明: 使用完成, 需施放返回的字符串内存
//********************************************************************
char * CBase64::OpenSSLDecode(char * szInput, unsigned int nLength, bool isNewLine)
{  
    BIO * b64 = NULL;  
    BIO * bmem = NULL;  
    char * buffer = (char *)malloc(nLength);  
    memset(buffer, 0, nLength);  

    b64 = BIO_new(BIO_f_base64());  
    if(!isNewLine) 
	{  
        BIO_set_flags(b64, BIO_FLAGS_BASE64_NO_NL);  
    }  
    bmem = BIO_new_mem_buf(szInput, nLength);  
    bmem = BIO_push(b64, bmem);  
    BIO_read(bmem, buffer, nLength);  

    BIO_free_all(bmem);  

    return buffer;  
}  