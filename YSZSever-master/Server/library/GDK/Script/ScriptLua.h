/*****************************************************************************
文 件 名:  ScriptLua.cpp
作    者:     
完成日期:  2015-4-14
说明信息:  lua文件加载执行
		   c++函数的注册机制
-----------------------------------------------------------------------------------------------------------------------------------
-注意: 调用Reg_CFun_lua和Reg_ObjCFun_lua注册函数时，第一个参数必须转换成函数所在的最后一个子类类型(可以是虚函数)，不然linux下编译不通过。
-原因: g++ 和 VS 的差异，编译期间，对于模板参数Func 传入类型 class::*func VS会直接转换成class::*func，无论该类中是否有func函数。
-如果: class中没有func函数，g++会找class的父类中是否有，直到找到后，将参数转换成 baseclass::*func，dispatch的时候然后悲剧就发生了...  
-所以: 注册类的成员函数时，必须保证第一个参数转换成函数所在的最后一个子类的类类型(注册函数可以是虚函数)
-----------------------------------------------------------------------------------------------------------------------------------
*****************************************************************************/
#pragma once
#include "Define.h"

#define luafun(fun) sScriptLua.PushFun(fun)
#define luapush(P) sScriptLua.Param(P)

#ifndef DEBUG 
#define lua_stackdump(pl) sScriptLua.StackDump(pl)
#else
#define lua_stackdump(pl)
#endif 

typedef std::vector<int32> LuaFunReturn;
typedef std::vector<int> PacketVec;



extern "C"
{
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
};

template<typename CT, typename Func>
class CCallRegister;

template<typename CT, typename Func>
class CCallDispatcher;

template<typename CT, typename RetV>
class CCallHelper;

// 类型特化 
template<typename T>
struct TypeHelper{};

#define lua_pushfloat(pL, P) do {lua_pushnumber(pL,P);return 1;}while(0);
#define lua_pushint(pL, P) do {lua_pushinteger(pL,P);return 1;}while(0);
#define lua_pushstr(pL, P) do {lua_pushstring(pL, P);return 1;}while(0);
#define lua_pushbool(pL, P) do {lua_pushboolean(pL, P);return 1;}while(0);
#define lua_pushprt(pL, P) do {lua_pushlightuserdata(pL, P);return 1;}while(0);
template<>struct TypeHelper<float>		{static int8 PushParameter(lua_State * pL, float p)		    {lua_pushfloat(pL,p)}};
template<>struct TypeHelper<uint64>		{static int8 PushParameter(lua_State * pL, uint64 p)		{lua_pushint(pL,p)}};
template<>struct TypeHelper<uint32>		{static int8 PushParameter(lua_State * pL, uint32 p)		{lua_pushint(pL,p)}};
template<>struct TypeHelper<uint16>		{static int8 PushParameter(lua_State * pL, uint16 p)		{lua_pushint(pL,p)}};
template<>struct TypeHelper<uint8>		{static int8 PushParameter(lua_State * pL, uint8 p)			{lua_pushint(pL,p)}};
template<>struct TypeHelper<int32>		{static int8 PushParameter(lua_State * pL, int p)			{lua_pushint(pL,p)}};
template<>struct TypeHelper<String>		{static int8 PushParameter(lua_State * pL, String p)		{lua_pushstr(pL,p.c_str())}};
template<>struct TypeHelper<const char*>{static int8 PushParameter(lua_State * pL, const char* p)	{lua_pushstr(pL,p)}};
template<>struct TypeHelper<bool>		{static int8 PushParameter(lua_State * pL, bool p)			{lua_pushbool(pL,p)}};
template<>struct TypeHelper<void*>      {static int8 PushParameter(lua_State * pL, void* p)			{lua_pushprt(pL,p)}};

