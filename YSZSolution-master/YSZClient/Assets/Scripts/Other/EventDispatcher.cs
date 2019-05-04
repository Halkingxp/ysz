using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EventDispatcher
{
    private static EventDispatcher m_Instance = null;

    private EventDispatcher()
    {

    }

    public static EventDispatcher Instance
    {
        get
        {
            if (m_Instance == null)
                m_Instance = new EventDispatcher();
            return m_Instance;
        }
    }


    private Dictionary<string, System.Action<object>> m_EventDict = new Dictionary<string, System.Action<object>>();

    /// <summary>
    /// 添加事件监听
    /// </summary>
    /// <param name="eventName"></param>
    /// <param name="listener"></param>
    public void AddEventListener(string eventName, System.Action<object> listener)
    {
        if (m_EventDict.ContainsKey(eventName))
        {
            m_EventDict[eventName] -= listener;
            m_EventDict[eventName] += listener;
        }
        else
        {
            m_EventDict[eventName] = listener;
        }
    }

    public void RemoveEventListener(string eventName)
    {
        if (m_EventDict.ContainsKey(eventName))
        {
            m_EventDict[eventName] = null;
        }
    }

    public void RemoveEventListener(string eventName, System.Action<object> listener)
    {
        if (m_EventDict.ContainsKey(eventName))
        {
            System.Action<object> findItem = m_EventDict[eventName];
            findItem -= listener;
            if (findItem == null)
            {
                m_EventDict.Remove(eventName);
            }
            else
            {
                m_EventDict[eventName] = findItem;
            }
        }
    }

    public void TriggerEvent(string eventType, object data)
    {
        if (m_EventDict.ContainsKey(eventType))
        {
            try
            {
                m_EventDict[eventType](data);
            }
            catch (System.Exception ex)
            {
                Debug.LogException(ex);
            }
        }
    }

    /// <summary>
    /// 清理掉所有的事件监听
    /// </summary>
    public void ClearAllEventListener()
    {
        m_EventDict.Clear();
        System.GC.Collect();
    }
}
