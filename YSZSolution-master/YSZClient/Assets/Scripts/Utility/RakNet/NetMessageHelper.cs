//***************************************************************
// 脚本名称：NetMessageHelper
// 类创建人：周  波
// 创建日期：2017.02
// 功能描述：用于写入和读取网络字节消息
//***************************************************************
using UnityEngine;
using System.Collections;
using System;
using System.IO;

namespace Net
{
    public class PushMessage : IDisposable
    {
        MemoryStream memoryStream = null;
        BinaryWriter binaryWriter = null;
        public PushMessage()
        {
            memoryStream = new MemoryStream();
            binaryWriter = new BinaryWriter(memoryStream);
        }

        /// <summary>
        /// 写入 byte 数据
        /// </summary>
        /// <param name="content"></param>
        public void PushByte(byte content)
        {
            binaryWriter.Write(content);
        }

        /// <summary>
        /// 写入 sbyte 数据
        /// </summary>
        /// <param name="content"></param>
        public void PushSByte(sbyte content)
        {
            binaryWriter.Write(content);
        }

        /// <summary>
        /// 写入 bool 数据
        /// </summary>
        /// <param name="content"></param>
        public void PushBoolean(bool content)
        {
            binaryWriter.Write(content);
        }

        /// <summary>
        /// 写入 bytes 数据
        /// </summary>
        /// <param name="content"></param>
        public void PushBytes(byte[] content)
        {
            content = content ?? new byte[0];
            PushArrayLength(content.Length);
            binaryWriter.Write(content);
        }

        /// <summary>
        /// 写入数组的长度
        /// </summary>
        /// <param name="length"></param>
        void PushArrayLength(int length)
        {
            PushInt16((short)length);
        }

        /// <summary>
        /// 写入 string 数据
        /// </summary>
        /// <param name="content"></param>
        public void PushString(string content)
        {
            PushBytes(Utility.UTF8StringToBytes(content));
        }

        /// <summary>
        /// 写入 short 数据
        /// </summary>
        /// <param name="content"></param>
        public void PushInt16(short content)
        {
            binaryWriter.Write(content);
        }

        /// <summary>
        /// 写入 ushort 数据
        /// </summary>
        /// <param name="content"></param>
        public void PushUInt16(ushort content)
        {
            binaryWriter.Write(content);
        }

        /// <summary>
        /// 写入 int 数据
        /// </summary>
        /// <param name="content"></param>
        public void PushInt32(int content)
        {
            binaryWriter.Write(content);
        }

        /// <summary>
        /// 写入 uint 数据
        /// </summary>
        /// <param name="content"></param>
        public void PushUInt32(uint content)
        {
            binaryWriter.Write(content);
        }

        /// <summary>
        /// 写入 long 值
        /// </summary>
        /// <param name="content"></param>
        public void PushInt64(long content)
        {
            binaryWriter.Write(content);
        }

        /// <summary>
        /// 写入 ulong 值
        /// </summary>
        /// <param name="content"></param>
        public void PushUInt64(ulong content)
        {
            binaryWriter.Write(content);
        }

        /// <summary>
        /// 写入 float 数据
        /// </summary>
        /// <param name="content"></param>
        public void PushFloat(float content)
        {
            binaryWriter.Write(content);
        }

        /// <summary>
        /// 当前消息体数据
        /// </summary>
        public byte[] Message
        {
            get
            {
                byte[] result = new byte[memoryStream.Length];
                Array.Copy(memoryStream.ToArray(), result, memoryStream.Length);
                return result;
            }
        }

        public void Dispose()
        {
            if (binaryWriter != null)
            {
                binaryWriter.Flush();
                binaryWriter.Close();
                binaryWriter = null;
            }
            if (memoryStream != null)
            {
                memoryStream.Flush();
                memoryStream.Close();
                memoryStream.Dispose();
                memoryStream = null;
            }
        }
    }

    public class PopMessage : IDisposable
    {
        /// <summary>
        /// 数组长度
        /// </summary>
        MemoryStream memoryStream = null;
        BinaryReader binaryReader = null;

        public byte ParseType { get; private set; }

        /// <summary>
        /// 构造函数
        /// </summary>
        /// <param name="dataArray"></param>
        /// <param name="parseType">解析方式：1 字节流，2 protobuf</param>
        public PopMessage(byte[] dataArray, byte parseType)
        {
            this.ParseType = parseType;

            memoryStream = new MemoryStream(dataArray);
            if (parseType == 1)
            {
                memoryStream.Position = NetworkClient.DATA_LENGTH;
            }
            else
            {
                memoryStream.Position = 0;
            }

            binaryReader = new BinaryReader(memoryStream);
        }

        /// <summary>
        /// 重置开始解析消息的位置
        /// </summary>
        public void Reset()
        {
            if (memoryStream != null)
                memoryStream.Position = 0;
        }

        /// <summary>
        /// 读取byte 值
        /// </summary>
        /// <returns></returns>
        public byte PopByte()
        {
            if (memoryStream.Length - memoryStream.Position < GetReadLenghtByType("byte"))
            {
                return default(byte);
            }
            else
            {
                return binaryReader.ReadByte();
            }
        }

