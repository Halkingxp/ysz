//***************************************************************
// 脚本名称：NetClient.cs
// 类创建人：周  波
// 创建日期：2017.02
// 功能描述：用于RakNet的网络通信客户端
//***************************************************************

using System;
using UnityEngine;
using System.Collections.Generic;
using RakNet;

namespace Net
{
    public partial class NetworkClient : IDisposable
    {
        /// <summary>
        /// 消息状态长度
        /// </summary>
        const int STATE_LENGTH = 1;
        /// <summary>
        /// 解析方式长度
        /// </summary>
        const int PARSE_LENGTH = 1;
        /// <summary>
        /// 消息头长度（消息状态+解析方式+消息编号）
        /// </summary>
        const int HEADER_LENGTH = STATE_LENGTH + PARSE_LENGTH + 2;
        /// <summary>
        /// 消息体长度
        /// </summary>
        public const int DATA_LENGTH = 2;
        /// <summary>
        /// 协议头 长度
        /// </summary>
        const int PROTOCOL_SIZE = HEADER_LENGTH + DATA_LENGTH;
        /// <summary>
        /// 每帧接受的最大数量
        /// </summary>
        const int MaxReceiveCount = 3;

        /// <summary>
        /// Raknet 网络连接客服端
        /// </summary>
        private RakNet.RakPeerInterface mClient;

        /// <summary>
        /// 是否连接上服务器
        /// </summary>
        public bool IsConnectedServer { get; private set; }

        /// <summary>
        /// 连接失败成功的标志
        /// </summary>
        //public bool IsConnectSuccess { get; private set; }

        /// <summary>
        /// 是否关闭状态
        /// </summary>
        //public bool IsClientClosed { get; private set; }

        /// <summary>
        /// 是否初始化过了
        /// </summary>
        public bool IsStartUp { get; private set; }

        /// <summary>
        /// 网络连接回调
        /// </summary>
        private Action<bool> connectCallBack = null;

        /// <summary>
        /// 消息解析器的字典
        /// </summary>
        private Dictionary<ushort, Action<PopMessage>> m_MessageParserDict = new Dictionary<ushort, Action<PopMessage>>();

        /// <summary>
        /// 客户端名称
        /// </summary>
        public string ClientName { get; protected set; }

        /// <summary>
        /// 服务器IP地址
        /// </summary>
        public string ServerIP { get; protected set; }

        /// <summary>
        /// 服务器端口
        /// </summary>
        public ushort ServerPort { get; protected set; }

        private SystemAddress m_serverAddress = null;
        private RakNetGUID m_guid = null;

        public bool ProcUserMessage { get; set; }
        /// <summary>
        /// 构造函数
        /// </summary>
        /// <param name="clientName">连接名称</param>
        /// <param name="serverIP">服务器IP地址</param>
        /// <param name="serverPort">服务器端口</param>
        public NetworkClient(string clientName)
        {
            this.ClientName = clientName;
            this.IsStartUp = false;
            ProcUserMessage = true;
        }

        #region Handle Network Connet

        /// <summary>
        /// 通知网络连接回调
        /// </summary>
        /// <param name="isSuccess"></param>
        void NotifyConnectCallBack(bool isSuccess)
        {
            if (connectCallBack != null)
            {
                connectCallBack(isSuccess);
            }
        }

        public bool CanSendMessage()
        {
            if (mClient == null)
            {
                Debug.LogError("mClient = null 请先初始化");
                return false;
            }
            if (mClient.IsActive() == false)
            {
                //Debug.Log("mClient.IsActive() = false 不能发送消息");
                return false;
            }

            ConnectionState clientState = mClient.GetConnectionState(m_serverAddress);
            if (clientState != ConnectionState.IS_CONNECTED)
            {
                //Debug.Log("ConnectionState = " + clientState + " 不能发送消息");
                return false;
            }

            return true;
        }

        public void ShowConnectionState()
        {
            if (mClient == null)
            {
                Debug.LogError("显示raknet状态时 mClient = null 请先初始化");
            }
            //ConnectionState clientState = mClient.GetConnectionState(m_serverAddress);
            //Debug.Log("显示raknet的状态 ConnectionState = " + clientState);
        }

