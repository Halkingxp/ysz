/*****************************************************************************
Copyright (C), 2012-2100, ^^^^^^^^. Co., Ltd.
文 件 名:  Pack.cpp
作    者:  Herry   
版    本:  1.0
完成日期:  2012-8-27
说明信息:  消息包, 使用了内存池管理内存
*****************************************************************************/
#include "Packet.h"
#include "MessageIdentifiers.h"

// 大端和小端的转换
//#ifdef _MSC_VER
//    #include <winsock2.h>
//#else
//    #include <arpa/inet.h> 
//#endif
//
//#define HTONS(v) htons(v)
//#define NTOHS(v) ntohs(v)
//#define HTONL(v) htonl(v)
//#define NTOHL(v) ntohl(v)

//********************************************************************
//函数功能: 构造函数
//第一参数: [IN] 发送的协议编号
//返回说明: 
//备注说明: 
//********************************************************************
CPacket::CPacket(uint16 nOpcode) : m_nSocketID(0)
{
	Reset(nOpcode);
}

//********************************************************************
//函数功能: 构造函数
//第一参数:
//返回说明: 
//备注说明: 
//********************************************************************
CPacket::CPacket(void) : m_nSocketID(0)
{
	Reset(0);
}

CPacket::~CPacket(void)
{
}

//********************************************************************
//函数功能: 重置消息包
//第一参数: [IN] 发送的协议编号
//返回说明: 
//备注说明: 
//********************************************************************
void CPacket::Reset(const char *pRecvData, uint16 nRecvSize)
{
	if (nRecvSize > PACKET_LEN)
	{
		memset(m_szData, 0, PACKET_LEN);
		return;
	}
	memcpy(m_szData, pRecvData, nRecvSize);
	m_nRPos = PACKET_HEAD_LEN;
	m_nWPos = nRecvSize;
}

//********************************************************************
//函数功能: 重置消息包
//第一参数: [IN] 发送的协议编号
//返回说明: 
//备注说明: 
//********************************************************************
void CPacket::Reset(uint16 nOpcode)
{
	CPacketHead *pHead = (CPacketHead *)m_szData;
	pHead->nMainID = ID_USER_PACKET_ENUM;
	pHead->nOpcode = nOpcode;
	pHead->nType = 1;
	pHead->nSize = PACKET_HEAD_LEN;
	m_nRPos = PACKET_HEAD_LEN;
	m_nWPos = PACKET_HEAD_LEN;
}

//********************************************************************
//函数功能: 获得消息包数据块
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
const char* CPacket::GetData(void)
{
	CPacketHead *pHead = (CPacketHead *)m_szData;
	pHead->nSize = m_nWPos;
	return m_szData;
}

//********************************************************************
//函数功能: 获得消息包数据长度
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
uint16 CPacket::GetSize(void)
{
	return m_nWPos;
}


//********************************************************************
//函数功能: 获得UDP主编号
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
uint8 CPacket::GetMainID(void)
{
	CPacketHead *pHead = (CPacketHead *)m_szData;
	return pHead->nMainID;
}

//********************************************************************
//函数功能: 设置UDP主编号
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CPacket::SetMainID(uint8 nMainID)
{
	CPacketHead *pHead = (CPacketHead *)m_szData;
	pHead->nMainID = nMainID;
}

//********************************************************************
//函数功能: 获得数据类型
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
uint8 CPacket::GetDataType(void)
{
	CPacketHead *pHead = (CPacketHead *)m_szData;
	return pHead->nType;
}

//********************************************************************
//函数功能: 获得消息编号
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
uint16 CPacket::GetOpcode(void)
{
	CPacketHead *pHead = (CPacketHead *)m_szData;
	return pHead->nOpcode;
}

//********************************************************************
//函数功能: 设置消息编号
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CPacket::SetOpcode(uint16 nOpcode)
{
	CPacketHead *pHead = (CPacketHead *)m_szData;
	pHead->nOpcode = nOpcode;
}
//********************************************************************
//函数功能: 获得写入位置
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
uint16 CPacket::GetWritePos(void)
{
	return m_nWPos;
}
//********************************************************************
//函数功能: 获得读取位置
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
uint16 CPacket::GetReadPos(void)
{
	return m_nRPos;
}