        /// <summary>
        /// 读取byte 值
        /// </summary>
        /// <returns></returns>
        public sbyte PopSByte()
        {
            if (memoryStream.Length - memoryStream.Position < GetReadLenghtByType("byte"))
            {
                return default(sbyte);
            }
            else
            {
                return binaryReader.ReadSByte();
            }
        }

        /// <summary>
        /// 读取bool 值
        /// </summary>
        /// <returns></returns>
        public bool PopBoolean()
        {
            if (memoryStream.Length - memoryStream.Position < GetReadLenghtByType("bool"))
            {
                return default(bool);
            }
            else
            {
                return binaryReader.ReadBoolean();
            }
        }

        /// <summary>
        /// 读取byte 数组 值
        /// </summary>
        /// <returns></returns>
        public byte[] PopBytes()
        {
            int length = PopArrayLength();
            byte[] data = null;
            if (length > 0)
            {
                if (memoryStream.Length < memoryStream.Position + length)
                {
                    data = new byte[0];
                    Debug.LogErrorFormat("Data Length Error, when PopMessage pop bytes!");
                }
                else
                {
                    data = binaryReader.ReadBytes(length);
                }
            }
            else
            {
                data = new byte[0];
            }
            return data;
        }

        /// <summary>
        /// 读取字符串 值
        /// </summary>
        /// <returns></returns>
        public string PopString()
        {
            byte[] data = PopBytes();
            return Utility.BytesToUTF8String(data);
        }

        /// <summary>
        /// 读取数组长度
        /// </summary>
        /// <returns></returns>
        int PopArrayLength()
        {
            return PopInt16();
        }

        /// <summary>
        /// 读取 short 值
        /// </summary>
        /// <returns></returns>
        public short PopInt16()
        {
            if (memoryStream.Length - memoryStream.Position < GetReadLenghtByType("Int16"))
            {
                return default(short);
            }
            else
            {
                return binaryReader.ReadInt16();
            }
        }

        /// <summary>
        /// 读取 ushort 值
        /// </summary>
        /// <returns></returns>
        public ushort PopUInt16()
        {
            if (memoryStream.Length - memoryStream.Position < GetReadLenghtByType("UInt16"))
            {
                return default(ushort);
            }
            else
            {
                return binaryReader.ReadUInt16();
            }
        }

        /// <summary>
        /// 读取一个int 值
        /// </summary>
        /// <returns></returns>
        public int PopInt32()
        {
            if (memoryStream.Length - memoryStream.Position < GetReadLenghtByType("Int32"))
            {
                return default(int);
            }
            else
            {
                return binaryReader.ReadInt32();
            }
        }

        /// <summary>
        /// 读取 uint 值
        /// </summary>
        /// <returns></returns>
        public uint PopUInt32()
        {
            if (memoryStream.Length - memoryStream.Position < GetReadLenghtByType("UInt32"))
            {
                return default(uint);
            }
            else
            {
                return binaryReader.ReadUInt32();
            }
        }

        public uint[] GetRand()
        {
            return new uint[] { 1, 3, 5, 7 };
        }

        /// <summary>
        /// 读取 long 值
        /// </summary>
        /// <returns></returns>
        public long PopInt64()
        {
            if (memoryStream.Length - memoryStream.Position < GetReadLenghtByType("Int64"))
            {
                return default(long);
            }
            else
            {
                return binaryReader.ReadInt64();
            }
        }

        /// <summary>
        /// 读取 ulong 值
        /// </summary>
        /// <returns></returns>
        public ulong PopUInt64()
        {
            if (memoryStream.Length - memoryStream.Position < GetReadLenghtByType("UInt64"))
            {
                return default(ulong);
            }
            else
            {
                return binaryReader.ReadUInt64();
            }
        }

        /// <summary>
        /// 读取 float 值
        /// </summary>
        /// <returns></returns>
        public float PopFloat()
        {
            if (memoryStream.Length - memoryStream.Position < GetReadLenghtByType("float"))
            {
                return default(float);
            }
            else
            {
                return binaryReader.ReadSingle();
            }
        }

        public void Dispose()
        {
            if (binaryReader != null)
            {
                binaryReader.Close();
                binaryReader = null;
            }

            if (memoryStream != null)
            {
                memoryStream.Close();
                memoryStream.Dispose();
                memoryStream = null;
            }
        }

        /// <summary>
        /// 根据类型获取读取长度
        /// </summary>
        /// <param name="typeName"></param>
        /// <returns></returns>
        static int GetReadLenghtByType(string typeName)
        {
            switch (typeName)
            {
                case "Int32":
                case "UInt32":
                case "int":
                case "uint":
                case "float":
                    return 4;
                case "Int16":
                case "UInt16":
                case "short":
                case "ushort":
                    return 2;
                case "byte":
                case "bool":
                    return 1;
                case "UInt64":
                case "Int64":
                case "long":
                case "ulong":
                    return 8;
                default:
                    return 0;
            }
        }
    }
}