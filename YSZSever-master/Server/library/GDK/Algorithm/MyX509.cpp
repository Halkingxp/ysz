#include <string.h> 
#include "openssl/x509.h"
#include "MyX509.h"

CMyX509::CMyX509(void)
{
    m_bits = DEFAULT_KEY_SIZE;

    m_public_key_size = 0;
    m_public_key = NULL;

    m_private_key_size = 0;
    m_private_key = NULL;

    m_exOpr[PUBLIC_ENCRYPTION].lpDoEnde = &CMyX509::DoPublicKeyEncryption;
    m_exOpr[PUBLIC_ENCRYPTION].key = &m_public_key;
    m_exOpr[PUBLIC_ENCRYPTION].key_size = &m_public_key_size;

    m_exOpr[PUBLIC_DECRYPTION].lpDoEnde = &CMyX509::DoPublicKeyDecryption;
    m_exOpr[PUBLIC_DECRYPTION].key = &m_public_key;
    m_exOpr[PUBLIC_DECRYPTION].key_size = &m_public_key_size;

    m_exOpr[PRIVATE_ENCRYPTION].lpDoEnde = &CMyX509::DoPrivateKeyEncryption;
    m_exOpr[PRIVATE_ENCRYPTION].key = &m_private_key;
    m_exOpr[PRIVATE_ENCRYPTION].key_size = &m_private_key_size;

    m_exOpr[PRIVATE_DECRYPTION].lpDoEnde = &CMyX509::DoPrivateKeyDecryption;
    m_exOpr[PRIVATE_DECRYPTION].key = &m_private_key;
    m_exOpr[PRIVATE_DECRYPTION].key_size = &m_private_key_size;
}

CMyX509::CMyX509(unsigned int key_size)
{
    if (key_size == 0)
    {
        m_bits = DEFAULT_KEY_SIZE;
    }
    else
    {
        m_bits = key_size;
    }

    m_public_key_size = 0;
    m_public_key = NULL;

    m_private_key_size = 0;
    m_private_key = NULL;

    m_exOpr[PUBLIC_ENCRYPTION].lpDoEnde = &CMyX509::DoPublicKeyEncryption;
    m_exOpr[PUBLIC_ENCRYPTION].key = &m_public_key;
    m_exOpr[PUBLIC_ENCRYPTION].key_size = &m_public_key_size;

    m_exOpr[PUBLIC_DECRYPTION].lpDoEnde = &CMyX509::DoPublicKeyDecryption;
    m_exOpr[PUBLIC_DECRYPTION].key = &m_public_key;
    m_exOpr[PUBLIC_DECRYPTION].key_size = &m_public_key_size;

    m_exOpr[PRIVATE_ENCRYPTION].lpDoEnde = &CMyX509::DoPrivateKeyEncryption;
    m_exOpr[PRIVATE_ENCRYPTION].key = &m_private_key;
    m_exOpr[PRIVATE_ENCRYPTION].key_size = &m_private_key_size;

    m_exOpr[PRIVATE_DECRYPTION].lpDoEnde = &CMyX509::DoPrivateKeyDecryption;
    m_exOpr[PRIVATE_DECRYPTION].key = &m_private_key;
    m_exOpr[PRIVATE_DECRYPTION].key_size = &m_private_key_size;
}

CMyX509::~CMyX509(void)
{
    if (m_public_key)
    {
        free(m_public_key);
        m_private_key = NULL;
    }
    if (m_private_key)
    {
        free(m_private_key);
        m_private_key = NULL;
    }
}

int CMyX509::DoEnde(const unsigned char *from,int from_size,unsigned char *to,int to_size,unsigned int nFlag)
{
    if (NULL == *m_exOpr[nFlag].key)
    {
        return -1;
    }

    if (nFlag > PRIVATE_DECRYPTION)
    {
        return -2;
    }
    return (this->*m_exOpr[nFlag].lpDoEnde)(*m_exOpr[nFlag].key,*m_exOpr[nFlag].key_size,from,from_size,to,to_size);
}

int CMyX509::DoEnde(const unsigned char *key,int key_size,const unsigned char *from,int from_size,unsigned char *to,int to_size,unsigned int nFlag)
{
    if (nFlag > PRIVATE_DECRYPTION)
    {
        return -2;
    }
    return (this->*m_exOpr[nFlag].lpDoEnde)(key,key_size,from,from_size,to,to_size);
}

