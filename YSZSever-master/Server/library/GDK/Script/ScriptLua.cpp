#pragma once
#include "Socket/NetServer.h"
#include "Socket/NetClient.h"
#include "ScriptLua.h"
#include "Timer/TimerMgr.h"
#include "DataStructure/MsgQueue.h"
#include "Assert/Assert.h"
#include "Algorithm/Base64.h"
#include "Http/HttpClient.h"

#if !defined WIN32
#include <unistd.h>
#endif

uint8 CScriptLua::s_nWriteLog = 1;
uint8 CScriptLua::s_nLeaveSave = 1;

CScriptLua::CScriptLua()
{

}

CScriptLua::~CScriptLua()
{
    lua_close(pL);
}
int CScriptLua::Initlua(const String& strLuaPath, uint16 nServerID)
{
	pL = luaL_newstate();
	if (pL == NULL)
	{
		REPORT("初始化lua失败");
		return -1;
	}

    this->strLuaPath = strLuaPath;
	luaL_openlibs(pL);
    lua_checkstack(pL, 100);    // 将lua堆栈扩充到100
	lua_createtable(pL, 10, 400);//lua_newtable(pL);

    // 注册网络接口函数
    lua_register(pL, "c_ParserPacket", ParserPacketForLuaDefine);
	lua_register(pL, "c_SendMsgToClient", SendMsgToClient);
	lua_register(pL, "c_SendMsgToServer", SendMsgToServer);
	lua_register(pL, "c_SendHttpRequest", SendHttpRequest);
	lua_register(pL, "c_GetClientIP", GetClientIP);
	lua_register(pL, "c_GetServerIP", GetServerIP);
	lua_register(pL, "c_StartService", StartService);
	lua_register(pL, "c_Base64Encode", Base64Encode);
	lua_register(pL, "c_Base64Decode", Base64Decode);

	lua_register(pL, "c_ServerStartup", ServerStartup);
	lua_register(pL, "c_ServerShutdown", ServerShutdown);
	lua_register(pL, "c_ServerCloseSocket", ServerCloseSocket);
	lua_register(pL, "c_ClientConnect", ClientConnect);
	lua_register(pL, "c_ClientShutdown", ClientShutdown);
	lua_register(pL, "c_ClientCloseSocket", ClientCloseSocket);

	// 注册辅助接口函数
    lua_register(pL, "c_Errorlog", Errorlog);
    lua_register(pL, "c_Loglog", Loglog);
    lua_register(pL, "c_RegistryTimer", RegistryTimer);
    lua_register(pL, "c_CancelTimer", CancelTimer);
    lua_register(pL, "c_IsWriteLog", IsWriteLog);
    lua_register(pL, "c_TestMsg", TestMsg);
    lua_register(pL, "c_Sleep", SleepLua);
	lua_register(pL, "c_StringToTime", StringToTime);
	lua_register(pL, "c_GetTimeToMillisecond", GetTimeToMillisecond);
    lua_register(pL, "c_IsLeaveSave", IsLeaveSave);

    // 将枚举值类型定义给lua
    lua_pushinteger(pL, LUA_INT8);
    lua_setglobal(pL,"INT8");
    lua_pushinteger(pL, LUA_INT16);
    lua_setglobal(pL, "INT16");
    lua_pushinteger(pL, LUA_INT32);
    lua_setglobal(pL, "INT32");
    lua_pushinteger(pL, LUA_UINT8);
    lua_setglobal(pL, "UINT8");
    lua_pushinteger(pL, LUA_UINT16);
    lua_setglobal(pL, "UINT16");
    lua_pushinteger(pL, LUA_UINT32);
	lua_setglobal(pL, "UINT32");
    lua_pushinteger(pL, LUA_STRING);
    lua_setglobal(pL, "STRING");
    lua_pushinteger(pL, LUA_FLOAT);
    lua_setglobal(pL, "FLOAT");
    lua_pushinteger(pL, LUA_TABLE);
    lua_setglobal(pL, "TABLE");
    lua_pushinteger(pL, nServerID);
    lua_setglobal(pL, "SERVER_ID");
	lua_pushinteger(pL, LUA_DOUBLE);
	lua_setglobal(pL, "DOUBLE");
	lua_pushinteger(pL, LUA_INT64);
	lua_setglobal(pL, "INT64");

	
	LoadFile();
	return 0;
}

