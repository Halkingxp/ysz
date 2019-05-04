/*****************************************************************************
Copyright (C), 2012-2100, . Co., Ltd.
文 件 名:  DumpFile.h
作    者:  Herry
版    本:  1.0
完成日期:  2012-8-30
说明信息:  Windows平台下的dump文件
*****************************************************************************/
#pragma once
#include <DbgHelp.h>
#pragma comment(lib, "DbgHelp.lib")


class CDumpFile
{
public:
	static CDumpFile& GetInstance(void)
	{
		static CDumpFile obj;
		return obj;
	}

private:
	CDumpFile(void)
	{
		SetPath("Dump");
		m_Type = MiniDumpNormal;
	}

	~CDumpFile(void)
	{
	}

public:

	//********************************************************************
	//函数功能：创建MiniDump文件, 并记录相关信息
	//第一参数：
	//返回说明: 
	//异常说明:
	//备注说明: 
	//使用说明: 
	//
	//此函数定义为全局函数
	//********************************************************************
	//函数功能: MiniDump出现崩溃异常后的回调函数
	//第一参数：
	//返回说明: 
	//异常说明:
	//备注说明: ::SetUnhandledExceptionFilter(OnFileDump); 设置回调
	//********************************************************************
	//LONG WINAPI OnFileDump(EXCEPTION_POINTERS *lpException)
	//{
	//	MiniDump &dump = MiniDump::GetInstance();
	//	dump.OnFileMiniDump(lpException);
	//
	//	return EXCEPTION_EXECUTE_HANDLER;
	//};
	//********************************************************************
	void OnFileMiniDump(EXCEPTION_POINTERS *lpException)
	{
		char file[MAX_PATH] = {};
		::GetLocalTime(&m_Time);
		sprintf_s(file, "%s%04d-%02d-%02d [%02d.%02d.%02d].dmp",
			m_strPath, m_Time.wYear, m_Time.wMonth, m_Time.wDay,
			m_Time.wHour, m_Time.wMinute, m_Time.wSecond);

		HANDLE hFile = CreateFileA(file,
			GENERIC_READ | GENERIC_WRITE,
			0,
			NULL,
			CREATE_ALWAYS,
			FILE_ATTRIBUTE_NORMAL,
			NULL);

		if ((hFile != NULL) && (hFile != INVALID_HANDLE_VALUE))
		{
			MINIDUMP_EXCEPTION_INFORMATION mdei;

			mdei.ThreadId = GetCurrentThreadId();
			mdei.ExceptionPointers = lpException;
			mdei.ClientPointers = FALSE;

			BOOL rv = MiniDumpWriteDump(GetCurrentProcess(),
				GetCurrentProcessId(),
				hFile,
				m_Type,
				(lpException != 0) ? &mdei : 0,
				0,
				0);
			if (!rv)
			{
				//cout << "MiniDumpWriteDump failed. Error: " << GetLastError() << endl;
			}

			CloseHandle(hFile);

		}
		else
		{
			//cout << "CreateFile failed. Error: " << GetLastError() << endl;
		}
	}

	//********************************************************************
	//函数功能：设置记录路径

	//第一参数：路径字符串

	//返回说明: 
	//异常说明:
	//备注说明: 如果不设置创建路径, 默认在当前项目所在文件夹创建
	//********************************************************************
	bool SetPath(const char *path)
	{
		if (path == NULL)
		{
			return false;
		}
		strcpy(m_strPath, path);
		return true;
	}

	//********************************************************************
	//函数功能：设置记录类型

	//第一参数：类型枚举值

	//返回说明: 
	//异常说明:

	//备注说明: 类型不同记录文件的大小以及信息会有很大的区别
	//备注说明: 默认是迷你类型
	//********************************************************************
	void SetMiniDumpType(MINIDUMP_TYPE type)
	{
		m_Type = type;
	}

private:
	char		  m_strPath[MAX_PATH];
	MINIDUMP_TYPE m_Type;
	SYSTEMTIME    m_Time;
};

#define sDumpFile CDumpFile::GetInstance()