enum LuaField
{
    LUA_INT8        = 1,
    LUA_INT16       = 2,
    LUA_INT32       = 3,
    LUA_UINT8       = 4,
    LUA_UINT16      = 5,
    LUA_UINT32      = 6,
    LUA_STRING      = 7,
    LUA_FLOAT       = 8,
    LUA_TABLE       = 9,
	LUA_DOUBLE      = 10,
	LUA_INT64		= 11,
};
class SaveLuaStack;
#define SaveReturn(pl, SaveB, SaveE, ErrRet) SaveLuaStack save(pl, SaveB, SaveE); if (pl == NULL) return ErrRet;
class CScriptLua
{

public:
	CScriptLua();
	~CScriptLua();
	static CScriptLua& Getinstance(){static CScriptLua obj;return obj;}

	int Initlua(const String& strLuaPath, uint16 nServerID);

	int  LoadFile(const String& strLoadFile = "all");
    int  GetGlobal(const String& strName);

public:
	/* 
	 参数1:返回值个数. 参数2::调用函数名、参数3:调用参数1...参数N:调用参数N (调用参数用lua_pushParam，最后调用函数名用lua_callFun)
	 返回值全部在LuaFunReturn中，lua函数返回顺序和LuaFunReturn插入顺序依次对应(！！！！！！暂时只提供返回整形只！！！)
	 */
	LuaFunReturn CallLuaFun(int nargsSize, int nResultNum, ...);
	int PushFun(const String& Fun );
	template<typename P> int Param(P p);


    // 消息发送给lua并打包成table作为参数
    int Msg_lua(CPacket& cPacket);

    // GC
    void DoGC() { lua_gc(pL, LUA_GCCOLLECT, 0); }
private:

	// 网络通信模块, 解析, 组装, 启动, 关闭, 发送等
	static int  ParserPacketForLuaDefine(lua_State* pl);// lua使用 将消息包解析并封装成table
	static bool ParserTalbeToPacket(lua_State* pl, CPacket& cPacket, int nTalbe);
    static void WhileTable(lua_State* pl, int stackBegin, PacketVec& vec);
    static int  SerializePacketToLua(lua_State* pl, CPacket* cPacket, PacketVec& vec, int nSize, int nBegin, int nEnd, int nTalbe);
    static int	SendMsgToClient(lua_State* pl);		// lua使用 将数据封装成消息包并发送给Client
	static int	SendMsgToServer(lua_State* pl);		// lua使用 将数据封装成消息包并发送给Server
	static int	SendHttpRequest(lua_State* pl);		// lua使用 发送http请求
	static int	GetClientIP(lua_State* pl);			// lua使用 获取指定SocketID的IP
	static int	GetServerIP(lua_State* pl);			// lua使用 获取指定SocketID的IP
	static int	StartService(lua_State* pl);		// lua使用 开启网络服务
	
	static int	ServerStartup(lua_State* pl);		// lua使用 启动服务端通信模块
	static int	ServerShutdown(lua_State* pl);		// lua使用 关闭服务端通信模块
	static int	ServerCloseSocket(lua_State* pl);	// lua使用 关闭指定SocketID连接
	static int	ClientConnect(lua_State* pl);		// lua使用 启动客户端通信模块
	static int	ClientShutdown(lua_State* pl);		// lua使用 关闭客户端通信模块
	static int	ClientCloseSocket(lua_State* pl);	// lua使用 关闭指定SocketID连接
	static int	Base64Encode(lua_State* pl);		// lua使用 使用Base64算法编码
	static int	Base64Decode(lua_State* pl);		// lua使用 使用Base64算法解码

	// 计时器, 线程休眠, 辅助功能等
    static int	StringToTime(lua_State* pl);		// lua使用 字符串类型的时间, 转换成对应的系统时间
	static int  GetTimeToMillisecond(lua_State* pl);// lua使用 获取当前毫秒级别的时间戳
    static int	RegistryTimer(lua_State* pl);		// lua使用 注册计时器
    static int	CancelTimer(lua_State* pl);			// lua使用 注销计时器
    static int	TestMsg(lua_State* pl);				// lua使用 将数据封装成消息包并压入消息队列
    static int	SleepLua(lua_State* pl);			// lua使用 lua中线程休眠, 单位毫秒
    static int	IsLeaveSave(lua_State* pl);			// lua使用 获取是否离线回存
   
