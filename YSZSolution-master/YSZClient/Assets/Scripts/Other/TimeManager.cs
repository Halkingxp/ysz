//***************************************************************
// 脚本名称：TimeManager
// 类创建人：周  波
// 创建日期：2017.03
// 功能描述：倒计时脚本
//***************************************************************
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// 倒计时管理器
/// </summary>
[XLua.LuaCallCSharp]
public class TimeManager : Kernel<TimeManager>
{
    /// <summary>
    /// 倒计时数据
    /// </summary>
    class CountDownInfo
    {
        /// <summary>
        /// 关键字
        /// </summary>
        public string KeyName { get; set; }

        /// <summary>
        /// 倒计时
        /// </summary>
        public float CountDown { get; set; }

        /// <summary>
        /// 下一次更新时间
        /// </summary>
        public float NextCountDown { get; set; }

        /// <summary>
        /// 更新间隔
        /// </summary>
        public float NotifyInterval { get; set; }

        /// <summary>
        /// 更新通知回掉
        /// </summary>
        public System.Action<float> UpdateNotify { get; set; }

        /// <summary>
        /// 是否已经过时的
        /// </summary>
        public bool IsObsolete { get; internal set; }
    }

    List<CountDownInfo> m_CountDownInfoList = new List<CountDownInfo>();

    /// <summary>
    /// 
    /// </summary>
    /// <param name="countDown"></param>
    /// <param name="keyName"></param>
    /// <param name="notifyInterval">更新的最小频率为 0.1s 每次</param>
    public void StartCountDown(float countDown, string keyName, System.Action<float> updateCallBack, float notifyInterval = 1)
    {
        if (notifyInterval < 0.1f)
            notifyInterval = 0.1f;
        CountDownInfo item = new CountDownInfo();
        item.CountDown = item.NextCountDown = countDown;
        item.NotifyInterval = notifyInterval;
        item.KeyName = keyName;
        item.UpdateNotify = updateCallBack;
        m_CountDownInfoList.Add(item);
    }

    /// <summary>
    /// 延迟触发方法
    /// </summary>
    /// <param name="delayTime">延迟时间</param>
    /// <param name="action">触发的方法</param>
    public void DelayInvoke(float delayTime, System.Action action)
    {
        StartCoroutine(DelayCoroutine(delayTime, action));
    }

    /// <summary>
    /// 移除key倒计时
    /// </summary>
    /// <param name="keyName"></param>
    public void RemoveCountDown(string keyName)
    {
        CountDownInfo findItem = m_CountDownInfoList.Find((temp) => temp.KeyName == keyName);
        if (findItem != null)
        {
            findItem.IsObsolete = true;
            findItem.UpdateNotify = null;
        }
    }

    IEnumerator DelayCoroutine(float delayTime, System.Action callBack)
    {
        yield return new WaitForSeconds(delayTime);
        if (callBack != null)
            callBack();
    }

    private void Update()
    {
        if (m_CountDownInfoList.Count > 0)
        {
            float deltaTime = Time.deltaTime;
            for (int i = m_CountDownInfoList.Count - 1; i >= 0; i--)
            {
                CountDownInfo item = m_CountDownInfoList[i];
                item.CountDown -= deltaTime;
                if (item.CountDown <= item.NextCountDown)
                {
                    if (item.UpdateNotify != null && !item.IsObsolete)
                    {
                        item.UpdateNotify(item.NextCountDown);
                    }
                    if (item.CountDown <= 0 || item.IsObsolete)
                    {
                        item.UpdateNotify = null;
                        m_CountDownInfoList.RemoveAt(i);
                    }
                    else
                    {
                        item.NextCountDown -= item.NotifyInterval;
                        if (item.NextCountDown < 0)
                        {
                            item.NextCountDown = 0;
                        }
                    }
                }
            }
        }
    }

}
