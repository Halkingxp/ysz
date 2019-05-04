/*****************************************************************************
Copyright (C), 2012-2100, ^^^^^^^^. Co., Ltd.
文 件 名:  MsgQueue.h
作    者:  Herry  
版    本:  1.0
完成日期:  2012-11-13
说明信息:  消息队列, 多线程安全
*****************************************************************************/
#pragma once
#include "Packet/Packet.h"
#include "DataStructure/Queue.h"
#include <mutex>

#define MAX_MSG_QUEUE_LEN			6000		// 消息队列长度



typedef std::vector<CPacket*> PACK_VEC;
class CMsgQueueVec
{
private:
    CMsgQueueVec(void);
    ~CMsgQueueVec(void);
public:
    static CMsgQueueVec& GetInstance(void) { static CMsgQueueVec obj; return obj; }

public:
    bool PushPacket(CPacket &cPacket);
    bool Empty()    { return m_vecMsg.empty(); }
    void Get(PACK_VEC& vec);
    void ClearAll(void);
    uint32 GetSize(void)     { return m_vecMsg.size();}
    uint32 GetMaxCount(void) { return m_nMaxCount;    }
private:
    PACK_VEC            m_vecMsg;
    std::mutex			m_cLock;
    uint32              m_nMaxCount;
};
#define sMsgQueueVec CMsgQueueVec::GetInstance()