//********************************************************************
//函数功能: 在指定位置写入数据
//第一参数: [IN] 指定位置
//第二参数: [IN] 写入的数据
//第三参数: [IN] 写入数据的长度
//返回说明: 修改成功, 返回true
//返回说明: 修改失败, 返回false
//备注说明: 在写入数据前调用GetWritePos()记录写入位置, 之后再修改数据
//********************************************************************
bool CPacket::Rrevise(uint16 nPos, void *pData, uint16 nLen)
{
	if (pData == NULL || nPos > m_nWPos || nPos + nLen > m_nWPos)
	{
		return false;
	}
	memcpy(&m_szData[nPos], pData, nLen);
	return true;
}
//********************************************************************
//函数功能: 获得剩余可写入空间
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
uint16 CPacket::GetSpace(void)
{
	return PACKET_LEN - m_nWPos;
}

//********************************************************************
//函数功能: 获得SocketID
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
uint32 CPacket::GetSocketID(void)
{
	return m_nSocketID;
}

//********************************************************************
//函数功能: 设置SocketID
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CPacket::SetSocketID(uint32 nID)
{
	m_nSocketID = nID;
}
//********************************************************************
//函数功能: 读取 int8
//第一参数: 
//返回说明: 
//备注说明: 读取失败, 参数被改为0
//********************************************************************
int8 CPacket::ReadInt8(void)
{
	int8 value = 0;
	if (m_nRPos + (uint16)sizeof(int8) <= m_nWPos)
	{
		value = *(int8 *)(&m_szData[m_nRPos]);
		m_nRPos += sizeof(int8);
	}
	return value;
}
//********************************************************************
//函数功能: 读取 int16
//第一参数: 
//返回说明: 
//备注说明: 读取失败, 参数被改为0
//********************************************************************
int16 CPacket::ReadInt16(void)
{
	int16 value = 0;
	if (m_nRPos + (uint16)sizeof(int16) <= m_nWPos)
	{
		value = *(int16 *)(&m_szData[m_nRPos]);
		m_nRPos += sizeof(int16);
	}
	return value;
}
//********************************************************************
//函数功能: 读取 int32
//第一参数: 
//返回说明: 
//备注说明: 读取失败, 参数被改为0
//********************************************************************
int32 CPacket::ReadInt32(void)
{
	int32 value = 0;
	if (m_nRPos + (uint16)sizeof(int32) <= m_nWPos)
	{
		value = *(int32 *)(&m_szData[m_nRPos]);
		m_nRPos += sizeof(int32);
	}
	return value;
}
//********************************************************************
//函数功能: 读取 int64
//第一参数: 
//返回说明: 
//备注说明: 读取失败, 参数被改为0
//********************************************************************
int64 CPacket::ReadInt64(void)
{
	int64 value = 0;
	if (m_nRPos + (uint16)sizeof(int64) <= m_nWPos)
	{
		value = *(int64 *)(&m_szData[m_nRPos]);
		m_nRPos += sizeof(int64);
	}
	return value;
}