    // log
    static int  Errorlog(lua_State* pl);
    static int  Loglog(lua_State* pl);
    static int  IsWriteLog(lua_State* pl);

public:
    static void SetWriteLog(uint8 nWriteLog)   { s_nWriteLog = nWriteLog;   }
    static void SetLeaveSave(uint8 nLeaveSave) { s_nLeaveSave = nLeaveSave; }

private:
	// 查看lua堆栈中的值
	void StackDump(lua_State* L);

private:
	lua_State* pL;
    String strLuaPath;
    static uint8 s_nWriteLog;
    static uint8 s_nLeaveSave;          // 是否开启离线回存 true开启
};

template<typename P>
int CScriptLua::Param(P p)
{
	int8 ii = TypeHelper<P>::PushParameter(pL, p);
	return ii;
}

// 用于包装类的地址，和成员函数指针
template<typename CT, typename Func>
struct data
{
	CT* c;
	Func f;
};

#define sScriptLua CScriptLua::Getinstance()

// 注册类
// 将C函数注册给lua用
template<typename CT, typename Func>
class CCallRegister
{
public:
	// 此函数为真正给lua用的函数
	static int Call(lua_State* pL)
	{
		/*lua_touserdata 官方注释: 如果index 处的值是一个full userdata 则返回它的块地址。
								  如果该值是个light userdata
								  则返回它的指针。否则返回NULL*/
		data<CT, Func>* fp = (data<CT, Func>*)lua_touserdata(pL, lua_upvalueindex(1));
		int result = CCallDispatcher<CT, Func>::Dispatch(fp->c, fp->f, pL);
		//result -1 参数不够，-2参数类型不对
		if (result != 0)
		{
			lua_pushinteger(pL, result);
		}
		return 1;

		/* 实验1：
		void* pf = lua_touserdata(pL, lua_upvalueindex(1));
		void* pc = lua_touserdata(pL, lua_upvalueindex(2));
		Func* func = (Func*)(pf);
		Func ff = *func;
		启用适配类，调用该函数
		return CCallDispatcher<CT, Func>::dispatch((CT*)pc, ff, pL);
		*/
	}
};

//适配函数类
// 此类只做一个中转用，将不同参数的函数适配给后面的调用者
template<typename CT, typename Func>
class CCallDispatcher
{
public:
	template<typename RetV>
	static int Dispatch(CT *c, RetV (CT::*pFunc)(), lua_State* pL)
	{
		if (lua_gettop(pL) != 0)
		{
			return -1;	// 参数个数不对
		}
		return CCallHelper<CT, RetV>::Call(c, pFunc, pL);
	}

	template<typename RetV, typename P1>
	static int Dispatch(CT *c, RetV (CT::*pFunc)(P1), lua_State* pL)
	{
		if (lua_gettop(pL) != 1)
		{
			return -1;	// 参数个数不对
		}
		return CCallHelper<CT, RetV>::Call(c, pFunc, pL);
	}

	template<typename RetV, typename P1, typename P2>
	static int Dispatch(CT *c, RetV (CT::*pFunc)(P1, P2), lua_State* pL)
	{
		int i = lua_gettop(pL);
		if (lua_gettop(pL) != 2)
		{
			return -1;	// 参数个数不对
		}
		return CCallHelper<CT, RetV>::Call(c, pFunc, pL);
	}

	template<typename RetV, typename P1, typename P2, typename P3>
	static int Dispatch(CT *c, RetV (CT::*pFunc)(P1, P2, P3), lua_State* pL)
	{
		int i = lua_gettop(pL);
		if (lua_gettop(pL) != 3)
		{
			return -1;	// 参数个数不对
		}
		return CCallHelper<CT, RetV>::Call(c, pFunc, pL);
	}

	template<typename RetV, typename P1, typename P2, typename P3, typename P4>
	static int Dispatch(CT *c, RetV (CT::*pFunc)(P1, P2, P3, P4), lua_State* pL)
	{
		int i = lua_gettop(pL);
		if (lua_gettop(pL) != 4)
		{
			return -1;	// 参数个数不对
		}
		return CCallHelper<CT, RetV>::Call(c, pFunc, pL);
	}