        /// <summary>
        /// 启动是否成功
        /// </summary>
        /// <returns></returns>
        public bool StartUpRaknet(bool isIPV6)
        {
            if (IsStartUp == false)
            {
                if (mClient == null)
                {
                    mClient = RakPeerInterface.GetInstance();
                }

                SocketDescriptor descriptor = new SocketDescriptor();
                //descriptor.port = 0;
                if (isIPV6 == true)
                {
                    // 这里有尼玛个天坑，AF_INET6 這个宏在windows下的值是23，在 mac osx下的值是30
                    descriptor.socketFamily = 30;
                }
                else
                {
                    descriptor.socketFamily = 2;
                }

                StartupResult result = mClient.Startup(1, descriptor, 1);
                if (result == StartupResult.RAKNET_STARTED)
                {
                    IsStartUp = true;
                    return true;
                }
                else
                {
                    Debug.LogError(string.Format("初始化raknet失败,result = {0}", result));
                    return false;
                }
            }
            else
            {
                return true;
            }
        }

        /// <summary>
        /// 彻底关掉raknet
        /// </summary>
        public void ShutDown()
        {
            if (mClient != null && mClient.IsActive() && !string.IsNullOrEmpty(ServerIP))
            {
                Debug.LogFormat("DisConnect Server[{0}]====>[{1}].", this.ClientName, this.ServerIP);
                //Debug.Log("mClient.CloseConnection 被调用");
                mClient.CloseConnection(m_serverAddress, true);
            }

            if (mClient != null)
            {
                //Debug.Log("mClient.Shutdown 被调用");
                mClient.Shutdown(300);
            }
            IsStartUp = false;
            IsConnectedServer = false;
        }

        /// <summary>
        /// 开启网络连接
        /// </summary>
        public void Connect(string serverIP, ushort serverPort, Action<bool> connectCallBack)
        {
            if (IsConnectedServer) // 已经连接上了服务器
            {
                Debug.LogError("已经连接上了服务器,请勿重复链接");
                connectCallBack(false);
                return;
            }

            if (!IsStartUp)
            {
                Debug.LogError("连接时，没有初始化raknet");
                connectCallBack(false);
                return;
            }

            this.ServerIP = serverIP;
            this.ServerPort = serverPort;

            if (!IsValidity())
            {
                Debug.LogErrorFormat("Cann't connect client[{0}], it have some error of server ip[{1}] or server port[{2}], please check it!", this.ClientName, this.ServerIP, this.ServerPort);
                connectCallBack(false);
                return;
            }

            this.connectCallBack = connectCallBack;
            //Debug.Log(string.Format("调用raknet连接接口 serverip{0}, port{1}", this.ServerIP, this.ServerPort));
            ConnectionAttemptResult connectResult = mClient.Connect(this.ServerIP, this.ServerPort, null, 0);
            //Debug.Log("调用连接接口的返回值 = " + connectResult);
            if (connectResult == ConnectionAttemptResult.CONNECTION_ATTEMPT_STARTED)
            {
                //IsConnectSuccess = false;
                //// 已经向服务器发送了连接请求，等待服务器消息反馈
                //// 真正连接成功需要等待服务器返回消息才知道连接成功与否
            }
            else
            {
                connectCallBack(false);
            }
        }

        /// <summary>
        /// 检验服务器的IP和端口是否合法
        /// </summary>
        /// <returns></returns>
        bool IsValidity()
        {
            System.Net.IPAddress serverAddress = null;
            if (System.Net.IPAddress.TryParse(ServerIP, out serverAddress))
            {
                if (ServerPort > 0)
                {
                    return true;
                }
                else
                {
                    return false;
                }
            }
            else
            {
                return false;
            }
        }

        /// <summary>
        /// 断开连接
        /// </summary>
        private void InternalDisConnect()
        {
            if (IsConnectedServer)
            {
                IsConnectedServer = false;
            }
            // 断开已有的连接
            if (mClient != null && mClient.IsActive() && !string.IsNullOrEmpty(ServerIP) && !(m_serverAddress == null))
            {
                Debug.LogFormat("DisConnect Server[{0}]====>[{1}].", this.ClientName, this.ServerIP);
                mClient.CloseConnection(m_serverAddress, true);
            }
        }