//********************************************************************
//函数功能: 加载所有lua脚本文件
//第一参数: 需要指定加载的文件
//备注说明: 
//********************************************************************
int CScriptLua::LoadFile(const String& strLoadFile)
{
	if (pL == NULL)
	{
		printf("load lua  falid\r\n");
		return -1;
	}
	if (strLoadFile != "all")
	{
		String str = strLuaPath + strLoadFile;
		if (luaL_dofile(pL,str.c_str()))
		{
			String result = lua_tostring(pL,1);
			lua_settop(pL, 0);
			sprintf(g_szInfo,"lua加载失败，错误信息:%s",result.c_str());
			REPORT(g_szInfo);
			return -1;
		}
		lua_settop(pL, 0);
		return 0;
	}
    else
	{
        String dir = strLuaPath + "init.lua";   
        if (luaL_dofile(pL,dir.c_str()))
        {
            String result = lua_tostring(pL,1);
            lua_settop(pL, 0);
            sprintf(g_szInfo,"lua加载失败，错误信息:%s",result.c_str());
            REPORT(g_szInfo);
            return -1;
		}
        uint8 d = lua_gettop(pL);
        lua_settop(pL, 0);		// 清空栈
        CallLuaFun(2, 0, luafun("File_Load"), luapush(strLuaPath));
        printf("---------- Load lua finish!----------- \r\n");
        return 0;
    }
}

void CScriptLua::StackDump(lua_State* L)
{
	printf("\n********begin dump lua stack********r\n");
	int i = 0;
	int top = lua_gettop(L);
	for (i = 1; i <= top; ++i) 
    {
		int t = lua_type(L, i);
		switch (t) 
        {
		case LUA_TSTRING:
			{
				printf("'%s' \r\n", lua_tostring(L, i));
			}
			break;
		case LUA_TBOOLEAN:
			{
				printf(lua_toboolean(L, i) ? "true \r\n" : "false \r\n");
			}break;
		case LUA_TNUMBER:
			{
				printf("%g \r\n", lua_tonumber(L, i));
			}
			break;
		default:
			{
				printf("%s \r\n", lua_typename(L, t));
			}
			break;
		}
	}
	printf("\n********end dump lua stack********\r\n");
}

LuaFunReturn CScriptLua::CallLuaFun(int nargsSize, int nResultNum, ...)
{
	LuaFunReturn RetVec;
	va_list ap;
	va_start(ap, nResultNum);
	uint8 nParamsize = nargsSize;
    
	va_end(ap);
	// 由于函数参数调用顺序是右至左，这里栈里的参数需要做一个反序
	lua_insert(pL, 1);
    nParamsize--;
	for (uint8 i = 0; i < nParamsize - 1; ++i)
	{
		lua_insert(pL, 2 + i);
	}

    lua_getglobal(pL, "Error");
    lua_insert(pL, 1);
    // lua_pcall 第四参数使用备注：如果有，必须比函数和参数先入栈
	uint8 ret = lua_pcall(pL, nParamsize, nResultNum, 1);
	uint8 pnum = lua_gettop(pL);

	// if (ret == LUA_ERRRUN)
	// {
    //    // luaL_traceback(pL, pL, NULL, 3);
    //     //StackDump(pL);
    //     String strError = lua_tostring(pL, 2);
    //     lua_pop(pL,2);
	// 	sprintf(g_szInfo,"%s", strError.c_str());
	// 	REPORT(g_szInfo);
	// 	return RetVec;
	// }

	// 由于C++，没有talbe，如果要获取lua中的table，必须对此做规则限制
	// 这里限制lua中函数，如果返回table，只能返回一个，并且只获取table中的number值
	if (pnum == 1 && lua_type(pL, 1) == LUA_TTABLE)
	{
		lua_pushnil(pL);
		uint8 num = 0;
		while (lua_next(pL, 1) != 0)
		{
			if (num >= 100)
			{
				REPORT("table返回值过大\r\n");
				return RetVec;
			}
			num++;
			//stackDump(pL);
			RetVec.push_back((int32)lua_tointeger(pL, -2));
			lua_pushnil(pL);
			uint8 num2 = 0;
			while (lua_next(pL, 3) != 0)
			{
				if (num2 >= 100)
				{
					REPORT("table返回值过大\r\n");
					return RetVec;
				}
				num2++;
				//stackDump(pL);
				if (lua_type(pL, -1)  == LUA_TNUMBER)
				{
					RetVec.push_back((int32)lua_tointeger(pL, -1));
				}
				lua_pop(pL, 1);
			}
			lua_pop(pL, 1);
		}
	}
	else
	{
		for (uint8 i = 2; i <= nResultNum + 1; ++i)
		{
			RetVec.push_back((int32)lua_tointeger(pL, i));
		}
	}

	lua_settop(pL, 0);
	return RetVec;
}

