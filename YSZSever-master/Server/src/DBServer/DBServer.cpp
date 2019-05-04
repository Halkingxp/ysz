#if defined WIN32
#define WIN32_LEAN_AND_MEAN
#endif

#include "Define.h"

#if defined WIN32
#include "DumpFile/DumpFile.h"
#else
#include <signal.h>
#endif

#include "World/ServerCommend.h"
#include "Statistics/StatisticsMgr.h"
#include "World/World.h"
#include "World/ThreadWatch.h"
#include "Tools/TimeTools.h"
#include "Xml/Xml.h"
#include "DataBase/DataBase.h"
#include "Timer/TimerMgr.h"
#include "World/DelaySaveMgr.h"
#include "World/DelaySelectMgr.h"
#include "DataStructure/MsgQueue.h"
#include "Socket/NetServer.h"
#include "Socket/NetClient.h"


using namespace std;

CXml		g_cSystemXml;		// 读取系统配置
CDataBase	g_cInstDataBase;	// 实例数据库表
CDataBase	g_cLogDataBase;		// 日志数据库表 

//extern CXml		g_cSystemXml;		// 读取系统配置
//extern CDataBase	g_cInstDataBase;	// 实例数据库表
//extern CDataBase	g_cLogDataBase;		// 日志数据库表 


#if defined(WIN32)
	/********************************************************************
	函数功能: MiniDump出现崩溃异常后的回调函数
	第一参数：
	返回说明: 
	异常说明:
	备注说明: 
	********************************************************************/
	inline LONG WINAPI OnFileDump(EXCEPTION_POINTERS *lpException)
	{
		char szInfo[BUFFER_LEN] = {};
		sprintf(szInfo, "当前协议编号: %d",	sStatisticsMgr.GetProtocol());
		REPORT(szInfo);

		sDumpFile.OnFileMiniDump(lpException);
		return EXCEPTION_EXECUTE_HANDLER;
	};
#endif


int main(int argc, char* argv[])
{
///////////////////////////////////////////////////////
//第一步: 各模块初始化并启动功能
///////////////////////////////////////////////////////

#if defined(WIN32)
	//// 启动内存泄漏检测功能
	//CheckMemoryLeakOut();

	//// 启动Dump记录功能
	//sDumpFile.SetPath("DBServer");
	//sDumpFile.SetMiniDumpType(MiniDumpWithFullMemory);
	//SetUnhandledExceptionFilter(OnFileDump);
#else
	// 忽略信号，防止崩溃
	signal(SIGPIPE, SIG_IGN);
#endif
		
	// 内存泄漏检测
	//CrtSetBreakAlloc(555);

	// 初始化随机种子
	u_int t = (u_int)CTimeTools::GetSystemTimeToSecond();
	srand(t);

#if defined (WIN32)
	char *configfile = "dbserver.conf";
#else
	char * configfile = NULL;
	std::string directory = argv[0];
	size_t find = 0, findbin = 0;
	find = directory.find_last_of("/\\");
	directory = directory.substr(0, find);
	findbin = directory.find("bin");
	directory = directory.substr(0, findbin) + "etc/dbserver.conf";
	configfile = directory.c_str();
#endif

	zsummer::log4z::ILog4zManager::getRef().setLoggerDisplay(LOG4Z_MAIN_LOGGER_ID, true);
	zsummer::log4z::ILog4zManager::getRef().setLoggerLevel(LOG4Z_MAIN_LOGGER_ID, LOG_LEVEL_INFO);
	zsummer::log4z::ILog4zManager::getRef().setLoggerLimitsize(LOG4Z_MAIN_LOGGER_ID, 20);
	zsummer::log4z::ILog4zManager::getRef().start();

	printf("系统配置路径: %s\r\n", configfile);
	if (!g_cSystemXml.OpenXmlFile(configfile))
	{
		REPORT("启动程序时, 读取配置xml失败");
		return -1;
	}

    // 初始化各种单例管理器
    sMsgQueueVec;
    sStatisticsMgr;
    sTimerMgr;
    sWorld;
    sDelaySaveMgr;
    sDelaySelectMgr;
    sThreadWatch;

	// 提前初始化
	sMsgQueueVec.ClearAll();

	int iRet = 0;
	
	// 初始化网络
	uint16 nListenPort = g_cSystemXml.ReadInt("Communication", "TCPPort");
	if (0 == nListenPort)
	{
		REPORT("启动程序时, DBServer.conf中TCP监听端口为空, 请检查");
		return -1;
	}
	iRet = sNetServer.Startup(1000, nListenPort, "");
	if (iRet != 0)
	{
		sprintf(g_szInfo, "启动程序时监听本地端口[%d]失败, 原因:%d", nListenPort, iRet);
		REPORT(g_szInfo);
		return -1;
	}

	// 所有功能模块的初始化
	iRet = sWorld.Initialize();
	if (0 != iRet)
	{
		sprintf(g_szInfo, "启动程序时, World初始化失败, 返回值: %d", iRet);
		REPORT(g_szInfo);
		return -1;
	}
   
    // 启动线程守卫
    sThreadWatch.Start();

    // 启动delaysave线程
    sDelaySaveMgr.Start();
     
    // 启动delyaselect线程
    sDelaySelectMgr.Start();

    // 启动World线程
    sWorld.Start();
     
   printf("------------ DBServer初始化完成 ------------\r\n");

    CServerCommend command;
    // 启动控制台功能, 线程优先级低
    command.SetServerName("DBServer");
    command.Start();

///////////////////////////////////////////////////////
//第二步: 初始化完成, 程序开始循环执行, 等待控制台输入结束命令
///////////////////////////////////////////////////////
	sWorld.Stop();
	sThreadWatch.Stop();
	command.Stop();

///////////////////////////////////////////////////////
//第三步: 程序已收到结束执行, 开始释放内存, 等待程序终止
///////////////////////////////////////////////////////

	// 所有功能模块的内存释放
	sWorld.Destroy();
	return 0;
}