	template<typename RetV, typename P1, typename P2, typename P3, typename P4, typename P5>
	static int Dispatch(CT *c, RetV (CT::*pFunc)(P1, P2, P3, P4, P5), lua_State* pL)
	{
		int i = lua_gettop(pL);
		if (lua_gettop(pL) != 5)
		{
			return -1;	// 参数个数不对
		}
		return CCallHelper<CT, RetV>::Call(c, pFunc, pL);
	}
};

// 函数调用类
template<typename CT, typename RetV>
class CCallHelper
{
public:
	static int Call(CT *c, RetV (CT::*pFunc)(), lua_State* pL)
	{
		RetV ret = (c->*pFunc)();
		PushValue(pL,ret);
		return 0;
	}

	template<typename P1>
	static int Call(CT *c, RetV (CT::*pFunc)(P1), lua_State* pL)
	{
		uint8 succ = 0;
		P1 p1 = GetValue(TypeHelper<P1>(), pL, 1, succ);
		if (succ == 0 ){return -2;}
		RetV ret = (c->*pFunc)(p1);
		PushValue(pL,ret);
		return 0;
	}

	template<typename P1, typename P2>
	static int Call(CT *c, RetV (CT::*pFunc)(P1, P2), lua_State* pL)
	{
		uint8 succ = 0;
		P1 p1 = GetValue(TypeHelper<P1>(), pL, 1, succ);
		if (succ == 0 ){return -2;}
		P2 p2 = GetValue(TypeHelper<P2>(), pL, 2, succ);
		if (succ == 0 ){return -2;}
		RetV ret = (c->*pFunc)(p1,p2);
		PushValue(pL,ret);
		return 0;
	}

	template<typename P1, typename P2, typename P3>
	static int Call(CT *c, RetV (CT::*pFunc)(P1, P2, P3), lua_State* pL)
	{
		uint8 succ = 0;
		P1 p1 = GetValue(TypeHelper<P1>(), pL, 1, succ);
		if (succ == 0 ){return -2;}
		P2 p2 = GetValue(TypeHelper<P2>(), pL, 2, succ);
		if (succ == 0 ){return -2;}
		P3 p3 = GetValue(TypeHelper<P3>(), pL, 3, succ);
		if (succ == 0 ){return -2;}
		RetV ret = (c->*pFunc)(p1,p2,p3);
		PushValue(pL,ret);
		return 0;
	}

	template<typename P1, typename P2, typename P3, typename P4>
	static int Call(CT *c, RetV (CT::*pFunc)(P1, P2, P3, P4), lua_State* pL)
	{
		uint8 succ = 0;
		P1 p1 = GetValue(TypeHelper<P1>(), pL, 1, succ);
		if (succ == 0 ){return -2;}
		P2 p2 = GetValue(TypeHelper<P2>(), pL, 2, succ);
		if (succ == 0 ){return -2;}
		P3 p3 = GetValue(TypeHelper<P3>(), pL, 3, succ);
		if (succ == 0 ){return -2;}
		P4 p4 = GetValue(TypeHelper<P4>(), pL, 4, succ);
		if (succ == 0 ){return -2;}
		RetV ret = (c->*pFunc)(p1,p2,p3,p4);
		PushValue(pL,ret);
		return 0;
	}

	template<typename P1, typename P2, typename P3, typename P4, typename P5>
	static int Call(CT *c, RetV (CT::*pFunc)(P1, P2, P3, P4, P5), lua_State* pL)
	{
		uint8 succ = 0;
		P1 p1 = GetValue(TypeHelper<P1>(), pL, 1, succ);
		if (succ == 0 ){return -2;}
		P2 p2 = GetValue(TypeHelper<P2>(), pL, 2, succ);
		if (succ == 0 ){return -2;}
		P3 p3 = GetValue(TypeHelper<P3>(), pL, 3, succ);
		if (succ == 0 ){return -2;}
		P4 p4 = GetValue(TypeHelper<P4>(), pL, 4, succ);
		if (succ == 0 ){return -2;}
		P5 p5 = GetValue(TypeHelper<P5>(), pL, 5, succ);
		if (succ == 0 ){return -2;}
		RetV ret = (c->*pFunc)(p1,p2,p3,p4,p5);
		PushValue(pL,ret);
		return 0;
	}
};