int CScriptLua::PushFun(const String& Fun)
{
	int i = lua_getglobal(pL, Fun.c_str());
    if (i != LUA_TFUNCTION)
    {
        sprintf(g_szInfo, "脚本中没有该函数:%s", Fun.c_str());
        REPORT(g_szInfo);
        return 0;
    }
	return 1;
}

int CScriptLua::Msg_lua(CPacket& cPacket)
{
    uint16 op = cPacket.GetOpcode();
    LuaFunReturn result;
    void* ptr = (void*)&cPacket;
    
    //luafun("lua_MsgHandle");
    //lua_pushinteger(pL, op);
    //lua_pushlightuserdata(pL, ptr);
    //lua_pushinteger(pL, cPacket.GetSocketID());
    //lua_pcall(pL, 3, 1, 0);
    //lua_tointeger(pL, 1);
    //lua_pop(pL, 1);
    result = CallLuaFun(4, 1, luafun("lua_MsgHandle"),luapush(op),luapush(ptr), luapush(cPacket.GetSocketID()));
    if (result.empty())
    {
        return -1;
    }
    else
    {
        return result[0];
    }
}

//********************************************************************
//函数功能: errorlog
//lua第一参数: str
//lua第二参数: str
//lua第三参数: str
//lua第三参数: str
//返回说明: 
//备注说明: lua用的错误日志
//********************************************************************
int CScriptLua::Errorlog(lua_State* pl)
{
    String strDes = "";
    //String strFile = "";
    //String strFunc = "";
    //int    nLine   = 0;

    {
        SaveReturn(pl, 1, 0, 0);
        //SaveLuaStack save(pl, 1, 0);
        strDes = lua_tostring(pl, -1);
        lua_pop(pl, 1);
        //strFile = lua_tostring(pl, -1);
        //lua_pop(pl, 1);
        //strFunc = lua_tostring(pl, -1);
        //lua_pop(pl, 1);
        //nLine = lua_tointeger(pl, -1);
        //lua_pop(pl, 1);
    }

	REPORT(strDes.c_str());
    return 0;
}

//********************************************************************
//函数功能: Loglog
//lua第一参数: str
//lua第二参数: str
//lua第三参数: str
//lua第三参数: str
//返回说明: 
//备注说明: lua用的日志记录
//********************************************************************
int CScriptLua::Loglog(lua_State* pl)
{
    String strDes = "";
    //String strFile = "";
    //String strFunc = "";
    //int    nLine   = 0;

    {
        SaveReturn(pl, 1, 0, 0);
        //SaveLuaStack save(pl, 1, 0);
        strDes = lua_tostring(pl, -1);
        lua_pop(pl, 1);
        //strFile = lua_tostring(pl, -1);
        //lua_pop(pl, 1);
        //strFunc = lua_tostring(pl, -1);
        //lua_pop(pl, 1);
        //nLine = lua_tointeger(pl, -1);
        //lua_pop(pl, 1);
    }

	LOGI(strDes.c_str());
    return 0;
}
//********************************************************************
//函数功能: GetDebug
//lua第一参数: 无参数 
//返回说明: 
//备注说明: lua用的输出日志标志
//********************************************************************
int CScriptLua::IsWriteLog(lua_State* pL)
{
    lua_pushinteger(pL, s_nWriteLog);
    return 1;
}

//********************************************************************
//函数功能: 解析消息包，并封装成table
//lua第一参数: 解析顺序的table
//lua第二参数: cPacket 消息包指针
//返回说明: 
//备注说明: 标准的c->lua 接口函数，返回值lua返回值个数(栈个数)
//********************************************************************
int CScriptLua::ParserPacketForLuaDefine(lua_State* pl)
{
    PacketVec vec;
    CPacket* cPacket = NULL;
    vec.reserve(20);

    {
        //获取packet数据指针，并且获得lua中的解析方式
        SaveReturn(pl, 2, 0, 0);
       //SaveLuaStack save(pl, 2, 0);
        cPacket = (CPacket*)lua_touserdata(pl,-1);
        lua_pop(pl, 1);
        WhileTable(pl, 1, vec); // “解析”lua中的解析方式
        lua_pop(pl, 1);
    }

    if (cPacket == NULL)
    {
        REPORT("协议未解析成功");
        return 0;
    }

    {
        //按照lua中定义的解析方式对packet进行解析、封装
        SaveReturn(pl, 0, 1, 0);
        //SaveLuaStack save(pl, 0, 1);
        SerializePacketToLua(pl, cPacket, vec, 1, 0, vec.size() - 1, 1);
    }
    
    // 这个处理是让lua中方便的使用，不需要再多访问一次[1]
    lua_pushinteger(pl, 1);
    lua_gettable(pl, 1);
    lua_insert(pl, 1);
    lua_pop(pl, 1);
    return 1;
}

