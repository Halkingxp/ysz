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
#include "Script/ScriptLua.h"


extern CXml			g_cSystemXml;		// 读取系统配置
CWorld::CWorld(void) : m_nServerID(0), m_isPrintf(true)
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
	// 初始化线程守护者
	uint16 nWatchID = sThreadWatch.Initialize("HubServer.WorldThraed");
	static uint32 nLastTime = CTimeTools::GetSystemTimeToTick();

	// 消息队列
    uint32 nOpcode = 0;
    uint16 nMsgCount = 0;
    uint16 nUpdateCount = 0;
    PACK_VEC vecMsg;
    vecMsg.reserve(MAX_MSG_QUEUE_LEN);
	while (IsRun())
	{
		sNetServer.Update();
		sNetClient.Update();
		//sTimerWheel.UpdateWheel();

        vecMsg.clear();
        sMsgQueueVec.Get(vecMsg);
        if (!vecMsg.empty())
        {
            PACK_VEC::iterator it = vecMsg.begin();
            PACK_VEC::iterator end = vecMsg.end();
            while (it != end)
            {
				CPacket* pPacket = *it;
				it++;

				nOpcode = pPacket->GetOpcode();
                // 开始统计
                sStatisticsMgr.StatisticsStart(nOpcode, pPacket->GetSize());

                // 取消息成功, 消息处理
                MsgProc(*pPacket);
                // 结算一次统计
                sStatisticsMgr.StatisticsEnd(nOpcode);

                nMsgCount++;
                if (nMsgCount > 50)
                {
                    nMsgCount = 0;
                    // 计时管理器更新
                    sTimerMgr.Update();
                    // 更新线程守卫
                    sThreadWatch.Updata(nWatchID);  
                    Sleep(5);

                    // 此处不能break
                }

				delete pPacket;
				pPacket = NULL;
            }
        }
        else
        {
            // 空闲状态下休眠
            Sleep(5);

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
	}
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

    // 消息传给lua
    if (sScriptLua.Msg_lua(cPacket) == 0)
    {
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
int CWorld::Initialize(const String& directory)
{
	sNetServer.SetNotifyCloseProtocol(SS_CLOSE_CONNECT);
	sNetClient.SetCallbackProtocol(SS_RECONNECT);

	RegMsgCallbackFun(SS_RECONNECT, _OnReConnect);
	RegMsgCallbackFun(SS_REQUEST_LUA, _OnResponesLua);
	RegMsgCallbackFun(SS_RELOAD_LUA, _OnReloadLua);
	RegMsgCallbackFun(SS_TEST_LUA, _OnTestLua);
	RegMsgCallbackFun(SS_WORLD_MESSAGE, _OnTestThread);

	int8 iRet = 0;
	// 初始化lua
	String strLuaPath = g_cSystemXml.ReadString("Script", "Dirctory");
	iRet = sScriptLua.Initlua(strLuaPath, GetServerID());
	if (iRet != 0)
	{
		sprintf(g_szInfo, "lua初始化化失败,%d", iRet);
		REPORT(g_szInfo);
		return -11;
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
//函数功能: 向DB发送SQL命令
//函数作者: Herry 2015-9-6
//第一参数: [IN] SQL语法
//第二产生: [IN] 返回协议编号
//返回说明: 
//备注说明: Lua脚本里也封装了类似的函数, 若要调整字段, 需两边一起修改
//备注说明: Lua函数 function SQLQuery(SQL_Syntax, Callback)
//********************************************************************
void CWorld::RequestExecuteSQL(const String& strSQL, uint32 nProtocol)
{
	// 请求db数据
	CPacket cp(SS_REQUEST_LUA);
	cp.WriteString(strSQL);     // SQL语法
	cp.WriteUint8(0);           // DB类型, 0实例数据, 1日志数据
	cp.WriteUint16(nProtocol);  // 返回协议编号
	sNetClient.SendToServer(cp, m_nDBSocketID);
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

void CWorld::_OnGameMapping(CPacket& cPacket)
{
	sWorld.m_nGameSocketID = cPacket.GetSocketID();
	LOGFMTI("==========>>>>> GameServer_SocketID Mapping:%d", cPacket.GetSocketID());
}

//********************************************************************
//函数功能: 有服务端断开连接的回调机制
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CWorld::_OnReConnect(CPacket &cPacket)
{

	get_string(strCallback, cPacket);
	sScriptLua.CallLuaFun(3, 1, luafun(strCallback), luapush((void*)&cPacket), luapush(cPacket.GetSocketID()));

	// 上面处理和下面处理2选1
	//// 断线重新连接
	//sprintf(g_szInfo, "HubServer与DBServer心跳断开\r\n");
	//REPORT(g_szInfo);

	//// 连接DB服务器
	//String strDBServerIP = g_cSystemXml.ReadString("Communication", "DBServerIP");
	//uint16 nDBServerPort = g_cSystemXml.ReadInt("Communication", "DBServerPort");
	//sWorld.m_nDBSocketID = sNetClient.Connect(strDBServerIP, nDBServerPort, "", "");
	//if (sWorld.m_nDBSocketID <= 4)
	//{
	//	sprintf(g_szInfo, "重新连接DB服务器时失败, 原因:%d", sWorld.m_nDBSocketID);
	//	REPORT(g_szInfo);
	//	return;
	//}
	//else
	//{
	//	LOGFMTI("==========>>>>> ReConnect_DBServer SocketID:%d", sWorld.m_nDBSocketID);
	//}
}


//********************************************************************
//函数功能: 通用的消息处理函数
//函数作者:  2015-9-6
//第一参数: 
//返回说明: 
//备注说明: 向DB发送SQL命令执行后返回的回调处理 (调用Lua函数处理)
//********************************************************************
void CWorld::_OnResponesLua(CPacket &cPacket)
{
    get_string(strCallback, cPacket);
    sScriptLua.CallLuaFun(2, 1, luafun(strCallback),luapush((void*)&cPacket));
}

//********************************************************************
//函数功能: 重新加载Lua脚本
//函数作者: 2016-1-15
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CWorld::_OnReloadLua(CPacket &cPacket)
{
    get_string(strLuafile, cPacket)
    sScriptLua.LoadFile(strLuafile);
}

//********************************************************************
//函数功能: 测试Lua消息处理
//函数作者: 2016-1-15
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CWorld::_OnTestLua( CPacket &cPacket )
{
    get_uint32(nAccountID, cPacket);
    sScriptLua.LoadFile("TestMsg.lua");
    sScriptLua.CallLuaFun(2, 0, luafun("lua_TestMsg"), luapush(nAccountID));
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
