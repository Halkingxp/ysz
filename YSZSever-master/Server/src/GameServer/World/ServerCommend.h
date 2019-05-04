/*****************************************************************************
Copyright (C), 2012-2100, ^^^^^^^^. Co., Ltd.
文 件 名:  ServerCommend.h
作    者:  Herry  
版    本:  1.0
完成日期:  2012-11-12
说明信息:  服务器的控制台命令
*****************************************************************************/
#pragma once
#include "Command/Command.h"

class CServerCommend : public CCommand
{
public:
    CServerCommend(void);
    virtual ~CServerCommend(void);

protected:
	virtual void Quit(const STRING_VECTOR &vParam);
	void Statistics(const STRING_VECTOR &vParam);
	void TestThread(const STRING_VECTOR &vParam);
	void NetSwitch(const STRING_VECTOR &vParam);
	void MsgSize(const STRING_VECTOR &vParam);
	void Loadlua(const STRING_VECTOR &vParam);
	void LogSwitch(const STRING_VECTOR &vParam);
	void TestLua(const STRING_VECTOR &vParam);
	void ShowServerID(const STRING_VECTOR &vParam);
	void Kick(const STRING_VECTOR &vParam);



	void SendBroadcast(const STRING_VECTOR &vParam);
	void SendToHubServer(const STRING_VECTOR &vParam);
	void SendToDBServer(const STRING_VECTOR &vParam);
};