void CScriptLua::WhileTable(lua_State* pl, int stackBegin, PacketVec& vec)
{
    lua_pushnil(pl);
    while(lua_next(pl, stackBegin) != 0)
    {
        if (lua_type(pl, stackBegin + 2) == LUA_TNUMBER)
        {
            int ntype = (int)lua_tointeger(pl,stackBegin + 2);
            vec.push_back(ntype);
        }
        else if (lua_type(pl, stackBegin+2) == LUA_TTABLE)
        {
            lua_len(pl, stackBegin+2);
            int num = (int)lua_tointeger(pl, stackBegin+3);
            lua_pop(pl, 1);
            vec.push_back(num);
            vec.push_back(LUA_TABLE);
            WhileTable(pl, stackBegin + 2, vec);
        }
        lua_pop(pl, 1);
    }
}

//********************************************************************
//函数功能: 递归解析消息包，组装成table
//第一参数: pl      lua指针
//第二参数: cPacket 消息包
//第三参数: vec     解析内容
//第四参数: nSize   消息包个数
//第五参数: nBegin  子包字段开始位置
//第六参数: nEnd    子包字段结束位置
//第七参数: nTalbe  包在栈中的位置
//返回说明: 
//备注说明: 
//********************************************************************
int CScriptLua::SerializePacketToLua(lua_State* pl, CPacket* cPacket, PacketVec& vec, 
                            int nSize, int nBegin, int nEnd, int nTalbe)
{
    if (nBegin > nEnd)
    {
        return 0;
    }
    lua_createtable(pl, 0, nSize);//lua_newtable(pL);

    for ( int i  = 0; i < nSize; ++i)
    {
        lua_pushinteger(pl, i+1);
        lua_createtable(pl, 0, nEnd - nBegin + 1);//lua_newtable(pL);
        int nindex = 1;
        for (int j = nBegin; j <= nEnd; ++j, ++nindex)
        {
            if (j + 2 < nEnd && vec[j + 2] == LUA_TABLE)
            {
                lua_pushinteger(pl, nindex);
                uint16 s = cPacket->ReadUint16();        // 这里限制死了，如果是动态的元素个数必须用uint16
                j = SerializePacketToLua(pl, cPacket, vec, s, j+3,j+2+vec[j+1], nTalbe + 4);
            }
            else
            {
                switch (vec[j])
                {
                case LUA_INT8:
                    lua_pushinteger(pl, nindex);
                    lua_pushinteger(pl, cPacket->ReadInt8());
                    break;
                case LUA_INT16:
                    lua_pushinteger(pl, nindex);
                    lua_pushinteger(pl, cPacket->ReadInt16());
                    break;
                case LUA_INT32:
                    lua_pushinteger(pl, nindex);
                    lua_pushinteger(pl, cPacket->ReadInt32());
                    break;
                case LUA_UINT8:
                    lua_pushinteger(pl, nindex);
                    lua_pushinteger(pl, cPacket->ReadUint8());
                    break;
                case LUA_UINT16:
                    lua_pushinteger(pl, nindex);
                    lua_pushinteger(pl, cPacket->ReadUint16());
                    break;
                case LUA_UINT32:
                    lua_pushinteger(pl, nindex);
                    lua_pushinteger(pl, cPacket->ReadUint32());
					break;
				case LUA_INT64:
					lua_pushinteger(pl, nindex);
					lua_pushinteger(pl, cPacket->ReadInt64());
					break;
                case LUA_FLOAT:
					lua_pushinteger(pl, nindex);
                    lua_pushnumber(pl, cPacket->ReadFloat());
                    break;
                case LUA_STRING:
                    lua_pushinteger(pl, nindex);
                    lua_pushstring(pl, cPacket->ReadString().c_str());
                    break;
				case LUA_DOUBLE:
					lua_pushinteger(pl, nindex);
					lua_pushnumber(pl, cPacket->ReadDouble());
					break;
                default:
                    continue;
                }
            }
            lua_settable(pl, nTalbe + 2);
        }
        lua_settable(pl ,nTalbe);
    }

   return nEnd;
}

//********************************************************************
//函数功能: 解析lua数据table，封装成数据包并且压入消息队列, 测试消息
//lua第一参数: table    发送数据table
//lua第二参数: Procotol 协议编号
//lua第三参数: sockid   

