//***************************************************************
// 脚本名称：ConnectManager.cs
// 类创建人：周  波
// 创建日期：2017.02
// 功能描述：管理网络连接相关内容
//***************************************************************
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
namespace Net
{
    public class ConnectManager : Kernel<ConnectManager>
    {

        List<NetworkClient> clientList = new List<NetworkClient>();

        /// <summary>
        /// 获取客户端连接
        /// </summary>
        /// <param name="clientName">连接名称</param>
        /// <returns></returns>
        public NetworkClient FindNetworkClient(string clientName)
        {
            return clientList.Find(temp => temp.ClientName == clientName);
        }

        /// <summary>
        /// 创建客户端连接
        /// </summary>
        /// <param name="clientName">客服端名称</param>
        /// <param name="ipAddress">ip 地址</param>
        /// <param name="port">端口</param>
        public NetworkClient CreateNetworkClient(string clientName)
        {
            NetworkClient findItem = clientList.Find(temp => temp.ClientName == clientName);
            if (findItem == null)
            {
                findItem = new NetworkClient(clientName);
                clientList.Add(findItem);
            }
            return findItem;
        }

        /// <summary>
        /// 关闭客户端网络连接
        /// </summary>
        /// <param name="clientName">客户端名称</param>
        /// <returns></returns>
        public bool CloseNetworkClient(string clientName)
        {
            NetworkClient findItem = clientList.Find(temp => temp.ClientName == clientName);
            if (findItem != null)
            {
                findItem.DisConnect();
                clientList.Remove(findItem);
                findItem.Dispose();
                findItem = null;
                return true;
            }
            else
            {
                Debug.LogWarningFormat("Can't find NetworkClient with name[{0}], when you want to close it, please check it!", clientName);
                return false;
            }
        }

        public void CloseAllNetworkClient()
        {
            for (int i = 0; i < clientList.Count;)
            {
                var client = clientList[i];
                if (client != null)
                {
                    client.DisConnect();
                    clientList.RemoveAt(i);
                    client.Dispose();
                    client = null;
                }
                else
                {
                    i++;
                }
            }
            clientList.Clear();
        }

        /// <summary>
        /// 断开网络连接
        /// </summary>
        /// <param name="clientName">客户端名称</param>
        /// <returns></returns>
        public void DisconnectNetworkClient(string clientName)
        {
            NetworkClient findItem = clientList.Find(temp => temp.ClientName == clientName);
            if (findItem != null)
            {
                findItem.DisConnect();
            }
            else
            {
                Debug.LogWarningFormat("Can't find NetworkClient with name[{0}], when you want to disconnect it, please check it!", clientName);
            }
        }

        public void ConnectNetworkClient(string clientName, string ipAddress, ushort port, System.Action<bool> connectCallBack)
        {
            NetworkClient findItem = clientList.Find(temp => temp.ClientName == clientName);
            if (findItem != null)
            {
                if (findItem.IsConnectedServer == false)
                {
                    findItem.Connect(ipAddress, port, connectCallBack);
                }
            }
            else
            {
                Debug.LogWarningFormat("Can't find NetworkClient with name[{0}], when you want to connect it, please check it!", clientName);
            }
        }

        void Update()
        {
            for (int i = 0; i < clientList.Count; i++)
            {
                clientList[i].UpdateNetwork();
            }
        }

        /// <summary>
        /// 退出时断开所有的网络连接
        /// </summary>
        private void OnApplicationQuit()
        {
            for (int i = 0; i < clientList.Count; i++)
            {
                clientList[i].DisConnect();
                clientList[i].Dispose();
            }
        }

        public NetworkClient GetNetworkClient(string clientName)
        {
            NetworkClient findItem = clientList.Find(temp => temp.ClientName == clientName);
            return findItem;
        }
    }
}