        public void DisConnect()
        {
            InternalDisConnect();
        }

        #endregion

        #region Handle Update Network

        /// <summary>
        /// 更新网络连接器
        /// </summary>
        public void UpdateNetwork()
        {
            if (IsStartUp)
            {
                ReceiveMessage();
            }
        }

        #endregion

        #region Handle Receive Message

        // 接受的数量
        int receiveCount = 0;

        /// <summary>
        /// 处理接受消息
        /// </summary>
        void ReceiveMessage()
        {

            receiveCount = 0;
            // 单帧处理消息数量不大于指定的消息数量
            while (receiveCount < MaxReceiveCount || !ProcUserMessage)
            {
                Packet packet = mClient.Receive();
                if (packet == null) // 没有消息内容了，不用解析，退出循环
                {
                    break;
                }
                receiveCount++;
                DefaultMessageIDTypes messageIDType = (DefaultMessageIDTypes)packet.data[0];
                LogMessage(messageIDType.ToString());
                switch (packet.data[0])
                {
                    case (byte)DefaultMessageIDTypes.ID_DISCONNECTION_NOTIFICATION:
                        //DisConnect();
                        EventDispatcher.Instance.TriggerEvent("Application_ConnectionLost", packet.data[0]);
                        break;
                    case (byte)DefaultMessageIDTypes.ID_ALREADY_CONNECTED:
                        //Debug.Log("收到18消息");
                        DisConnect();
                        EventDispatcher.Instance.TriggerEvent("Application_ConnectionLost", packet.data[0]);
                        break;
                    case (byte)DefaultMessageIDTypes.ID_INCOMPATIBLE_PROTOCOL_VERSION:
                        break;
                    case (byte)DefaultMessageIDTypes.ID_REMOTE_DISCONNECTION_NOTIFICATION: // Server telling the clients of another m_Client disconnecting gracefully.  You can manually broadcast this in a peer to peer enviroment if you want.
                        break;
                    case (byte)DefaultMessageIDTypes.ID_REMOTE_CONNECTION_LOST: // Server telling the clients of another m_Client disconnecting forcefully.  You can manually broadcast this in a peer to peer enviroment if you want.
                        DisConnect();
                        EventDispatcher.Instance.TriggerEvent("Application_ConnectionLost", packet.data[0]);
                        break;
                    case (byte)DefaultMessageIDTypes.ID_REMOTE_NEW_INCOMING_CONNECTION: // Server telling the clients of another m_Client connecting.  You can manually broadcast this in a peer to peer enviroment if you want.
                        break;
                    case (byte)DefaultMessageIDTypes.ID_CONNECTION_BANNED: // Banned from this server
                        break;
                    case (byte)DefaultMessageIDTypes.ID_CONNECTION_ATTEMPT_FAILED:
                        DisConnect();
                        //ShutDown();
                        EventDispatcher.Instance.TriggerEvent("Application_ConnectionLost", packet.data[0]);
                        break;
                    case (byte)DefaultMessageIDTypes.ID_NO_FREE_INCOMING_CONNECTIONS:// 服务器满员了
                        DisConnect();
                        EventDispatcher.Instance.TriggerEvent("Application_ConnectionLost", packet.data[0]);
                        // Sorry, the server is full.  I don't do anything here but
                        // A real app should tell the user
                        break;
                    case (byte)DefaultMessageIDTypes.ID_INVALID_PASSWORD:// 无效的密码
                        break;
                    case (byte)DefaultMessageIDTypes.ID_CONNECTION_LOST:
                        // Couldn't deliver a reliable packet - i.e. the other system was abnormally
                        // terminated
                        DisConnect();
                        EventDispatcher.Instance.TriggerEvent("Application_ConnectionLost", packet.data[0]);
                        break;
                    case (byte)DefaultMessageIDTypes.ID_CONNECTION_REQUEST_ACCEPTED: // 连接成功
                        {
                            IsConnectedServer = true;
                            //LogMessage(string.Format("ID_CONNECTION_REQUEST_ACCEPTED to {0} with GUID {1}", packet.systemAddress.ToString(true), packet.guid.ToString()));
                            //LogMessage(string.Format("My external address is {0}", mClient.GetExternalID(packet.systemAddress).ToString(true)));
                            m_serverAddress = packet.systemAddress;
                            m_guid = packet.guid;
                            Debug.LogFormat("RakNetGUID:{0}", m_guid);
                            mClient.SetTimeoutTime(9000, m_serverAddress);
                            NotifyConnectCallBack(true);
                            break;
                        }
                    case (byte)DefaultMessageIDTypes.ID_CONNECTED_PING:
                    case (byte)DefaultMessageIDTypes.ID_UNCONNECTED_PING:
                        LogMessage(string.Format("Ping from {0}", packet.systemAddress.ToString(true)));
                        break;
                    case (byte)DefaultMessageIDTypes.ID_USER_PACKET_ENUM:
                    case (byte)DefaultMessageIDTypes.ID_USER_PACKET_ENUM2:
                        if (ProcUserMessage == true)
                        {
                            Dispatch(packet);
                        }
                        break;
                    default:
                        // It's a m_Client, so just show the message
                        LogMessage("Message ID Type default: " + packet.data[0]);
                        break;
                }
                mClient.DeallocatePacket(packet);
            }

            if (ProcUserMessage == false)
            {
                ProcUserMessage = true;
                // 抛出消息清除完毕的事件
                //Debug.Log("c#清空消息完毕");
                EventDispatcher.Instance.TriggerEvent("Application_ClearMessage_OK", null);
            }
        }