//返回说明: 
//备注说明: 标准的c->lua 接口函数，返回值lua返回值个数(栈个数)
//********************************************************************
int CScriptLua::TestMsg(lua_State* pl)
{
    uint32 nProtocol = 0;
    uint32 nSocketID = 0;
    uint32 nType     = 0;
	
    {
        //SaveLuaStack save(pl, 3, 1);
        nSocketID   = (uint32)lua_tointeger(pl, -1);
        if (nSocketID == 0)
        {
            lua_pop(pl, 3);
            return 0;
        }
        nProtocol   = (uint32)lua_tointeger(pl, -2);
        lua_pop(pl, 2);
    }

    CPacket cp(nProtocol);
    {
        SaveReturn(pl, 1, 0, 0);
        //SaveLuaStack save(pl, 1, 0);
        if (!ParserTalbeToPacket(pl, cp, 1))
        {
            sprintf(g_szInfo,"协议:[%d] 报错", nProtocol);
            REPORT(g_szInfo);
        }
        lua_pop(pl, 1);
    }

    cp.SetSocketID(nSocketID);
    sMsgQueueVec.PushPacket(cp);
	
    return 0;
}


//********************************************************************
//函数功能:Lua中休眠线程
//lua第一参数: 休眠时长 (单位毫秒)

//返回说明: 
//备注说明: 标准的c->lua 接口函数，返回值lua返回值个数(栈个数)
//********************************************************************
int CScriptLua::SleepLua(lua_State* pl)
{
    uint32 nMilliseconds = 0;
    {
        //SaveLuaStack save(pl, 1, 1);
		nMilliseconds = (uint32)lua_tointeger(pl, -1);
        if (nMilliseconds == 0)
        {
            lua_pop(pl, 1);
            return 1;
        }
    }
#ifdef WIN32
	Sleep(nMilliseconds);
#else
	usleep(nMilliseconds * 1000);
#endif
    return 0;
}

//********************************************************************
//函数功能: lua使用 获取指定SocketID的IP
//lua第一参数: SocketID  客户端SocketID

//返回说明: 
//备注说明: 标准的c->lua 接口函数，返回值lua返回值个数(栈个数)
//********************************************************************
int CScriptLua::GetClientIP(lua_State* pl)
{
    uint32 nSocketID = 0;
    {
        SaveReturn(pl, 1, 0, 0);
        nSocketID = (uint32)lua_tointeger(pl, -1);
        lua_pop(pl, 1);
    }

    String strIP = sNetServer.GetClientAddress(nSocketID);
    lua_pushstring(pl, strIP.c_str());
    return 1;
}

//********************************************************************
//函数功能: lua使用 获取指定SocketID的IP
//lua第一参数: SocketID  服务端SocketID

//返回说明: 
//备注说明: 标准的c->lua 接口函数，返回值lua返回值个数(栈个数)
//********************************************************************
int CScriptLua::GetServerIP(lua_State* pl)
{
	uint32 nSocketID = 0;
	{
		SaveReturn(pl, 1, 0, 0);
		nSocketID = (uint32)lua_tointeger(pl, -1);
		lua_pop(pl, 1);
	}

	String strIP = sNetClient.GetServerAddress(nSocketID);
	lua_pushstring(pl, strIP.c_str());
	return 1;
}

int CScriptLua::StartService(lua_State* pl)
{
	sNetServer.StartService();
	return 0;
}


//********************************************************************
//函数功能: lua使用 启动服务端通信模块
//返回说明: 
//备注说明: 标准的c->lua 接口函数，返回值lua返回值个数(栈个数)
//********************************************************************
int CScriptLua::ServerStartup(lua_State* pl)
{
	uint32 nMaxConnecttion = 0;
	uint16 nPort = 0;
	String strPassword = "";
	{
		SaveReturn(pl, 3, 0, 0);
		strPassword = lua_tostring(pl, -1);
		nPort = (uint16)lua_tointeger(pl, -2);
		nMaxConnecttion = (uint32)lua_tointeger(pl, -3);
		lua_pop(pl, 3);
	}

	uint8 nRet = sNetServer.Startup(nMaxConnecttion, nPort, strPassword);
	lua_pushinteger(pl, nRet);
	return 1;
}

//********************************************************************
//函数功能: lua使用 释放服务器通信模块的资源
//返回说明: 
//备注说明: 标准的c->lua 接口函数，返回值lua返回值个数(栈个数)
//********************************************************************
int CScriptLua::ServerShutdown(lua_State* pl)
{
	sNetServer.Shutdown();
	return 0;
}

