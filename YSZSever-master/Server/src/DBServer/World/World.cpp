/*****************************************************************************
Copyright (C), 2012-2100, ^^^^^^^^. Co., Ltd.
文 件 名:  World.cpp
作    者:  Herry   
版    本:  1.0
完成日期:  2012-11-12
说明信息:  
*****************************************************************************/
#include "Socket/NetServer.h"
#include "Socket/NetClient.h"
#include "World.h"
#include "Define.h"
#include "ThreadWatch.h"
#include "DataStructure/MsgQueue.h"
#include "Timer/TimerMgr.h"
#include "Tools/TimeTools.h"
#include "Protocol.h"
#include "Xml/Xml.h"
#include "Statistics/StatisticsMgr.h"
#include "Json/Json.h"
#include "DelaySaveMgr.h"
#include "DelaySelectMgr.h"
#include "DataBase/DataBase.h"


extern CXml			g_cSystemXml;		// 读取系统配置
extern CDataBase	g_cInstDataBase;	// 实例数据库表
extern CDataBase	g_cLogDataBase;		// 日志数据库表

CWorld::CWorld(void)
{
}

CWorld::~CWorld(void)
{
}

CWorld& CWorld::GetInstance(void)
{
    static CWorld object;
    return object;
}


void CWorld::Run(void)
{
	// 启动数据库线程
	g_cInstDataBase.ThreadStart();

	// 初始化线程守护者
	uint16 nWatchID = sThreadWatch.Initialize("DBServer.WorldThraed");

	// 消息队列
    uint32 nOpcode = 0;
    uint16 nMsgCount = 0;
    uint16 nUpdateCount = 0;
    PACK_VEC vecMsg;
    vecMsg.reserve(MAX_MSG_QUEUE_LEN);

	while (IsRun())
	{      
		sNetServer.Update();

        vecMsg.clear();
        sMsgQueueVec.Get(vecMsg);
        if (!vecMsg.empty())
        {
            PACK_VEC::iterator it = vecMsg.begin();
            PACK_VEC::iterator end = vecMsg.end();
            while (it != end)
            {
				CPacket* pPacket = *it;
                nOpcode = pPacket->GetOpcode();

                // 开始统计
                sStatisticsMgr.StatisticsStart(nOpcode, pPacket->GetSize());

                // 取消息成功, 消息处理
                MsgProc(*pPacket);
                it++;
                // 结算一次统计
                sStatisticsMgr.StatisticsEnd(nOpcode);

                nMsgCount++;
                if (nMsgCount > 100)
                {
                    nMsgCount = 0;

                    // 更新线程守卫
                    sThreadWatch.Updata(nWatchID);

                    // 计时管理器更新
                    sTimerMgr.Update(); 
					Sleep(10);

                    // 此处不能break
                }

				delete pPacket;
				pPacket = NULL;
            }
        }
        else
        {
            // 空闲状态下休眠
			Sleep(10);

            // 每执行100次循环, 更新一次数据
            nUpdateCount++;
            if (nUpdateCount > 100)
            {
                // 更新线程守卫
                sThreadWatch.Updata(nWatchID);

                // 计时管理器更新
                sTimerMgr.Update();
                nUpdateCount = 0;
            }
        }
        vecMsg.clear();
	}

	uint32 nInst = 0;
	uint32 nLog = 0;
	while (!sDelaySaveMgr.IsEmpty())
	{
		nInst = sDelaySaveMgr.GetQuerySize(DELAY_INST);
		nLog = sDelaySaveMgr.GetQuerySize(DELAY_LOG);
		printf("-- 服务器正在回存数据, 还有 %d 条数据\r\n", (nInst + nLog));
		Sleep(5000);
	}
	printf("--\r\n");
	printf("-- 服务器完成所有数据的回存,  -- 现在可以关闭程序了\r\n");
	// 终止数据库线程
	g_cInstDataBase.ThreadEnd();
}

//********************************************************************
//函数功能: 消息处理函数
//第一参数: [IN] 收到的消息包
//返回说明: 
//备注说明: 
//********************************************************************
void CWorld::MsgProc(CPacket &cPacket)
{
	// 解析消息包, 并处理
	uint32 nOpcode = cPacket.GetOpcode();

    MSG_CALLBACK_MAP::iterator it_op = m_cCallBackmap.find(nOpcode);
    // 兼容老版本，如果it_op == end() 不作处理
    if (it_op != m_cCallBackmap.end())
    {
        it_op->second(cPacket);
        return;
    }
}