        /// <summary>
        /// 消息分发器
        /// </summary>
        /// <param name="packet"></param>
        void Dispatch(Packet packet)
        {
            byte[] data = packet.data; // 消息包的内容
            if (data.Length >= HEADER_LENGTH)
            {
                // 协议ID
                ushort protocolID = System.BitConverter.ToUInt16(data, STATE_LENGTH + PARSE_LENGTH);
                LogMessage(string.Format("===Dispatch Protocol[{0}]==", protocolID));

                // 解析方式
                byte parseType = data[STATE_LENGTH];

                // 消息体内容
                byte[] messageContent = new byte[data.Length - HEADER_LENGTH];

                Array.Copy(data, HEADER_LENGTH, messageContent, 0, data.Length - HEADER_LENGTH);

                NotifyParseMessage(protocolID, parseType, messageContent);
            }
            else
            {
                Debug.LogErrorFormat("Net packet error, packet data length less than {0}!", HEADER_LENGTH);
            }
        }

        /// <summary>
        /// 通知消息解析器解析消息
        /// </summary>
        /// <param name="protocolID">消息ID</param>
        /// <param name="messageContent">消息内容</param>
        void NotifyParseMessage(ushort protocolID, byte parseType, byte[] messageContent)
        {
            if (m_MessageParserDict.Count > 0)
            {
                using (PopMessage message = new PopMessage(messageContent, parseType))
                {
                    if (m_MessageParserDict.ContainsKey(protocolID))
                    {
                        m_MessageParserDict[protocolID].Invoke(message);
                        // 统一触发下
                        message.Reset();
                        EventDispatcher.Instance.TriggerEvent(protocolID.ToString(), message);
                    }
                    else
                    {
                        Debug.LogErrorFormat("Unhandled protocol id [{0}], please check it!", protocolID);
                    }
                }
            }
            else
            {
                Debug.LogError("Net message received but no praser for prase it!");
            }
        }

        /// <summary>
        /// 注册消息解析器
        /// </summary>
        /// <param name="protocolID">协议编号</param>
        /// <param name="parser">消息解析器</param>
        public void RegisterParser(ushort protocolID, Action<PopMessage> parser)
        {
            if (parser != null)
            {
                Action<PopMessage> tempParser;
                if (m_MessageParserDict.ContainsKey(protocolID))
                {
                    tempParser = m_MessageParserDict[protocolID];
                    if (tempParser != null)
                    {
                        tempParser += parser;
                    }
                    else
                    {
                        tempParser = parser;
                    }
                }
                else
                {
                    tempParser = parser;
                }
                m_MessageParserDict[protocolID] = tempParser;
            }
            else
            {
                Debug.LogErrorFormat("You can't register one null parser for protocol ID[{0}]", protocolID);
            }
        }

