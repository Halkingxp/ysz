using UnityEngine;

/// <summary>
/// 游戏管理器
/// </summary>
public class GameManager : Kernel<GameManager>
{
    bool m_isCutOut = false;

    /// <summary>
    /// 去掉游戏休眠
    /// </summary>
    /// <param name="focus"></param>
    void OnApplicationFocus(bool focus)
    {
        Screen.sleepTimeout = focus ? SleepTimeout.NeverSleep : SleepTimeout.SystemSetting;
    }

    void Start()
    {
        OnApplicationFocus(true);// 开始游戏运行到此时，游戏已调用OnApplicationFocus，此处补充调用一次
    }

    void OnApplicationPause(bool isPause)
    {
        if (isPause)
        {
            m_isCutOut = true;
            EventDispatcher.Instance.TriggerEvent("Application_CutOut", m_isCutOut);
        }
        else
        {

            if (m_isCutOut == false)
            {
                // 不做处理
            }
            else
            {
                m_isCutOut = false;
                EventDispatcher.Instance.TriggerEvent("Application_CutOut", m_isCutOut);
            }
        }
        EventDispatcher.Instance.TriggerEvent("OnApplicationPause", isPause);
    }

    /// <summary>
    /// 退出游戏
    /// </summary>
    private void OnApplicationQuit()
    {
        EventDispatcher.Instance.TriggerEvent("OnApplicationQuit", true);
    }
}