// 模板特化，专门针对没有返回值的函数调用
template<typename CT>
class CCallHelper<CT, void>
{
public:
	static int Call(CT *c, void (CT::*pFunc)(), lua_State* pL)
	{
		(c->*pFunc)();
		return 0;
	}

	template<typename P1>
	static int Call(CT *c, void (CT::*pFunc)(P1), lua_State* pL)
	{
		uint8 succ = 0;
		P1 p1 = GetValue(TypeHelper<P1>(), pL, 1, succ);
		if (succ == 0 ){return -2;}
		(c->*pFunc)(p1);
		return 0;
	}

	template<typename P1, typename P2>
	static int Call(CT *c, void (CT::*pFunc)(P1, P2), lua_State* pL)
	{
		uint8 succ = 0;
		P1 p1 = GetValue(TypeHelper<P1>(), pL, 1, succ);
		if (succ == 0 ){return -2;}
		P2 p2 = GetValue(TypeHelper<P2>(), pL, 2, succ);
		if (succ == 0 ){return -2;}
		(c->*pFunc)(p1,p2);
		return 0;
	}

	template<typename P1, typename P2, typename P3>
	static int Call(CT *c, void (CT::*pFunc)(P1, P2, P3), lua_State* pL)
	{
		uint8 succ = 0;
		P1 p1 = GetValue(TypeHelper<P1>(), pL, 1, succ);
		if (succ == 0 ){return -2;}
		P2 p2 = GetValue(TypeHelper<P2>(), pL, 2, succ);
		if (succ == 0 ){return -2;}
		P3 p3 = GetValue(TypeHelper<P3>(), pL, 3, succ);
		if (succ == 0 ){return -2;}
		(c->*pFunc)(p1,p2,p3);
		return 0;
	}
	template<typename P1, typename P2, typename P3, typename P4>
	static int Call(CT *c, void (CT::*pFunc)(P1, P2, P3, P4), lua_State* pL)
	{
		uint8 succ = 0;
		P1 p1 = GetValue(TypeHelper<P1>(), pL, 1, succ);
		if (succ == 0 ){return -2;}
		P2 p2 = GetValue(TypeHelper<P2>(), pL, 2, succ);
		if (succ == 0 ){return -2;}
		P3 p3 = GetValue(TypeHelper<P3>(), pL, 3, succ);
		if (succ == 0 ){return -2;}
		P4 p4 = GetValue(TypeHelper<P4>(), pL, 4, succ);
		if (succ == 0 ){return -2;}
		(c->*pFunc)(p1,p2,p3,p4);
		return 0;
	}

	template<typename P1, typename P2, typename P3, typename P4, typename P5>
	static int Call(CT *c, void (CT::*pFunc)(P1, P2, P3, P4, P5), lua_State* pL)
	{
		uint8 succ = 0;
		P1 p1 = GetValue(TypeHelper<P1>(), pL, 1, succ);
		if (succ == 0 ){return -2;}
		P2 p2 = GetValue(TypeHelper<P2>(), pL, 2, succ);
		if (succ == 0 ){return -2;}
		P3 p3 = GetValue(TypeHelper<P3>(), pL, 3, succ);
		if (succ == 0 ){return -2;}
		P4 p4 = GetValue(TypeHelper<P4>(), pL, 4, succ);
		if (succ == 0 ){return -2;}
		P5 p5 = GetValue(TypeHelper<P5>(), pL, 5, succ);
		if (succ == 0 ){return -2;}
		(c->*pFunc)(p1,p2,p3,p4,p5);
		return 0;
	}
};

