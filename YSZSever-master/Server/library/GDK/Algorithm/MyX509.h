#pragma once

#define	DEFAULT_KEY_SIZE	1024


enum X509_TYPE
{
    PUBLIC_ENCRYPTION       = 0,    //π´‘øº”√‹
    PUBLIC_DECRYPTION       = 1,    //π´‘øΩ‚√‹
    PRIVATE_ENCRYPTION      = 2,    //ÀΩ‘øº”√‹
    PRIVATE_DECRYPTION      = 3,    //ÀΩ‘øΩ‚√‹
};

class CMyX509
{
private:
    unsigned int m_bits;
    unsigned int m_public_key_size;
    unsigned char *m_public_key;
    unsigned int m_private_key_size;
    unsigned char *m_private_key;

    typedef int (CMyX509::*LPFUNEX)(const unsigned char *key,int key_size,const unsigned char *from,int from_size,unsigned char *to,int to_size);

    struct tagOperator
    {
        LPFUNEX lpDoEnde;
        unsigned char **key;
        unsigned int *key_size;
    };

    tagOperator m_exOpr[4];

    int DoPublicKeyEncryption(const unsigned char *key,int key_size,const unsigned char *from,int from_size,unsigned char *to,int to_size);
    int DoPublicKeyDecryption(const unsigned char *key,int key_size,const unsigned char *from,int from_size,unsigned char *to,int to_size);
    int DoPrivateKeyEncryption(const unsigned char *key,int key_size,const unsigned char *from,int from_size,unsigned char *to,int to_size);
    int DoPrivateKeyDecryption(const unsigned char *key,int key_size,const unsigned char *from,int from_size,unsigned char *to,int to_size);

public:
    CMyX509(void);
    CMyX509(unsigned int key_size);
    ~CMyX509(void);

    bool InitRsa();

    void SetPublicKey(const unsigned char *key,unsigned int key_size);
    void SetPrivateKey(const unsigned char *key,unsigned int key_size);

    unsigned int GetPublicKey(unsigned char **key);
    unsigned int GetPrivateKey(unsigned char **key);

    int DoEnde(const unsigned char *from,int from_size,unsigned char *to,int to_size, unsigned int nFlag);
    int DoEnde(const unsigned char *key,int key_size,const unsigned char *from,int from_size,unsigned char *to,int to_size,unsigned int nFlag);
};