//********************************************************************
//函数功能: lua使用 关闭指定SocketID连接
//返回说明: 
//备注说明: 标准的c->lua 接口函数，返回值lua返回值个数(栈个数)
//********************************************************************
int CScriptLua::ServerCloseSocket(lua_State* pl)
{
	uint32 nSocketID = 0;
	{
		SaveReturn(pl, 1, 0, 0);
		nSocketID = (uint32)lua_tointeger(pl, -1);
		lua_pop(pl, 1);
	}

	sNetServer.CloseSocket(nSocketID);
	return 0;
}

//********************************************************************
//函数功能: lua使用 连接服务器
//返回说明: 
//备注说明: 标准的c->lua 接口函数，返回值lua返回值个数(栈个数)
//********************************************************************
int CScriptLua::ClientConnect(lua_State* pl)
{
	String strIP = "";
	uint16 nPort = 0;
	String strPassword = "";
	String strCallback = "";
	{
		SaveReturn(pl, 4, 0, 0);
		strCallback = lua_tostring(pl, -1);
		strPassword = lua_tostring(pl, -2);
		nPort = (uint16)lua_tointeger(pl, -3);
		strIP = lua_tostring(pl, -4);
		lua_pop(pl, 4);
	}

	uint32 nRet = sNetClient.Connect(strIP, nPort, strPassword, strCallback);
	lua_pushinteger(pl, nRet);
	return 1;
}

//********************************************************************
//函数功能: lua使用 释放指定SocketID连接的资源
//返回说明: 
//备注说明: 标准的c->lua 接口函数，返回值lua返回值个数(栈个数)
//********************************************************************
int CScriptLua::ClientShutdown(lua_State* pl)
{
	uint32 nSocketID = 0;
	{
		SaveReturn(pl, 1, 0, 0);
		nSocketID = (uint32)lua_tointeger(pl, -1);
		lua_pop(pl, 1);
	}

	sNetClient.Shutdown(nSocketID);
	return 0;
}

//********************************************************************
//函数功能: lua使用 关闭指定SocketID连接
//返回说明: 
//备注说明: 标准的c->lua 接口函数，返回值lua返回值个数(栈个数)
//********************************************************************
int CScriptLua::ClientCloseSocket(lua_State* pl)
{
	uint32 nSocketID = 0;
	{
		SaveReturn(pl, 1, 0, 0);
		nSocketID = (uint32)lua_tointeger(pl, -1);
		lua_pop(pl, 1);
	}

	sNetClient.CloseSocket(nSocketID);
	return 0;
}

//********************************************************************
//函数功能: lua使用 获取指定SocketID的IP
//lua第一参数: SocketID  客户端SocketID

//返回说明: 
//备注说明: 标准的c->lua 接口函数，返回值lua返回值个数(栈个数)
//********************************************************************
int CScriptLua::IsLeaveSave(lua_State* pL)
{
    lua_pushinteger(pL, s_nLeaveSave);
    return 1;
}


//********************************************************************
//函数功能: 解析lua数据table，封装成数据包并且发送Client
//lua第一参数: table    发送数据table
//lua第二参数: Procotol 协议编号
//lua第三参数: sockid   

//返回说明: 
//备注说明: 标准的c->lua 接口函数，返回值lua返回值个数(栈个数)
//********************************************************************
int CScriptLua::SendMsgToClient(lua_State* pl)
{
    uint32 nProtocol = 0;
    uint32 nSocketID = 0;
   
    {
        //SaveLuaStack save(pl, 3, 1);
        nSocketID   = (uint32)lua_tointeger(pl, -1);
        if (nSocketID == 0)
        {
            lua_pop(pl, 3);
            return 0;
        }
        nProtocol   = (uint32)lua_tointeger(pl, -2);
        lua_pop(pl, 2);
    }

    CPacket cp(nProtocol);
    {
        SaveReturn(pl, 1, 0, 0);
        //SaveLuaStack save(pl, 1, 0);
        if (!ParserTalbeToPacket(pl, cp, 1))
        {
            sprintf(g_szInfo,"发送给客户端协议:[%d] 报错", nProtocol);
            REPORT(g_szInfo);
        }
        lua_pop(pl, 1);
    }

    sNetServer.SendToClient(cp, nSocketID);
    return 0;
}

//********************************************************************
//函数功能: 解析lua数据table，封装成数据包并且发送Server
//lua第一参数: table    发送数据table
//lua第二参数: Procotol 协议编号
//lua第三参数: sockid   

