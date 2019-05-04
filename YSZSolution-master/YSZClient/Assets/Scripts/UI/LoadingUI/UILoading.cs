using UnityEngine;
using UnityEngine.UI;

/// <summary>
/// 加载UI数据
/// </summary>
public class LoadingUIData
{
    public LoadingUIData()
    {

    }

    public LoadingUIData(LoadingUIData data)
    {
        if (data != null)
        {
            this.TipsInfo = data.TipsInfo;
            this.ProgressValue = data.ProgressValue;
        }
    }

    public LoadingUIData(string tips, float value)
    {
        this.TipsInfo = tips;
        this.ProgressValue = value;
    }

    /// <summary>
    /// 提示信息
    /// </summary>
    public string TipsInfo { get; set; }

    private float m_ProgressValue = 0f;
    /// <summary>
    /// 进度值(0,1)
    /// </summary>
    public float ProgressValue
    {
        get { return m_ProgressValue; }
        set { m_ProgressValue = Mathf.Clamp01(value); }
    }
}

/// <summary>
/// 加载界面
/// </summary>
public class UILoading : WindowBase
{
    public static readonly string UIAssetName = "UILoading";

    static bool isDataUpdate = false;

    static LoadingUIData m_UIData = new LoadingUIData();

    /// <summary>
    /// 提示标签
    /// </summary>
    [SerializeField]
    Text m_TipsInfoText = null;

    /// <summary>
    /// 进度图片
    /// </summary>
    [SerializeField]
    Image m_ProgressValue = null;

    /// <summary>
    /// 进度条的滑块提示
    /// </summary>
    [SerializeField]
    RectTransform m_HandleRect = null;

    private float HandleAreaSize = 100f;
    /// <summary>
    /// 进度更新
    /// </summary>
    /// <param name="tip"></param>
    /// <param name="value"></param>
    public static void UpdateProgress(string tip, float value)
    {
        m_UIData.TipsInfo = tip;
        m_UIData.ProgressValue = value;
        isDataUpdate = true;
    }
    /// <summary>
    /// 进度更新
    /// </summary>
    /// <param name="tip"></param>
    /// <param name="currentValue"></param>
    /// <param name="maxValue"></param>
    public static void UpdateProgress(string tip, int currentValue, int maxValue)
    {
        if (maxValue < 1)
            maxValue = 1;
        UpdateProgress(tip, (float)currentValue / maxValue);
    }
    /// <summary>
    /// 进度更新
    /// </summary>
    /// <param name="currentValue"></param>
    /// <param name="maxValue"></param>
    public static void UpdateProgress(int currentValue, int maxValue)
    {
        UpdateProgress(m_UIData.TipsInfo, currentValue, maxValue);
    }

    protected override void WindowOpened()
    {
        base.WindowOpened();
        UpdateUIElement1();
    }

    static WindowNode openedWindowNode = null;

    /// <summary>
    /// 显示数据加载界面
    /// </summary>    
    public static void Show(System.Action<WindowNode> complatedCallBack = null)
    {
        if (openedWindowNode == null)
        {
            WindowNodeInitParam initParam = new WindowNodeInitParam(UIAssetName);
            initParam.NodeType = BaseNodeType.Loading;
            initParam.LoadComplatedCallBack = complatedCallBack;
            openedWindowNode = WindowManager.Instance.OpenWindow(initParam);
            HotFix.HotFixUpdate.HotfixProgressChangedEvent += HotFixUpdate_HotfixProgressChangedEvent;
        }
    }

    static void HotFixUpdate_HotfixProgressChangedEvent(object sender, HotFix.HotfixProgressChangedEventArgs e)
    {
        UpdateProgress(e.TipsContent, e.ProgressPercentage, 100);
    }

    /// <summary>
    /// 隐藏数据加载界面
    /// </summary>
    public static void Hide()
    {
        if (openedWindowNode != null)
        {
            HotFix.HotFixUpdate.HotfixProgressChangedEvent -= HotFixUpdate_HotfixProgressChangedEvent;
            WindowManager.Instance.CloseWindow(openedWindowNode, false);
            openedWindowNode = null;
        }
    }

    void UpdateUIElement1()
    {
        if (m_UIData != null)
        {
            if (m_TipsInfoText != null)
            {
                m_TipsInfoText.text = m_UIData.TipsInfo;
            }

            if (m_ProgressValue != null)
            {
                m_ProgressValue.fillAmount = m_UIData.ProgressValue;
            }

            if (m_HandleRect != null)
            {
                m_HandleRect.localPosition = new Vector3(HandleAreaSize * (m_UIData.ProgressValue - 0.5f), 0, 0);
            }
        }

        isDataUpdate = false;
    }

    // Use this for initialization
    protected override void Start()
    {
        if (WindowNode != openedWindowNode)
        {
            WindowManager.Instance.CloseWindow(WindowNode, false);
            return;
        }
        base.Start();
        if (m_TipsInfoText == null || m_ProgressValue == null || m_HandleRect == null)
        {
            Debug.LogError("Some ui element was null in LoadingUI script, please check it!");
            return;
        }

        RectTransform parentRect = m_HandleRect.parent as RectTransform;
        HandleAreaSize = parentRect.rect.size.x;
        UpdateUIElement1();
    }

    void Update()
    {
        if (isDataUpdate)
        {
            UpdateUIElement1();
        }
    }

}