//********************************************************************
//函数功能: 读取 uint8
//第一参数: 
//返回说明: 
//备注说明: 读取失败, 参数被改为0
//********************************************************************
uint8 CPacket::ReadUint8(void)
{
	uint8 value = 0;
	if (m_nRPos + (uint16)sizeof(uint8) <= m_nWPos)
	{
		value = *(uint8 *)(&m_szData[m_nRPos]);
		m_nRPos += sizeof(uint8);
	}
	return value;
}
//********************************************************************
//函数功能: 读取 uint16
//第一参数: 
//返回说明: 
//备注说明: 读取失败, 参数被改为0
//********************************************************************
uint16 CPacket::ReadUint16(void)
{
	uint16 value = 0;
	if (m_nRPos + (uint16)sizeof(uint16) <= m_nWPos)
	{
		value = *(uint16 *)(&m_szData[m_nRPos]);
		m_nRPos += sizeof(uint16);
	}
	return value;
}
//********************************************************************
//函数功能: 读取 uint32
//第一参数: 
//返回说明: 
//备注说明: 读取失败, 参数被改为0
//********************************************************************
uint32 CPacket::ReadUint32(void)
{
	uint32 value = 0;
	if (m_nRPos + (uint16)sizeof(uint32) <= m_nWPos)
	{
		value = *(uint32 *)(&m_szData[m_nRPos]);
		m_nRPos += sizeof(uint32);
	}
	return value;
}
//********************************************************************
//函数功能: 读取 uint64
//第一参数: 
//返回说明: 
//备注说明: 读取失败, 参数被改为0
//********************************************************************
uint64 CPacket::ReadUint64(void)
{
	uint64 value = 0;
	if (m_nRPos + (uint16)sizeof(uint64) <= m_nWPos)
	{
		value = *(uint64 *)(&m_szData[m_nRPos]);
		m_nRPos += sizeof(uint64);
	}
	return value;
}
//********************************************************************
//函数功能: 读取 float
//第一参数: 
//返回说明: 
//备注说明: 读取失败, 参数被改为0
//备注说明: 读取的值只保留小数点后7位
//********************************************************************
float CPacket::ReadFloat(void)
{
	float value = 0;
	if (m_nRPos + (uint16)sizeof(float) <= m_nWPos)
	{
		value = *(float *)(&m_szData[m_nRPos]);
		m_nRPos += sizeof(float);
	}
	return value;
}
//********************************************************************
//函数功能: 读取 double
//第一参数: 
//返回说明: 
//备注说明: 读取失败, 参数被改为0
//备注说明: 读取的值只保留小数点后16位
//********************************************************************
double CPacket::ReadDouble(void)
{
	double value = 0;
	if (m_nRPos + (uint16)sizeof(double) <= m_nWPos)
	{
		value = *(double *)(&m_szData[m_nRPos]);
		m_nRPos += sizeof(double);
	}
	return value;
}

//********************************************************************
//函数功能: 读取 bool
//第一参数: 
//返回说明: 
//备注说明: 读取失败, 参数被改为false
//********************************************************************
bool CPacket::ReadBool(void)
{
	bool value = false;
	if (m_nRPos + (uint16)sizeof(bool) <= m_nWPos)
	{
		value = *(bool *)(&m_szData[m_nRPos]);
		m_nRPos += sizeof(bool);
	}
	return value;
}


//********************************************************************
//函数功能: 读取 std::string
//第一参数: 
//返回说明: 
//备注说明: 读取失败, 参数执行clear()
//********************************************************************
String CPacket::ReadString(void)
{
	uint16 nStringLen = ReadUint16();

	String value = "";
	if (m_nRPos + nStringLen <= m_nWPos)
	{
		value.resize(nStringLen);
		memcpy((void *)value.c_str(), &m_szData[m_nRPos], nStringLen);
		m_nRPos += nStringLen;
	}
	return value;
}

//********************************************************************
//函数功能: 读取大块数据
//第一参数: [OUT] 返回读取的大块数据, 需提前分配足够的内存空间
//第二参数: [IN]  大块数据分配的内存大小
//返回说明: 读取成功, 返回实际读取长度
//返回说明: 读取失败, 返回0
//备注说明: 
//********************************************************************
uint16 CPacket::ReadBuffer(void *pData, uint16 nLen)
{
	if (pData == NULL)
	{
		return 0;
	}

	uint16 nBuffLen = ReadUint16();
	if (nBuffLen > nLen || NULL == pData)
	{
		return 0;
	}

	if (m_nRPos + nBuffLen <= m_nWPos)
	{
		memcpy(pData, &m_szData[m_nRPos], nBuffLen);
		m_nRPos += nBuffLen;
		return nBuffLen;
	}
	return 0;
}









//********************************************************************
//函数功能: 写入 int8
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CPacket::WriteInt8(int8 value)
{
	if (m_nWPos + sizeof(int8) < PACKET_LEN)
	{
		*(int8 *)(&m_szData[m_nWPos]) = value;
		m_nWPos += sizeof(int8);
	}
}

//********************************************************************
//函数功能: 写入 int16
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CPacket::WriteInt16(int16 value)
{
	if (m_nWPos + sizeof(int16) < PACKET_LEN)
	{
		*(int16 *)(&m_szData[m_nWPos]) = value;
		m_nWPos += sizeof(int16);
	}
}

