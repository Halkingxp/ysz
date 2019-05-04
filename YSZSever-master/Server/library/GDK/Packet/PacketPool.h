/*****************************************************************************
Copyright (C), 2015-2050, ***. Co., Ltd.
完成日期:  2016-11-25
说明信息:  消息包的内存池
*****************************************************************************/
#pragma once
#include <list>
#include <mutex>
#include "Packet.h"

// 内存池管理器
class CPacketPool
{
private:
	CPacketPool(void);
	~CPacketPool(void);

public:
	static CPacketPool& GetInstance(void);

public:
	void	 Init(uint16 nInitSize, uint16 nExpansionSize);
	CPacket* Pop(void);
	void	 Push(CPacket *pPacket);

private:
	std::mutex				m_cLock;
	std::list<CPacket*>		m_cFreeList;
	uint32					m_nExpansion;
};

#define sPacketPool CPacketPool::GetInstance()


