/*****************************************************************************
Copyright (C), 2008-2009, ***. Co., Ltd.
文 件 名:  BackstageMgr.h
说明信息:  
*****************************************************************************/
#pragma once
#include "Data.h"
#include "Thread/Thread.h"

class CBackstageMgr : public CThread
{
private:
	CBackstageMgr(void);
    ~CBackstageMgr(void);
public:
    static CBackstageMgr& GetInstance(void) { static CBackstageMgr obj; return obj; }

protected:
	virtual void Run(void);
};

#define sBackstageMgr CBackstageMgr::GetInstance()