//********************************************************************
//函数功能: 写入 int32
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CPacket::WriteInt32(int32 value)
{
	if (m_nWPos + sizeof(int32) < PACKET_LEN)
	{
		*(int32 *)(&m_szData[m_nWPos]) = value;
		m_nWPos += sizeof(int32);
	}
}


//********************************************************************
//函数功能: 写入 int64
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CPacket::WriteInt64(int64 value)
{
	if (m_nWPos + sizeof(int64) < PACKET_LEN)
	{
		*(int64 *)(&m_szData[m_nWPos]) = value;
		m_nWPos += sizeof(int64);
	}
}

//********************************************************************
//函数功能: 写入 uint8
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CPacket::WriteUint8(uint8 value)
{
	if (m_nWPos + sizeof(uint8) < PACKET_LEN)
	{
		*(uint8 *)(&m_szData[m_nWPos]) = value;
		m_nWPos += sizeof(uint8);
	}
}
//********************************************************************
//函数功能: 写入 uint16
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CPacket::WriteUint16(uint16 value)
{
	if (m_nWPos + sizeof(uint16) < PACKET_LEN)
	{
		*(uint16 *)(&m_szData[m_nWPos]) = value;
		m_nWPos += sizeof(uint16);
	}
}

//********************************************************************
//函数功能: 写入 uint32
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CPacket::WriteUint32(uint32 value)
{
	if (m_nWPos + sizeof(uint32) < PACKET_LEN)
	{
		*(uint32 *)(&m_szData[m_nWPos]) = value;
		m_nWPos += sizeof(uint32);
	}
}
//********************************************************************
//函数功能: 写入 uint64
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CPacket::WriteUint64(uint64 value)
{
	if (m_nWPos + sizeof(uint64) < PACKET_LEN)
	{
		*(uint64 *)(&m_szData[m_nWPos]) = value;
		m_nWPos += sizeof(uint64);
	}
}
//********************************************************************
//函数功能: 写入 float
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CPacket::WriteFloat(float value)
{
	if (m_nWPos + sizeof(float) < PACKET_LEN)
	{
		*(float *)(&m_szData[m_nWPos]) = value;
		m_nWPos += sizeof(float);
	}
}
//********************************************************************
//函数功能: 写入 double
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CPacket::WriteDouble(double value)
{
	if (m_nWPos + sizeof(double) < PACKET_LEN)
	{
		*(double *)(&m_szData[m_nWPos]) = value;
		m_nWPos += sizeof(double);
	}
}


//********************************************************************
//函数功能: 写入 std::string
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CPacket::WriteString(const String &value)
{
	uint16 nStringLen = (uint16)value.length();
	if (m_nWPos + sizeof(uint16) + nStringLen < PACKET_LEN)
	{
		memcpy(&m_szData[m_nWPos], &nStringLen, sizeof(uint16));
		m_nWPos += sizeof(uint16);

		memcpy(&m_szData[m_nWPos], value.c_str(), nStringLen);
		m_nWPos += nStringLen;
	}
}

//********************************************************************
//函数功能: 写入大块数据
//第一参数: [IN] 写入的大块数据
//第二参数: [IN] 写入的大块数据的长度
//返回说明: 写入成功, 返回实际写入长度
//返回说明: 写入失败, 返回0
//备注说明: 
//********************************************************************
uint16 CPacket::WriteBuffer(void *pData, uint16 nLen)
{
	if (NULL == pData)
	{
		return 0;
	}

	if (m_nWPos + nLen + sizeof(uint16) < PACKET_LEN)
	{
		memcpy(&m_szData[m_nWPos], &nLen, sizeof(uint16));
		m_nWPos += sizeof(uint16);

		memcpy(&m_szData[m_nWPos], pData, nLen);
		m_nWPos += nLen;
		return nLen;
	}
	return 0;
}

//********************************************************************
//函数功能: 写入 bool
//第一参数: 
//返回说明: 
//备注说明: 
//********************************************************************
void CPacket::WriteBool(bool value)
{
	if (m_nWPos + sizeof(bool) < PACKET_LEN)
	{
		*(bool *)(&m_szData[m_nWPos]) = value;
		m_nWPos += sizeof(bool);
	}
}