//返回说明: 
//备注说明: 标准的c->lua 接口函数，返回值lua返回值个数(栈个数)
//********************************************************************
int CScriptLua::SendMsgToServer(lua_State* pl)
{
	uint32 nProtocol = 0;
	uint32 nSocketID = 0;

	{
		nSocketID = (uint32)lua_tointeger(pl, -1);
		if (nSocketID == 0)
		{
			lua_pop(pl, 3);
			return 0;
		}
		nProtocol = (uint32)lua_tointeger(pl, -2);
		lua_pop(pl, 2);
	}

	CPacket cp(nProtocol);
	{
		SaveReturn(pl, 1, 0, 0);
		if (!ParserTalbeToPacket(pl, cp, 1))
		{
			sprintf(g_szInfo, "发送给服务器协议:[%d] 报错", nProtocol);
			REPORT(g_szInfo);
		}
		lua_pop(pl, 1);
	}

	sNetClient.SendToServer(cp, nSocketID);
	return 0;
}

//********************************************************************
//函数功能: 发送日志到日志服务器
//返回说明: 
//备注说明: 标准的c->lua 接口函数，返回值lua返回值个数(栈个数)
//********************************************************************
int CScriptLua::SendHttpRequest(lua_State* pl)
{
	String strURL = "";
	String strData = "";
	{
		SaveReturn(pl, 2, 0, 0);
		strData = lua_tostring(pl, -1);
		strURL = lua_tostring(pl, -2);
		lua_pop(pl, 2);
	}

	if (strURL.length() > 0)
	{
		sHttpClient.Push(strURL, strData);
	}
	return 0;
}


int CScriptLua::Base64Encode(lua_State* pl)
{
	String strData;
	{
		SaveReturn(pl, 1, 0, 0);
		strData = lua_tostring(pl, -1);
		lua_pop(pl, 1);
	}

	char* pData = CBase64::OpenSSLEncode(strData.c_str(), strData.length(), false);

	String strReturn = pData;
	delete[] pData;
	lua_pushstring(pl, strReturn.c_str());
	return 1;
}

int CScriptLua::Base64Decode(lua_State* pl)
{
	String strData;
	{
		SaveReturn(pl, 1, 0, 0);
		strData = lua_tostring(pl, -1);
		lua_pop(pl, 1);
	}

	uint32 nDataLen = strData.length();
	char* pData = CBase64::OpenSSLDecode((char*)strData.c_str(), nDataLen, false);

	String strReturn = pData;
	delete[] pData;
	lua_pushstring(pl, strReturn.c_str());
	return 1;
}

int CScriptLua::StringToTime(lua_State* pl)
{
    String strTime;
    {
        SaveReturn(pl, 1, 0, 0);
        strTime = lua_tostring(pl, -1);
        lua_pop(pl, 1);
    }
    uint32 nTime = CTimeTools::GetStringToTime(strTime.c_str());
	lua_pushinteger(pl, nTime);
    return 1;
}


int CScriptLua::GetTimeToMillisecond(lua_State* pl)
{
	uint64 nTime = CTimeTools::GetSystemTimeToMillisecond();
	lua_pushinteger(pl, nTime);
	return 1;
}

//********************************************************************
//函数功能: lua使用, 注册计时器
//lua第一参数: table    注册计时器的数据table
//lua第二参数: Procotol 协议编号
//lua第三参数: 间隔时间 单位毫秒   
//lua第四参数: 重复次数 -1表示无限次  

//返回说明: 
//备注说明: 标准的c->lua 接口函数，返回值lua返回值个数(栈个数)
//********************************************************************
int CScriptLua::RegistryTimer(lua_State* pl)
{
    uint32 nProtocol = 0;
    uint32 nInterval = 0;
    int32 iCount = 0;

    {
        SaveReturn(pl, 4, 1, 0);
        nInterval   = (uint32)lua_tointeger(pl, -1);
        iCount      = (int32)lua_tointeger(pl, -2);
        nProtocol   = (uint32)lua_tointeger(pl, -3);
        lua_pop(pl, 3);
    }

    CPacket cp(nProtocol);
    {
        SaveReturn(pl, 1, 0, 0);
        if (lua_istable(pl, 1))
        {
            if (!ParserTalbeToPacket(pl, cp, 1))
            {
                sprintf(g_szInfo,"注册计时器时, 协议:[%d] 报错", nProtocol);
                REPORT(g_szInfo);
            }
        }
        lua_pop(pl, 1);
    }

    if (0 == iCount)
    {
        iCount = 1;
    }
    int iTimerID = sTimerMgr.SetTimer(nInterval, cp, iCount);
    lua_pushinteger(pl, iTimerID);
    return 1;
}
//********************************************************************
//函数功能: lua使用, 注销计时器
//函数作者: Herry 2015-9-28
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
int CScriptLua::CancelTimer(lua_State* pl)
{
    uint32 nTimerID = 0;

    {
        SaveReturn(pl, 1, 0, 0);
        nTimerID = (uint32)lua_tointeger(pl, -1);
        lua_pop(pl, 1);
    }

    sTimerMgr.DestroyTimer(nTimerID);
    return 0;
}