        /// <summary>
        /// 移除掉消息解析器
        /// </summary>
        /// <param name="protocolID"></param>
        public void RemoveParser(ushort protocolID)
        {
            if (m_MessageParserDict.ContainsKey(protocolID))
            {
                m_MessageParserDict[protocolID] = null;
                m_MessageParserDict.Remove(protocolID);
            }
        }

        /// <summary>
        /// 注册消息解析器
        /// </summary>
        /// <param name="protocolID">协议编号</param>
        /// <param name="parser">消息解析器</param>
        public void RemoveParser(ushort protocolID, Action<PopMessage> parser)
        {
            if (parser != null)
            {
                if (m_MessageParserDict.ContainsKey(protocolID))
                {
                    if (m_MessageParserDict[protocolID] != null)
                    {
                        if (m_MessageParserDict[protocolID] != parser)
                        {
                            m_MessageParserDict[protocolID] -= parser;
                        }
                        else
                        {
                            m_MessageParserDict[protocolID] = null;
                            m_MessageParserDict.Remove(protocolID);
                        }
                    }
                    else
                    {
                        m_MessageParserDict.Remove(protocolID);
                    }
                }
            }
            else
            {
                Debug.LogErrorFormat("You can't remove one null parser for protocol ID[{0}]", protocolID);
            }
        }

        #endregion

        #region Handle Send Message

        /// <summary>
        /// 发送消息
        /// </summary>
        /// <param name="stateFlag">状态</param>
        /// <param name="protocolID">消息ID</param>
        /// <param name="message">消息内容</param>
        public void SendMessage(ushort protocolID, byte[] message, byte parseType = 1, byte stateFlag = 134)
        {
            if (m_serverAddress == null)
            {
                Debug.LogWarningFormat("when send message m_serverAddress == null");
                return;
            }
            ConnectionState clientState = mClient.GetConnectionState(m_serverAddress);
            if (clientState != ConnectionState.IS_CONNECTED)
            {
                Debug.LogWarningFormat("The net connect was not success when you send message[Protocol:{0}], please check it!", protocolID);
                return;
            }

            byte[] protocolBytes = System.BitConverter.GetBytes(protocolID);
            byte[] messageLengthBytes = System.BitConverter.GetBytes((ushort)message.Length);
            byte[] dataBytes = new byte[PROTOCOL_SIZE + message.Length];
            // 写入状态标志
            dataBytes[0] = stateFlag;
            // 写入解析方式
            dataBytes[1] = parseType;
            int startIndex = 2;
            // 写入协议编号
            Array.Copy(protocolBytes, 0, dataBytes, startIndex, protocolBytes.Length);
            startIndex += protocolBytes.Length;
            // 写入消息长度
            Array.Copy(messageLengthBytes, 0, dataBytes, startIndex, messageLengthBytes.Length);
            startIndex += messageLengthBytes.Length;
            // 写入消息内容
            Array.Copy(message, 0, dataBytes, startIndex, message.Length);
            //uint sendRet = mClient.Send(dataBytes, dataBytes.Length, PacketPriority.HIGH_PRIORITY, PacketReliability.RELIABLE_ORDERED, (char)0, m_serverAddress, false);
            mClient.Send(dataBytes, dataBytes.Length, PacketPriority.HIGH_PRIORITY, PacketReliability.RELIABLE_ORDERED, (char)0, m_serverAddress, false);
        }

        #endregion

        #region Handle Network Error

        void AlreadyConnected()
        {

        }

        void ConnectionLost()
        {

        }

        void ConnectionFailed()
        {

        }

        #endregion

        #region Handle Log Message

        /// <summary>
        /// 输入日志信息
        /// </summary>
        /// <param name="format"></param>
        /// <param name="paramArray"></param>
        private void LogMessageFormat(string format, params object[] paramArray)
        {
            LogMessage(string.Format(format, paramArray));
        }

        /// <summary>
        /// 输出日志
        /// </summary>
        /// <param name="message">日志内容</param>
        private void LogMessage(string message)
        {
#if !NETWORK_DEBUG
            Debug.Log(message);
#endif
        }

        #endregion

        #region Handle Dispose

        public void Dispose()
        {
            m_MessageParserDict.Clear();
        }

        #endregion
    }
}