// 主要用于C函数获取lua传入的参数
static bool GetValue(TypeHelper<bool>, lua_State* pL, uint32 index, uint8& succ)
{
	succ = lua_isboolean(pL,index);
	return lua_toboolean(pL, index) == 1;
}
static uint8 GetValue(TypeHelper<uint8>, lua_State* pL, uint32 index, uint8& succ)
{
	succ = lua_isinteger(pL,index);
	return (uint8)lua_tointeger(pL, index);
}
static uint16 GetValue(TypeHelper<uint16>, lua_State* pL, uint32 index, uint8& succ)
{
	succ = lua_isinteger(pL,index);
	return (uint16)lua_tointeger(pL, index);
}
static uint32 GetValue(TypeHelper<uint32>, lua_State* pL, uint32 index, uint8& succ)
{
	succ = lua_isinteger(pL,index);
	return (uint32)lua_tointeger(pL, index);
}
static uint8 GetValue(TypeHelper<int8>, lua_State* pL, uint32 index, uint8& succ)
{
	succ = lua_isinteger(pL,index);
	return (uint8)lua_tointeger(pL, index);
}
static uint16 GetValue(TypeHelper<int16>, lua_State* pL, uint32 index, uint8& succ)
{
	succ = lua_isinteger(pL,index);
	return (uint16)lua_tointeger(pL, index);
}
static uint32 GetValue(TypeHelper<int32>, lua_State* pL, uint32 index, uint8& succ)
{
	succ = lua_isinteger(pL,index);
	return (uint32)lua_tointeger(pL, index);
}
static float GetValue(TypeHelper<float>, lua_State* pL, uint32 index, uint8& succ)
{
	succ = lua_isnumber(pL,index);
	return (float)lua_tonumber(pL, index);
}
static String GetValue(TypeHelper<String>, lua_State* pL, uint32 index, uint8& succ)
{
	succ = (lua_isstring(pL,index) || lua_isnil(pL, index));
	size_t len = 0;
	String str = lua_tolstring(pL, index, &len);
	return str;
}


static String GetValue(TypeHelper<const String&>, lua_State* pL, uint32 index, uint8& succ)
{
	succ = (lua_isstring(pL,index) || lua_isnil(pL, index));

	size_t len = 0;
	String str = lua_tolstring(pL, index, &len);
	return str;
}

// 主要用于C函数返回值，不同类型的值调用不同的api传给lua
static void PushValue(lua_State* pL, bool value)
{
	lua_pushboolean(pL, (int)value);
}
static void PushValue(lua_State* pL, String value)
{
	lua_pushlstring(pL, value.c_str(),value.length());
}
static void PushValue(lua_State* pL, int32 value)
{
	lua_pushinteger(pL, value);
}
static void PushValue(lua_State* pL, int16 value)
{
	lua_pushinteger(pL, value);
}
static void PushValue(lua_State* pL, int8 value)
{
	lua_pushinteger(pL, value);
}
static void PushValue(lua_State* pL, uint32 value)
{
	lua_pushinteger(pL, value);
}
static void PushValue(lua_State* pL, uint16 value)
{
	lua_pushinteger(pL, value);
}
static void PushValue(lua_State* pL, uint8 value)
{
	lua_pushinteger(pL, value);
}

class SaveLuaStack
{
public:
    SaveLuaStack(lua_State* pl,int nSaveBegin = 0, int nSaveEnd = 0)
    {
        m_pl = pl;
        m_nSaveBegin = nSaveBegin;
        m_nSaveEnd   = nSaveEnd;
        int num = lua_gettop(m_pl);
        if (num != m_nSaveBegin)
        {
            sprintf(g_szInfo, "begin 堆栈中还有数据，%d 个元素",num);
            REPORT(g_szInfo);
            lua_settop(m_pl, 0);
        }
    }

    ~SaveLuaStack()
    {
        int num = lua_gettop(m_pl);
        if (num != m_nSaveEnd)
        {
            sprintf(g_szInfo, "end 堆栈中还有数据，%d 个元素",num);
            REPORT(g_szInfo);
            lua_settop(m_pl, 0);
        }
    }
private:
    lua_State* m_pl;
    int        m_nSaveBegin;
    int        m_nSaveEnd;
};