bool CMyX509::InitRsa()
{
    RSA					*rsa;
    unsigned long		e;
    unsigned char		*pubt = NULL,*prit = NULL;

    e = RSA_3;

    if (0 == m_bits)
    {
        return 0;
    }

    rsa = RSA_generate_key(m_bits,e,NULL,NULL);
    if (NULL == rsa)
    {
        return false;
    }

    m_public_key_size = i2d_RSA_PUBKEY(rsa,&pubt);
    m_public_key = (unsigned char *)malloc(m_public_key_size);
    memcpy(m_public_key,pubt,m_public_key_size);

    m_private_key_size = i2d_RSA_PUBKEY(rsa,&prit);
    m_private_key = (unsigned char *)malloc(m_private_key_size);
    memcpy(m_private_key,pubt,m_private_key_size);

    if(rsa != NULL)
    {
        RSA_free(rsa);
        rsa = NULL;
    }

    return true;
}

void CMyX509::SetPublicKey(const unsigned char *key,unsigned int key_size)
{
    if (key)
    {
        if(NULL == m_public_key)
        {
            m_public_key = (unsigned char *)malloc(key_size);
        }
        else if(m_public_key_size < key_size)
        {
            free(m_public_key);
            m_public_key = (unsigned char *)malloc(key_size);
        }
        memset(m_public_key,0x00,m_public_key_size);
        memcpy(m_public_key,key,key_size);
        m_public_key_size = key_size;
    }
}

void CMyX509::SetPrivateKey(const unsigned char *key,unsigned int key_size)
{
    if (key)
    {
        if(NULL == m_private_key)
        {
            m_private_key = (unsigned char *)malloc(key_size);
        }
        else if(m_private_key_size < key_size)
        {
            free(m_private_key);
            m_private_key = (unsigned char *)malloc(key_size);
        }
        memset(m_private_key,0x00,m_private_key_size);
        memcpy(m_private_key,key,key_size);
        m_private_key_size = key_size;
    }
}

unsigned int CMyX509::GetPublicKey(unsigned char **key)
{
    if (NULL == key)
        return 0;

    *key = (unsigned char *)malloc(m_public_key_size);
    memset(*key,0x00,m_public_key_size);
    memcpy(*key,m_public_key,m_public_key_size);
    return m_public_key_size;
}

unsigned int CMyX509::GetPrivateKey(unsigned char **key)
{
    if (NULL == key)
        return 0;

    *key = (unsigned char *)malloc(m_private_key_size);
    memset(*key,0x00,m_private_key_size);
    memcpy(*key,m_private_key,m_private_key_size);
    return m_private_key_size;
}

int CMyX509::DoPublicKeyEncryption(const unsigned char *key,int key_size,const unsigned char *from,int from_size,unsigned char *to,int to_size)
{
    int					padding;
    int					fsurlen,to_count,flen;
    int					result;
    int					i;
    const unsigned char	*ucp;
    unsigned char		*from_temp;
    unsigned char		*to_temp;
    RSA					*rsa;

    ucp = key;
    rsa = d2i_RSA_PUBKEY(NULL,&ucp,key_size);
    if (NULL == rsa)
    {
        return 0;
    }

    padding = RSA_PKCS1_PADDING;
    flen = RSA_size(rsa);
    flen -= 11;

    from_temp = (unsigned char*)malloc(flen);
    to_temp = (unsigned char*)malloc((flen + 11) * 2);
    fsurlen = from_size;
    to_count = 0;

    for(i = 0;fsurlen > 0;i++)
    {
        memset(from_temp,0x00,flen);
        memset(to_temp,0x00,(flen + 11) * 2);
        memcpy(from_temp,&from[flen * i],flen);
        fsurlen -= flen;
        result = RSA_public_encrypt(flen,from_temp,to_temp,rsa,padding);
        if(-1 == result)
        {
            free(from_temp);
            free(to_temp);
            return 0;
        }

        memcpy(to + to_count,to_temp,result);
        to_count += result;
        if((to_count + result) > to_size)
        {
            free(from_temp);
            free(to_temp);
            return 0;
        }
    }

    free(from_temp);
    free(to_temp);
    return to_count;
}