//********************************************************************
//函数功能: 所有功能模块的初始化都放到这里
//第一参数: 
//返回说明: 返回0,   初始化成功
//返回说明: 返回非0, 初始化失败
//备注说明: 
//********************************************************************
int CWorld::Initialize(void)
{
	RegMsgCallbackFun(SS_WORLD_MESSAGE, CWorld::_OnTestThread);
	RegMsgCallbackFun(SS_TO_DBSERVER, CWorld::_OnTestNetMsg);
	RegMsgCallBackFun(SS_REQUEST_LUA, CWorld::_OnRequestData);

	int iRet = 0;
	String strHost = g_cSystemXml.ReadString("Database", "DatabaseHost");
	uint16 nPort = g_cSystemXml.ReadInt("Database", "DatabasePort");
	String strUser = g_cSystemXml.ReadString("Database", "DatabaseUser");
	String strPassword = g_cSystemXml.ReadString("Database", "DatabasePassword");

	String strInst = g_cSystemXml.ReadString("Database", "InstDatabase");
	String strLog = g_cSystemXml.ReadString("Database", "LogDatabase");
	String strConfig = g_cSystemXml.ReadString("Database", "ConfigDatabase");
	iRet = g_cInstDataBase.ConnectDataBase(strHost.c_str(), nPort, strUser.c_str(), strPassword.c_str(), strInst.c_str());
	if (0 != iRet)
	{
		sprintf(g_szInfo, "%s 数据库链接失败", strInst.c_str());
		REPORT(g_szInfo);
		return -2;
	}
	else
	{
		printf("连接 %s 数据库成功! \r\n", strInst.c_str());
	}

	iRet = g_cLogDataBase.ConnectDataBase(strHost.c_str(), nPort, strUser.c_str(), strPassword.c_str(), strLog.c_str());
	if (0 != iRet)
	{
		sprintf(g_szInfo, "%s 数据库链接失败", strLog.c_str());
		REPORT(g_szInfo);
		return -3;
	}
	else
	{
		printf("连接 %s 数据库成功! \r\n", strLog.c_str());
	}
	return 0;
}


//********************************************************************
//函数功能: 所有功能模块的释放内容都放到这里
//第一参数: 
//返回说明: 返回0,   释放成功
//返回说明: 返回非0, 释放失败
//备注说明: 
//********************************************************************
int CWorld::Destroy(void)
{
	sTimerMgr.Destroy();
	return 0;
}


//********************************************************************
//函数功能: 注册消息回调
//函数作者: 
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
bool CWorld::RegMsgCallBackFun(uint32 nOpcode, CallBackFun pFun)
{
    MSG_CALLBACK_MAP::iterator itf = m_cCallBackmap.find(nOpcode);
    if (itf != m_cCallBackmap.end())
    {
        sprintf(g_szInfo, "消息【%d】已被定义回调", nOpcode);
        REPORT(g_szInfo);
        return false;
    }

    m_cCallBackmap.insert(std::make_pair(nOpcode, pFun));
    return true;
}

void CWorld::_OnTestNetMsg(CPacket &cPacket)
{
	printf("==========Recv Test NetMsg, SocketID:%u\r\n", cPacket.GetSocketID());
}

void CWorld::_OnRequestData(CPacket &cPacket)
{
    get_string(strmysql, cPacket);
    get_uint8(dbtpye,   cPacket);
    get_uint16(CallbackProtocol, cPacket);

    String strCallback = "";
    if (CallbackProtocol == SS_REQUEST_LUA)
    {
        strCallback = cPacket.ReadString();
    }

    //实例数据用Select,log数据用Save
    if (dbtpye == DELAY_INST)
    {
        sDelaySelectMgr.PushQuery(strmysql, strCallback, CallbackProtocol, cPacket.GetSocketID());
    }
    else
    {
        sDelaySaveMgr.PushQuery((DelayType)dbtpye, strmysql);
    }
}

//********************************************************************
//函数功能: 测试World线程是否通畅
//函数作者: 2016-11-22
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CWorld::_OnTestThread(CPacket &cPacket)
{
	printf("收到测试WorldThread消息!\r\n");
}
