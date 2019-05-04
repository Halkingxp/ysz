/*****************************************************************************
Copyright (C), 2008-2009, ***. Co., Ltd.
文 件 名:  DelaySelectMgr.cpp
作    者:  
版    本:  1.0
完成日期:  2013-6-22
说明信息:  延迟执行SQL语句的管理器
*****************************************************************************/
#include "Socket/NetServer.h"
#include "DelaySelectMgr.h"
#include "DataBase/DataBase.h"
#include "World.h"
#include "Tools/StringTools.h"
#include "Protocol.h"
#include "DataStructure/MsgQueue.h"

extern CDataBase	g_cInstDataBase;	// 实例数据库表

CDelaySelectMgr::CDelaySelectMgr(void)
{
    m_cInstQueue.reserve(MAX_DELAYSELECT_NUM + 1);
}

CDelaySelectMgr::~CDelaySelectMgr(void)
{
}

CDelaySelectMgr& CDelaySelectMgr::GetInstance(void)
{
    static CDelaySelectMgr object;
    return object;
}

void CDelaySelectMgr::Run(void)
{
    uint32 nCountInst = 0;
    String strSQL;
    String strCallback;
    uint32 nCallbackProtocol;
    uint32 nSocketID;
    VEC_SQL tempInst;
    tempInst.reserve(MAX_DELAYSELECT_NUM + 1);
    CPacket cpData;
    while (IsRun())
    {
		{
			std::lock_guard<std::mutex> g(m_cLock);
            tempInst.swap(m_cInstQueue);
        }

        VEC_SQL::iterator it = tempInst.begin();
        VEC_SQL::iterator end = tempInst.end();
        while (it != end)
        {
            strSQL              = it->str_sqlSyntax;
            strCallback         = it->str_Callback;
            nCallbackProtocol   = it->nCallbackProtocol;
            nSocketID           = it->nSocketID;
            it++;
            CQueryResult* pResult = g_cInstDataBase.Query(strSQL.c_str());
            cpData.Reset(nCallbackProtocol);
            if (pResult == NULL)
            {
                if (strCallback != "")
                {
                    if (nCallbackProtocol == SS_REQUEST_LUA)
                    {
                        cpData.WriteString(strCallback);
                    }
                    cpData.WriteUint16(0);
                    sNetServer.SendToClient(cpData, nSocketID);
                }
                continue;
            }

            if (nCallbackProtocol == SS_REQUEST_LUA)
            {
                cpData.WriteString(strCallback);
            }

            uint32  nRowCount = pResult->GetRowCount();    // 数据条数
            uint32  nCount    = pResult->GetFieldCount();  // 一条数据字段数

            uint16 nPos = cpData.GetWritePos();
            cpData.WriteUint16(0);

            CField* pField = pResult->Fetch();
            if (pField == NULL)
            {
                continue;
            }

            uint16 nCurrCount = 0;
            uint32 nLeftSize = PACKET_LEN;
            uint16 nCurrentSize = 0;
            do 
            {
                // 由于字符串的组装需要加入2字节表示长度，所以这里 2* nCount 表示最大字符串字段所增加的大小
                nCurrentSize = pResult->GetCurrentTotalByte() + 2 * nCount;
                if (nCurrentSize >= PACKET_LEN)
                {
                    sprintf(g_szInfo, "结果集太大，超过消息包大小:[%d], ResultSize:[%d], sql:[%s]", PACKET_LEN,  pResult->GetCurrentTotalByte(), strSQL.c_str());
                    REPORT(g_szInfo);
                    continue;
                }

                if (nLeftSize <= nCurrentSize)
                {
                    nLeftSize = PACKET_LEN;
                    cpData.Rrevise(nPos, &nCurrCount,sizeof(nCurrCount));
					sNetServer.SendToClient(cpData, nSocketID);
                    Sleep(30);

                    cpData.Reset(nCallbackProtocol);
                    if (nCallbackProtocol == SS_REQUEST_LUA)
                    {
                        cpData.WriteString(strCallback);
                    }
                    nPos = cpData.GetWritePos();
                    cpData.WriteUint16(0);
                    nCurrCount = 0;
                }

                nLeftSize -= nCurrentSize;
                CField* pField = pResult->Fetch();
                if (pField == NULL)
                {
                    continue;
                }
                for (uint32 i = 0; i < nCount; ++i)
                {
                    if (pField[i].GetType() == DB_TYPE_INTEGER)
                    {
                        cpData.WriteInt32(pField[i].GetInt32());
                    }
					else if (pField[i].GetType() == DB_TYPE_BIGINT)
					{
						cpData.WriteInt64(pField[i].GetInt64());
					}
                    else if (pField[i].GetType() == DB_TYPE_FLOAT)
                    {
                        cpData.WriteFloat(pField[i].GetFloat());
                    }
                    else if (pField[i].GetType() == DB_TYPE_STRING)
                    {
                        cpData.WriteString(pField[i].GetString());
                    }
                }
                nCurrCount++;
            } while (pResult->NextRow());

            if (nCurrCount != 0)
            {
                cpData.Rrevise(nPos, &nCurrCount,sizeof(nCurrCount));
				sNetServer.SendToClient(cpData, nSocketID);
            }

            nCountInst++;
            if (nCountInst >= MAX_DELAYSELECT_NUM)
            {
                nCountInst = 0;
                if (!m_isTopSpeed)
                {
                    Sleep(5);
                }	
            }
        }
        tempInst.clear();

        if (!m_isTopSpeed)
        {
            Sleep(5);
        }
    }
}

void CDelaySelectMgr::PushQuery(const String &strSQL, const String &strCallback, uint32 nCBProtocol, uint32 nSocketID)
{
	std::lock_guard<std::mutex> g(m_cLock);

    SQL_OP op;
    op.str_sqlSyntax = strSQL;
    op.str_Callback  = strCallback;
    op.nCallbackProtocol = nCBProtocol;
    op.nSocketID = nSocketID;

    // 如果不为空字符串,表示为SELECT操作
    if (strCallback != "")
    {

    }
    m_cInstQueue.push_back(op);
}

////********************************************************************
////函数功能: 压入通知完成队列
////函数作者: Herry 2015-1-6
////第一参数: 
////返回说明: 
////备注说明: 
////********************************************************************
//void CDelaySelectMgr::PushFinish(uint32 nID)
//{
//	m_cFinishQueue.Add(nID);
//}