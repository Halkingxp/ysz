using UnityEngine;

/// <summary>
/// 开关动画
/// </summary>
public class SwitchAnimation : MonoBehaviour
{
    /// <summary>
    /// 是否使用不缩放的时间
    /// </summary>
    [SerializeField]
    bool m_UseUnscaledTime = false;

    /// <summary>
    /// 开启状态持续时间
    /// </summary>    
    [SerializeField]
    float OnLastTime = 0.1f;

    /// <summary>
    /// 关闭状态持续时间
    /// </summary>
    [SerializeField]
    float OffLastTime = 0.1f;

    /// <summary>
    /// 开启状态的时候显示的对象
    /// </summary>
    [SerializeField]
    GameObject m_OnGameObject = null;

    /// <summary>
    /// 关闭状态的时候显示的对象
    /// </summary>
    [SerializeField]
    GameObject m_OffGameObject = null;

    [SerializeField]
    private int m_SwitchTimes = 0;
    /// <summary>
    /// 切换的次数(0 不限制闪烁次数)
    /// </summary>
    public int SwitchTimes
    {
        get { return m_SwitchTimes; }
        private set { m_SwitchTimes = value; }
    }

    /// <summary>
    /// 正在闪烁中
    /// </summary>
    bool isWorking = false;

    /// <summary>
    /// 当前是否是开启状态
    /// </summary>    
    [SerializeField]
    bool isOn = true;

    /// <summary>
    /// 开始播放开关效果动画
    /// </summary>
    /// <param name="switchTimes">切换的次数(0 不限制闪烁次数)</param>
    public void Play(int switchTimes = 0)
    {
        if (switchTimes < 0)
        {
            switchTimes = 0;
        }
        this.m_SwitchTimes = switchTimes;
        this.m_TempTime = 0;
        this.m_TempSwitchedTimes = 0;
        this.isWorking = true;
        this.isOn = true;
        RefreshSwitchDisplayGo();
    }

    /// <summary>
    /// 停止播放效果
    /// </summary>
    public void Stop()
    {
        this.m_TempTime = 0;
        this.m_TempSwitchedTimes = 0;
        this.isWorking = false;
        this.isOn = false;
        RefreshSwitchDisplayGo();
    }

    /// <summary>
    /// 临时时间
    /// </summary>
    float m_TempTime = 0;

    /// <summary>
    /// 已闪烁的次数
    /// </summary>
    int m_TempSwitchedTimes = 0;

    /// <summary>
    /// 重置状态显示对象
    /// </summary>
    void RefreshSwitchDisplayGo()
    {
        if (m_OnGameObject != null)
            m_OnGameObject.SetActive(isOn);

        if (m_OffGameObject != null)
            m_OffGameObject.SetActive(!isOn);
    }

    void Update()
    {
        if (isWorking)
        {
            if (m_UseUnscaledTime)
            {
                m_TempTime += Time.unscaledDeltaTime;
            }
            else
            {
                m_TempTime += Time.smoothDeltaTime;
            }

            if (isOn)
            {
                if (m_TempTime >= OnLastTime)
                {
                    isOn = false;
                    m_TempTime -= OnLastTime;
                    RefreshSwitchDisplayGo();
                }
            }
            else
            {
                if (m_TempTime >= OffLastTime)
                {
                    isOn = true;
                    m_TempTime -= OffLastTime;

                    RefreshSwitchDisplayGo();
                    // 完成了一次切换
                    m_TempSwitchedTimes += 1;

                    if (SwitchTimes > 0) // 判断是否完成
                    {
                        if (m_TempSwitchedTimes >= SwitchTimes)
                        {
                            Stop();// 切换完成
                        }
                    }
                }
            }
        }
    }

}