bool CScriptLua::ParserTalbeToPacket(lua_State* pl, CPacket& cPacket, int nTalbe)
{
#define CHECK_TYPE(stack,type) if (lua_type(pl, -1) != type){ \
    sprintf(g_szInfo, "解析的字段不匹配，type：%d, lua_type(pl, -1):%d", type, lua_type(pl, -1));\
    REPORT(g_szInfo);\
    return false;\
    }
    if (!lua_istable(pl, nTalbe))
    {
        sprintf(g_szInfo,"异常:组装消息包时，堆栈中的数据不是table,type:[%d]", lua_type(pl, nTalbe));
        REPORT(g_szInfo);
        return false;
    }
    
    lua_pushnil(pl);
    while (lua_next(pl, nTalbe))
    {
        int i = lua_type(pl, -1);
        if (i != LUA_TTABLE)
        {
            sprintf(g_szInfo, "解析的字段类型不是一个LUA_TTABLE，type：%d", i);
            REPORT(g_szInfo);
            return false;
        }
        
        lua_rawgeti(pl, -1, 1);
        i = lua_type(pl, -1);
        if ( i != LUA_TNUMBER)
        {
            sprintf(g_szInfo, "1解析的字段类型不是一个LUA_TNUMBER，type：%d", i);
            REPORT(g_szInfo);
            return false;
        }
        LuaField type = (LuaField)lua_tointeger(pl, -1);
        lua_pop(pl, 1);

        lua_rawgeti(pl, -1, 2); 
        switch (type)
        {
        case LUA_INT8:
            CHECK_TYPE(-1, LUA_TNUMBER)
            cPacket.WriteInt8((int8)lua_tointeger(pl, -1));
            break;
        case LUA_INT16:
            CHECK_TYPE(-1, LUA_TNUMBER)
            cPacket.WriteInt16((int16)lua_tointeger(pl, -1));
            break;
        case LUA_INT32:
            CHECK_TYPE(-1, LUA_TNUMBER)
            cPacket.WriteInt32((int32)lua_tointeger(pl, -1));
            break;
        case LUA_UINT8:
            CHECK_TYPE(-1, LUA_TNUMBER)
            cPacket.WriteUint8((uint8)lua_tointeger(pl, -1));
            break;
        case LUA_UINT16:
            CHECK_TYPE(-1, LUA_TNUMBER)
            cPacket.WriteUint16((uint16)lua_tointeger(pl, -1));
            break;
        case LUA_UINT32:
            CHECK_TYPE(-1, LUA_TNUMBER)
            cPacket.WriteUint32((uint32)lua_tointeger(pl, -1));
			break;
		case LUA_INT64:
			CHECK_TYPE(-1, LUA_TNUMBER)
				cPacket.WriteInt64((int64)lua_tointeger(pl, -1));
			break;
        case LUA_FLOAT:
            CHECK_TYPE(-1, LUA_TNUMBER)
            cPacket.WriteFloat((float)lua_tonumber(pl, -1));
            break;
		case LUA_DOUBLE:
			CHECK_TYPE(-1, LUA_TNUMBER)
			cPacket.WriteDouble((double)lua_tonumber(pl, -1));
			break;
        case LUA_STRING:
            CHECK_TYPE(-1, LUA_TSTRING)
            cPacket.WriteString(lua_tostring(pl, -1));
            break;
        case LUA_TABLE:
            CHECK_TYPE(-1, LUA_TTABLE)
            lua_len(pl, -1);
            uint16 nSize = (uint16)lua_tointeger(pl, -1);
            cPacket.WriteUint16(nSize);
            lua_pop(pl, 1);
            lua_pushnil(pl);
            while (lua_next(pl, -2))
            {
                if (!ParserTalbeToPacket(pl, cPacket, nTalbe + 5))
                {
                    return false;
                }
                 lua_pop(pl, 1);
            }
           // lua_stackdump(pl);
            break;
        }
        lua_pop(pl, 2);
    }

    return true;
}

//********************************************************************
//函数功能: 获取Lua配置数据
//第一参数: 
//返回说明: 
//备注说明: 只支持读取整型类型字段
//********************************************************************
int CScriptLua::GetGlobal(const String& strName)
{
    lua_getglobal(pL, strName.c_str());
    int iValue = (int)lua_tonumber(pL, -1);
    lua_settop(pL, 0);
    return iValue;
}
