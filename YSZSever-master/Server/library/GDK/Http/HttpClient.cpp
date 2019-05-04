/*****************************************************************************
Copyright (C), 2012-2100, ^^^^^^^^. Co., Ltd.
文 件 名:  HttpClient.cpp
说明信息:   多线程安全
*****************************************************************************/
#include "HttpClient.h"
#include "Assert/Assert.h"


size_t DoNothingCallback(void *ptr, size_t size, size_t nmemb, void *stream)
{
	return size * nmemb;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

CHttpClient::CHttpClient(void)
{
	m_vecMsg.reserve(MAX_LOG_QUEUE_LEN);
	m_Headers = NULL;
	m_pCurl = curl_easy_init();
}

CHttpClient::~CHttpClient(void)
{
	curl_slist_free_all(m_Headers);
	curl_easy_cleanup(m_pCurl);
}

bool CHttpClient::Push(const String& strUrl, const String& strData)
{
	std::lock_guard<std::mutex> g(m_cLock);

	HTTP_NODE cNode;
	cNode.strUrl = strUrl;
	cNode.strData = strData;
    m_vecMsg.push_back(cNode);
    return true;
}

void CHttpClient::Get(HTTP_VEC& vec)
{
    if (!vec.empty())
    {
        REPORT("异常情况 vec不为空");
        return;
    }

	std::lock_guard<std::mutex> g(m_cLock);
    vec.swap(m_vecMsg);
}

void CHttpClient::ClearAll(void)
{
	std::lock_guard<std::mutex> g(m_cLock);
    m_vecMsg.clear();
}


void CHttpClient::Run(void)
{
	uint32 nNowTick = 0;
	uint32 nLastTick = 0;
	uint16 nUpdateCount = 0;
	uint32 nTick = 0;
	HTTP_VEC vecMsg;
	HTTP_NODE cNode;
	vecMsg.reserve(MAX_LOG_QUEUE_LEN);
	while (IsRun())
	{
		vecMsg.clear();
		sHttpClient.Get(vecMsg);
		if (!vecMsg.empty())
		{
			HTTP_VEC::iterator it = vecMsg.begin();
			HTTP_VEC::iterator end = vecMsg.end();
			while (it != end)
			{
				cNode = *it;
				it++;

				nLastTick = CTimeTools::GetSystemTimeToTick();
				sHttpClient.SendHttpRequest(cNode.strUrl, cNode.strData);
				nNowTick = CTimeTools::GetSystemTimeToTick();

				nTick = nNowTick - nLastTick;
				if (nTick > 500)
				{
					printf("Send Log Tick:%d\r\n", nTick);
				}
				Sleep(10);
			}
		}
		else
		{
			Sleep(10);
		}
	}
}

void CHttpClient::SendHttpRequest(const String& strUrl, const String& strData)
{
	curl_easy_setopt(m_pCurl, CURLOPT_URL, strUrl.c_str());

	m_Headers = curl_slist_append(m_Headers, "Content-Type: application/json");
	curl_easy_setopt(m_pCurl, CURLOPT_HTTPHEADER, m_Headers);

	curl_easy_setopt(m_pCurl, CURLOPT_TIMEOUT, 10L);
	curl_easy_setopt(m_pCurl, CURLOPT_FORBID_REUSE, 0);

	if (strData.length() > 0)
	{
		curl_easy_setopt(m_pCurl, CURLOPT_WRITEDATA, &strData);
	}
	curl_easy_setopt(m_pCurl, CURLOPT_WRITEFUNCTION, DoNothingCallback);
	CURLcode ret = curl_easy_perform(m_pCurl);
	curl_slist_free_all(m_Headers);
	m_Headers = NULL;
	if (ret != CURLE_OK)
	{
		char szInfo[8192] = {};
		sprintf(szInfo, "Send HttpRequest Error:%d; URL:%s Data:%s", ret, strUrl.c_str(), strData.c_str());
		LOGE(szInfo);
	}
}