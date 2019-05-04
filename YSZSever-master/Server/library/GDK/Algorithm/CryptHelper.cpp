/*
 * CryptoHelper.cpp
 *
 *  Created on: 2014年6月5日
 *      Author: Administrator
 */

#include "CryptHelper.h"

namespace UTILS
{
EVP_PKEY* CryptHelper::getKeyByPKCS1(const std::string &key, const int32_t keyType)
{
    RSA* rsa = getRsaKey(key, keyType);
    if(!rsa)
    {
        printf("getRsaKey failed !\n");
        return NULL;
    }
    EVP_PKEY* pkey = EVP_PKEY_new();
    if(1 != EVP_PKEY_assign_RSA(pkey, rsa))
    {
        printf("EVP_PKEY_assign_RSA failed !\n");
        RSA_free(rsa);
        EVP_PKEY_free(pkey);
        return NULL;
    }
    return pkey;
}

RSA* CryptHelper::getRsaKey(const std::string &key, const int32_t keyType)
{
    uint8_t *keyBuf;
    uint8_t *p;

    keyBuf = (uint8_t *) alloca(key.length());

    size_t keyLen(0);
    keyLen = base64Decode(keyBuf, (const uint8_t *) key.c_str(), key.length());
    if (0 > keyLen)
    {
        printf("base64Decode key failed !\n");
        return NULL;
    }

    //d2i_RSA_PUBKEY
    p = keyBuf;
    RSA *rsa =
            (keyType == 0) ?
                    d2i_RSA_PUBKEY(NULL, (const uint8_t **) &p, keyLen) :
                    d2i_RSAPrivateKey(NULL, (const uint8_t **) &p, keyLen);
    return rsa;
}


EVP_PKEY* CryptHelper::getKeyByPKCS8(const std::string &key)
{
    uint8_t* keyBuf = (uint8_t *) alloca(key.length());
    size_t keyLen = base64Decode(keyBuf, (const uint8_t *) key.c_str(), key.length());
    BIO* bio = BIO_new_mem_buf(keyBuf, keyLen);
    PKCS8_PRIV_KEY_INFO* v8Key = d2i_PKCS8_PRIV_KEY_INFO_bio(bio, NULL);
    EVP_PKEY* vkey = EVP_PKCS82PKEY(v8Key);
    return vkey;
}


void CryptHelper::freeKey(RSA* key)
{
    if (key)
        RSA_free(key);
}

void CryptHelper::freeKey(EVP_PKEY* key)
{
    if (key)
        EVP_PKEY_free(key);
}


int32_t CryptHelper::signWithRsa(const std::string &data, const EVP_MD *type, EVP_PKEY* priKey, std::string &sign)
{
    EVP_MD_CTX mdCtx;
    EVP_SignInit(&mdCtx, type);
    EVP_SignUpdate(&mdCtx, data.c_str(), data.length());

    uint32_t signLen(EVP_PKEY_size(priKey)), outLen(0);
    uint8_t* signBuf = (uint8_t *) OPENSSL_malloc(signLen);
    uint8_t* outBuf = (uint8_t *) OPENSSL_malloc(signLen * 2);

    int32_t ret = EVP_SignFinal(&mdCtx, signBuf, &signLen, priKey);
    if (1 != ret)
    {
        printf("EVP_SignFinal failed\n");
    }
    else
    {
        if (0 > (outLen = EVP_EncodeBlock(outBuf, signBuf, signLen)))
        {
            ret = -1;
            printf("EVP_EncodeBlock failed\n");
        }
        else
        {
            sign.assign((char*)outBuf, outLen);
        }
    }

    OPENSSL_free(signBuf);
    OPENSSL_free(outBuf);

    return 1 == ret ? 0 : -1;
}

int32_t CryptHelper::verifySignWithRsa(const std::string &data, const std::string &sign, const EVP_MD *type, EVP_PKEY* pubKey)
{
    EVP_MD_CTX mdCtx;
    uint8_t* signSrc = (uint8_t *) OPENSSL_malloc(sign.length());
    int32_t signSrcLen = base64Decode(signSrc, (const uint8_t *)sign.c_str(), sign.length());
    if(0 > signSrcLen)
    {
        printf("sign base64Decode failed\n");
        OPENSSL_free(signSrc);
        return -1;
    }

    EVP_VerifyInit(&mdCtx, type);
    EVP_VerifyUpdate(&mdCtx, data.c_str(), data.length());
    int32_t ret = EVP_VerifyFinal(&mdCtx, signSrc, signSrcLen, pubKey);

    OPENSSL_free(signSrc);
    return 1 == ret ? 0 : -2;
}


int32_t CryptHelper::md5WithRsa(const std::string &data, std::string &sign, EVP_PKEY* priKey)
{
    return signWithRsa(data, EVP_md5(), priKey, sign);
}


int32_t CryptHelper::verifyMd5WithRsa(const std::string &data, const std::string &sign, EVP_PKEY* pubKey)
{
    return verifySignWithRsa(data, sign, EVP_md5(), pubKey);
}


int32_t CryptHelper::base64Encode(uint8_t *out, const uint8_t *in, int32_t inl)
{
    int32_t outl(0);

    outl = EVP_EncodeBlock(out, in, inl);
    if (0 > outl)
    {
        return -1;
    }
    return outl;

}

int32_t CryptHelper::base64Decode(uint8_t *out, const uint8_t *in, int32_t inl)
{
    int32_t outl(0), ret(0);

    if ('=' == in[inl - 1])
    {
        ret++;
    }
    if ('=' == in[inl - 2])
    {
        ret++;
    }
    outl = EVP_DecodeBlock(out, in, inl);
    if (0 > outl)
    {
        printf("EVP_DecodeBlock failed\n");
        return -1;
    }
    out[outl - ret] = '\0';
    return outl - ret;
}


}  //end namespace UTILS
