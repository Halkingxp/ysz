/*****************************************************************************
Copyright (C), 2012-2100, ^^^^^^^^. Co., Ltd.
文 件 名:  HttpClient.h
说明信息:  多线程安全
*****************************************************************************/
#pragma once
#include "Data.h"
#include "DataStructure/Queue.h"
#include <mutex>
#include <vector>
#include "curl/curl.h"
#include "Thread/Thread.h"


#define MAX_LOG_QUEUE_LEN    10000

struct HTTP_NODE
{
	String  strUrl;
	String  strData;
};
typedef std::vector<HTTP_NODE> HTTP_VEC;
class CHttpClient : public CThread
{
private:
	CHttpClient(void);
    ~CHttpClient(void);
public:
    static CHttpClient& GetInstance(void) { static CHttpClient obj; return obj; }

public:
	void SendHttpRequest(const String& strUrl, const String& strData);
    bool Push(const String& strUrl, const String& strData);
    void Get(HTTP_VEC& vec);
	void ClearAll(void);
	bool Empty(void)		 { return m_vecMsg.empty(); }
    uint32 GetSize(void)     { return m_vecMsg.size();  }

protected:
	virtual void Run(void);

private:
    HTTP_VEC            m_vecMsg;
	std::mutex			m_cLock;
	CURL*               m_pCurl;
	curl_slist*         m_Headers;
};
#define sHttpClient CHttpClient::GetInstance()


