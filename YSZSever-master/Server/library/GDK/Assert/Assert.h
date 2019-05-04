#pragma once

#include "Define.h"
#if defined WIN32 && _DEBUG
	//#include <windows.h>
	#include <winuser.h>
#endif



#if defined (_M_IX86)
#define _DbgBreak() __asm { int 3 }
#elif defined (_M_IA64)
	void __break(int);
#pragma intrinsic (__break)
#define _DbgBreak() __break(0x80016)
#else 
#define _DbgBreak() DebugBreak()
#endif


//********************************************************************
//函数功能: 异常断言并错误日志记录
//第一参数: [IN] 日志记录描述
//第二参数: [IN] 断言文件信息, 传__FILE__
//第三参数: [IN] 断言函数信息, 传__FUNCTION__
//第四参数: [IN] 断言行号信息, 传__LINE__
//返回说明: 返回 -1, 参数异常, 参数有空指针
//返回说明: 返回  0, 断言结束
//备注说明: 程序启动时需要对LOG_ERROR类型的日志进行初始化
//********************************************************************
inline int _Assert(const char *szMsg, const char *szFile, const char *szFunc, unsigned int nLine)
{
	if (szMsg == NULL || szFile == NULL || szFunc == NULL)
	{
		return -1;
	}

	// DEBUG下还要弹出中断窗口
	static char szBuffer[BUFFER_LEN] = {};
	sprintf(szBuffer, "信息: %s\r\n文件: %s\r\n函数: %s\r\n行号: %d\r\n", szMsg, szFile, szFunc, nLine);

	#if defined WIN32 && _DEBUG
	{
		// DEBUG下先记录错误日志
		LOGE(szBuffer);

		sprintf(szBuffer, "%s【中止】结束程序 【重试】中断调试 【忽略】继续运行", szBuffer);
		int iRet = MessageBoxA(GetActiveWindow(), szBuffer, "异常", MB_ABORTRETRYIGNORE | MB_ICONERROR | MB_SYSTEMMODAL);
		if (iRet == IDABORT)
		{
			exit(EXIT_FAILURE);
		}
		else if (iRet == IDRETRY)
		{
			_DbgBreak();
		}
		return 0;
	}
	#else
	{
		// RELEASE下只记录错误日志
		LOGE(szBuffer);
		return 0;
	}
	#endif
};

#define REPORT(info)			(void)((_Assert((info), __FILE__, __FUNCTION__, __LINE__)))












