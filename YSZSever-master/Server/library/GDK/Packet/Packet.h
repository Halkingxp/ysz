/*****************************************************************************
Copyright (C), 2012-2100, ^^^^^^^^. Co., Ltd.
文 件 名:  Pack.h
作    者:  Herry  
版    本:  1.0
完成日期:  2012-8-27
说明信息:  消息包, 使用了内存池管理内存
*****************************************************************************/
#pragma once
#include "Define.h"

#define PACKET_LEN			65536			// 消息包的字节长度
#define SOCKET_BUFFER_LEN   131072          // 缓存区的字节长度 = PACKET_LEN * 2
#define PACKET_HEAD_LEN		6				// 消息头的字节长度

// 包头
struct CPacketHead
{
	uint8  nMainID;						// UDP主协议号
	uint8  nType;						// 数据类型 1:字节流 2:protolbuf
	uint16 nOpcode;						// 协议编号
	uint16 nSize;						// 协议体长度
};

// 消息包
class CPacket
{
public:
	CPacket(void);
	CPacket(uint16 nOpcode);
	CPacket(const CPacket &other) {}
	~CPacket(void);

	void   Reset(uint16 nOpcode);
	void   Reset(const char *pRecvData, uint16 nRecvSize);
	uint16 GetSize(void);
	uint16 GetSpace(void);
	uint16 GetOpcode(void);
	uint8  GetMainID(void);
	uint8  GetDataType(void);
	uint32 GetSocketID(void);
	void   SetMainID(uint8 nMainID);
	void   SetSocketID(uint32 nID);
	void   SetOpcode(uint16 nOpcode);
	const char* GetData(void);

	uint16 GetReadPos(void);
	uint16 GetWritePos(void);
	bool   Rrevise(uint16 nPos, void *pData, uint16 nLen);

private:
	CPacket& operator = (const CPacket &other) = delete;
	CPacket& operator >> (char *value) = delete;
	CPacket& operator << (char *value) = delete;

public:
	//读取
	int8	ReadInt8(void);
	int16	ReadInt16(void);
	int32	ReadInt32(void);
	int64	ReadInt64(void);
	uint8	ReadUint8(void);
	uint16	ReadUint16(void);
	uint32	ReadUint32(void);
	uint64	ReadUint64(void);
	float	ReadFloat(void);
	double	ReadDouble(void);
	bool	ReadBool(void);
	String	ReadString(void);
	uint16	ReadBuffer(void *pData, uint16 nLen);

	//写入
	void	WriteInt8(int8 value);
	void	WriteInt16(int16 value);
	void	WriteInt32(int32 value);
	void	WriteInt64(int64 value);
	void	WriteUint8(uint8 value);
	void	WriteUint16(uint16 value);
	void	WriteUint32(uint32 value);
	void	WriteUint64(uint64 value);
	void	WriteFloat(float value);
	void	WriteDouble(double value);
	void	WriteBool(bool value);
	void	WriteString(const String& value);
	uint16	WriteBuffer(void *pData, uint16 nLen);

private:
	char				m_szData[PACKET_LEN];		// 消息包
	uint16				m_nRPos;					// 读位置
	uint16				m_nWPos;					// 写位置
	uint32				m_nSocketID;				// SocketID
};
