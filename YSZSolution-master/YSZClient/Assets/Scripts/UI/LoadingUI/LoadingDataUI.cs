//***************************************************************
// 脚本名称：LoadingDataUI
// 类创建人：周  波
// 创建日期：2016.01
// 功能描述：
//***************************************************************
using UnityEngine;
using System.Collections;
using UnityEngine.UI;

public class LoadingDataUI : WindowBase
{
    public readonly static string UIAssetName = "LoadingDataUI";

    [SerializeField]
    Transform m_AnimationTransform;

    private float rotateAngle = -30;

    static WindowNode openedWindowNode = null;

    /// <summary>
    /// 显示数据加载界面
    /// </summary>
    /// <param name="timeOut"></param>
    /// <param name="timeOutCallBack"></param>
    public static void Show(int timeOut = 5, System.Action timeOutCallBack = null)
    {
        if (openedWindowNode == null)
        {
            WindowNodeInitParam initParam = new WindowNodeInitParam(UIAssetName);
            initParam.NodeType = BaseNodeType.AboveNormal;
            LoadingDataUIData uiData = new LoadingDataUIData();
            uiData.MaxLastTime = timeOut;
            uiData.MaxTimeCloseWindowCallBack = timeOutCallBack;
            initParam.WindowData = uiData;
            openedWindowNode = WindowManager.Instance.OpenWindow(initParam);            
        }
    }

    /// <summary>
    /// 隐藏数据加载界面
    /// </summary>
    public static void Hide()
    {
        if (openedWindowNode != null)
        {
            WindowManager.Instance.CloseWindow(openedWindowNode, false);
            openedWindowNode = null;
        }
    }

    protected override void WindowOpened()
    {
        this.m_AnimationTransform.localRotation = Quaternion.identity;
        base.WindowOpened();
    }

    protected override void WindowClosed()
    {
        base.WindowClosed();
        this.StartCountDown = false;
    }

    private float MaxLastTime = 10f;

    private System.Action MaxTimeCloseWindowCallBack = null;

    private float tempTime = 0;
    [SerializeField]
    float updateInterval = 0.3f;

    public bool StartCountDown = false;

    /// <summary>
    /// 内容文本
    /// </summary>
    [SerializeField]
    Text m_ContentText = null;

    public override void RefreshWindowData(object windowData)
    {
        base.RefreshWindowData(windowData);
        if (windowData is LoadingDataUIData)
        {
            LoadingDataUIData loadingDataUIData = (LoadingDataUIData)windowData;
            this.m_ContentText.text = loadingDataUIData.TipsContent;
            MaxLastTime = loadingDataUIData.MaxLastTime;
            this.MaxTimeCloseWindowCallBack = loadingDataUIData.MaxTimeCloseWindowCallBack;
            StartCountDown = true;
        }
    }

    void Update()
    {
        if (m_AnimationTransform != null)
        {
            tempTime += Time.unscaledDeltaTime;
            if (tempTime > updateInterval)
            {
                tempTime = tempTime % updateInterval;
                m_AnimationTransform.Rotate(new Vector3(0, 0, rotateAngle));
            }
        }

        if (StartCountDown)
        {
            MaxLastTime -= Time.unscaledDeltaTime;
            if (MaxLastTime <= 0)
            {
                if (MaxTimeCloseWindowCallBack != null)
                {
                    MaxTimeCloseWindowCallBack();
                }
                WindowManager.Instance.CloseWindow(this.WindowNode);
                openedWindowNode = null;
            }
        }
    }

}

/// <summary>
/// 加载数据界面的数据
/// </summary>
public class LoadingDataUIData
{
    public LoadingDataUIData()
    {
        MaxLastTime = 10;
    }

    /// <summary>
    /// 提示的内容
    /// </summary>
    public string TipsContent { get; set; }

    private int m_MaxLastTime = 10;

    /// <summary>
    /// 最大持续时间 多少秒(范围[1-20s],默认 10s)
    /// </summary>
    public int MaxLastTime
    {
        get { return m_MaxLastTime; }
        set
        {
            if (value < 1)
                value = 1;
            else if (value > 20)
                value = 20;
            m_MaxLastTime = value;
        }
    }

    /// <summary>
    /// 到达最大持续时间时关闭界面的回调
    /// </summary>
    public System.Action MaxTimeCloseWindowCallBack { get; set; }

}
