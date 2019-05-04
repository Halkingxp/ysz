/*****************************************************************************
Copyright (C), 2013-2015, ***. Co., Ltd.
文 件 名:  ScriptMgr.h
作    者:    
版    本:  1.0
完成日期:  2013-11-14
说明信息:  脚本管理器, 调用python脚本
*****************************************************************************/
#pragma once
#include "Define.h"

class CScriptPython
{
private:
	CScriptPython(void);
	~CScriptPython(void);

public:
    static CScriptPython& GetInstance(void);

	int  Initialize(const char *szPath);
	bool CallScript(const String &strScript, const String &strFunction, CPacket *pInParam = NULL, CPacket *pOutParam = NULL);
	bool CallScriptTokenList(const String &strScript, const String &strFunction, std::vector<String>& token);
private:
	String m_cPath;
};

#define sScriptMgr    CScriptMgr::GetInstance()