int CMyX509::DoPublicKeyDecryption(const unsigned char *key,int key_size,const unsigned char *from,int from_size,unsigned char *to,int to_size)
{
    int					padding;
    int					fsurlen,to_count,flen;
    int					result;
    int					i;
    const unsigned char	*ucp;
    unsigned char		*from_temp;
    unsigned char		*to_temp;
    RSA					*rsa;

    ucp = key;
    rsa = d2i_RSA_PUBKEY(NULL,&ucp,key_size);
    if(NULL == rsa)
    {
        return 0;
    }

    padding = RSA_PKCS1_PADDING;
    flen = RSA_size(rsa);

    from_temp = (unsigned char*)malloc(flen);
    to_temp = (unsigned char*)malloc(flen);
    fsurlen = from_size;
    to_count = 0;

    for(i = 0;fsurlen > 0;i++)
    {
        memset(from_temp,0x00,flen);
        memset(to_temp,0x00,flen);
        memcpy(from_temp,&from[flen * i],flen);
        fsurlen -= flen;
        result = RSA_public_decrypt(flen,from_temp,to_temp,rsa,padding);
        if(-1 == result)
        {
            free(from_temp);
            free(to_temp);
            return 0;
        }

        memcpy(to + to_count,to_temp,result);
        to_count += result;
        if((to_count + result) > to_size)
        {
            free(from_temp);
            free(to_temp);
            return 0;
        }
    }

    free(from_temp);
    free(to_temp);
    return to_count;
}

int CMyX509::DoPrivateKeyEncryption(const unsigned char *key,int key_size,const unsigned char *from,int from_size,unsigned char *to,int to_size)
{
    int					padding;
    int					fsurlen,to_count,flen;
    int					result;
    int					i;
    const unsigned char	*ucp;
    unsigned char		*from_temp;
    unsigned char		*to_temp;
    RSA					*rsa;

    ucp = key;
    rsa = d2i_RSA_PUBKEY(NULL,&ucp,key_size);
    if(NULL == rsa)
    {
        return 0;
    }

    padding = RSA_PKCS1_PADDING;
    flen = RSA_size(rsa);
    flen -= 11;

    from_temp = (unsigned char*)malloc(flen);
    to_temp = (unsigned char*)malloc((flen + 11) * 2);
    fsurlen = from_size;
    to_count = 0;

    for(i = 0;fsurlen > 0;i++)
    {
        memset(from_temp,0x00,flen);
        memset(to_temp,0x00,(flen + 11) * 2);
        memcpy(from_temp,&from[flen * i],flen);
        fsurlen -= flen;
        result = RSA_private_encrypt(flen,from_temp,to_temp,rsa,padding);
        if(-1 == result)
        {
            free(from_temp);
            free(to_temp);
            return 0;
        }

        memcpy(to + to_count,to_temp,result);
        to_count += result;
        if((to_count + result) > to_size)
        {
            free(from_temp);
            free(to_temp);
            return 0;
        }
    }

    free(from_temp);
    free(to_temp);
    return to_count;
}

int CMyX509::DoPrivateKeyDecryption(const unsigned char *key,int key_size,const unsigned char *from,int from_size,unsigned char *to,int to_size)
{
    int					padding;
    int					fsurlen,to_count,flen;
    int					result;
    int					i;
    const unsigned char	*ucp;
    unsigned char		*from_temp;
    unsigned char		*to_temp;
    RSA					*rsa;

    ucp = key;
    rsa = d2i_RSA_PUBKEY(NULL,&ucp,key_size);
    if(NULL == rsa)
    {
        return 0;
    }

    padding = RSA_PKCS1_PADDING;	
    flen = RSA_size(rsa);

    from_temp = (unsigned char*)malloc(flen);
    to_temp = (unsigned char*)malloc(flen);
    fsurlen = from_size;
    to_count = 0;

    for(i = 0;fsurlen > 0;i++)
    {
        memset(from_temp,0x00,flen);
        memset(to_temp,0x00,flen);
        memcpy(from_temp,&from[flen * i],flen);
        fsurlen -= flen;
        result = RSA_private_decrypt(flen,from_temp,to_temp,rsa,padding);
        if(-1 == result)
        {
            free(from_temp);
            free(to_temp);
            return 0;
        }

        memcpy(to + to_count,to_temp,result);
        to_count += result;
        if((to_count + result) > to_size)
        {
            free(from_temp);
            free(to_temp);
            return 0;
        }
    }

    free(from_temp);
    free(to_temp);
    return to_count;
}