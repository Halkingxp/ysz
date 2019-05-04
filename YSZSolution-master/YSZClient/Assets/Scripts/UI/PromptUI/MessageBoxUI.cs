//***************************************************************
// 脚本名称：MessageBox
// 类创建人：周  波
// 创建日期：2016.01
// 功能描述：通用提示框
//***************************************************************

using UnityEngine;
using UnityEngine.UI;
using System.Collections;
using System.Collections.Generic;

/// <summary>
/// 通用提示框
/// </summary>
public class MessageBoxUI : WindowBase
{
    public static readonly string UIAssetName = "MessageBoxUI";
    /// <summary>
    /// 关闭按钮
    /// </summary>
    [SerializeField]
    Button m_CloseButton = null;
    /// <summary>
    /// 整个关闭区域
    /// </summary>
    [SerializeField]
    Button m_CloseAreaButton = null;
    /// <summary>
    /// 确认按钮
    /// </summary>
    [SerializeField]
    Button m_OKButton = null;
    /// <summary>
    /// 取消按钮
    /// </summary>
    [SerializeField]
    Button m_CancelButton = null;
    /// <summary>
    /// 确认按钮描述
    /// </summary>
    [SerializeField]
    Text m_OKButtonText = null;
    /// <summary>
    /// 取消按钮描述
    /// </summary>
    [SerializeField]
    Text m_CancelButtonText = null;
    /// <summary>
    /// 提示title
    /// </summary>
    [SerializeField]
    Text m_TitleText = null;
    /// <summary>
    /// 提示类容
    /// </summary>
    [SerializeField]
    Text m_ContentText = null;
    /// <summary>
    /// 提示区域
    /// </summary>
    [SerializeField]
    RectTransform m_ContentArea = null;

    /// <summary>
    /// 使用倒计时
    /// </summary>
    bool m_UseCountDown = false;
    /// <summary>
    /// 倒计时时间
    /// </summary>
    float m_CountDown = 0;
    /// <summary>
    /// 按钮相应回调
    /// </summary>
    System.Action<MessageBoxResult> CallBack = null;
    /// <summary>
    /// 确认按钮Name
    /// </summary>
    string m_OkButtonName = "OK";
    /// <summary>
    /// 关闭区域是否启用
    /// </summary>
    bool m_EnableCloseArea = false;
    /// <summary>
    /// 提示内容最小高度
    /// </summary>
    const int ContentMinHeight = 350;


    /// <summary>
    /// 刷新数据
    /// </summary>
    /// <param name="windowData"></param>
    public override void RefreshWindowData(object windowData)
    {
        base.RefreshWindowData(windowData);
        MessageBoxData uiData = windowData as MessageBoxData;
        if (uiData == null)
        {
            return;
        }
        currentCountDownSecond = -1;
        m_CountDown = uiData.LastTime;
        m_UseCountDown = uiData.LastTime > 0;

        if (m_TitleText != null)
        {
            m_TitleText.text = uiData.Title;
        }

        if (m_ContentText != null)
        {
            m_ContentText.text = uiData.Content;
            m_ContentText.rectTransform.sizeDelta = new Vector2(m_ContentText.rectTransform.sizeDelta.x, Mathf.Max(ContentMinHeight - 60, m_ContentText.preferredHeight));
            m_ContentArea.sizeDelta = new Vector2(m_ContentArea.sizeDelta.x, Mathf.Max(ContentMinHeight, m_ContentText.preferredHeight + 60));
        }

        if (m_CancelButtonText != null)
        {
            m_CancelButtonText.text = uiData.CancelButtonName;
        }

        m_OkButtonName = uiData.OKButtonName;
        if (m_OKButtonText != null)
        {
            if (m_UseCountDown)
            {
                UpdateCountDownDisplay(m_CountDown);
            }
            else
            {
                m_OKButtonText.text = m_OkButtonName;
            }
        }
        this.CallBack = uiData.CallBack;
        this.m_EnableCloseArea = uiData.EnableCloseArea;

        SetUIButtonActiveByStyle(uiData.Style);
    }

    /// <summary>
    /// 设置UI风格样式
    /// </summary>
    /// <param name="style"></param>
    void SetUIButtonActiveByStyle(MessageBoxStyle style)
    {
        switch (style)
        {
            case MessageBoxStyle.OK:
                m_OKButton.gameObject.SetActive(true);
                m_CancelButton.gameObject.SetActive(false);
                m_CloseButton.gameObject.SetActive(false);
                break;
            case MessageBoxStyle.OKCancel:
                m_OKButton.gameObject.SetActive(true);
                m_CancelButton.gameObject.SetActive(true);
                m_CloseButton.gameObject.SetActive(false);
                break;
            case MessageBoxStyle.OKCancelClose:
                m_OKButton.gameObject.SetActive(true);
                m_CancelButton.gameObject.SetActive(true);
                m_CloseButton.gameObject.SetActive(true);
                break;
            case MessageBoxStyle.OKClose:
                m_OKButton.gameObject.SetActive(true);
                m_CancelButton.gameObject.SetActive(false);
                m_CloseButton.gameObject.SetActive(true);
                break;
        }
    }

    /// <summary>
    /// 按钮回调
    /// </summary>
    /// <param name="result"></param>
    void OnHandleButtonClick(MessageBoxResult result)
    {
        if (CallBack != null)
        {
            CallBack(result);
        }

        if (WindowManager.Instance != null)
        {
            WindowManager.Instance.CloseWindow(WindowNode, true);
        }
        else
        {
            Destroy(gameObject);
        }
    }


    int currentCountDownSecond = 0;
    /// <summary>
    /// 更新显示CD
    /// </summary>
    /// <param name="m_CountDown"></param>
    void UpdateCountDownDisplay(float m_CountDown)
    {
        int number = Mathf.CeilToInt(m_CountDown);
        if (currentCountDownSecond != number)
        {
            currentCountDownSecond = number;
            if (m_OKButtonText != null)
            {
                m_OKButtonText.text = string.Format("{0}({1})", m_OkButtonName, currentCountDownSecond);
            }
        }
    }

    /// <summary>
    /// 显示提示框
    /// </summary>
    /// <param name="uiData"></param>
    /// <param name="parent"></param>
    public static void Show(MessageBoxData uiData, WindowNode parent = null)
    {
        WindowNodeInitParam initParam = new WindowNodeInitParam(UIAssetName);

        if (uiData.LuaCallBack != null)
        {
            System.Action<MessageBoxResult> luaCallBack = (result) =>
            {
                uiData.LuaCallBack((int)result);
            };

            if (uiData.CallBack != null)
            {
                uiData.CallBack += luaCallBack;
            }
            else
            {
                uiData.CallBack = luaCallBack;
            }
        }


        if (parent != null)
        {
            initParam.ParentNode = parent;
        }
        else
        {
            initParam.NodeType = BaseNodeType.Propmt;
        }
        initParam.WindowData = uiData;
        WindowManager.Instance.OpenWindow(initParam);
    }

    protected override void Start()
    {
        base.Start();
        if (m_OKButton == null || m_CloseButton == null || m_CancelButton == null || m_CloseAreaButton == null || m_TitleText == null || m_ContentText == null)
        {
            Debug.LogError("Some ui element was null in MessageBox script, please check it!");
            return;
        }

        m_OKButton.onClick.AddListener(() => OnHandleButtonClick(MessageBoxResult.OK));
        m_CancelButton.onClick.AddListener(() => OnHandleButtonClick(MessageBoxResult.Cancel));
        m_CloseButton.onClick.AddListener(() => OnHandleButtonClick(MessageBoxResult.Close));
        m_CloseAreaButton.onClick.AddListener(() =>
        {
            if (m_EnableCloseArea)
                OnHandleButtonClick(MessageBoxResult.CloseArea);
        });
    }

    /// <summary>
    /// Update
    /// </summary>
    private void Update()
    {
        if (m_UseCountDown)
        {
            m_CountDown -= Time.deltaTime;
            UpdateCountDownDisplay(m_CountDown);
            if (m_CountDown <= 0)
            {
                m_UseCountDown = false;
                OnHandleButtonClick(MessageBoxResult.Close);
            }
        }
    }


}

/// <summary>
/// 操作返回结果
/// </summary>
public enum MessageBoxResult : int
{
    /// <summary>
    /// 返回结果
    /// </summary>
    OK = 1,
    /// <summary>
    /// 取消
    /// </summary>
    Cancel = 2,
    /// <summary>
    /// 关闭
    /// </summary>
    Close = 3,
    /// <summary>
    /// 关闭区域关闭
    /// </summary>
    CloseArea = 3,
}

/// <summary>
/// 提示框样式
/// </summary>
public enum MessageBoxStyle : int
{
    /// <summary>
    /// 确定
    /// </summary>
    OK = 1,
    /// <summary>
    /// 确定，取消
    /// </summary>
    OKCancel = 2,
    /// <summary>
    /// 确定，关闭
    /// </summary>
    OKClose = 3,
    /// <summary>
    /// 确定，取消，关闭
    /// </summary>
    OKCancelClose = 4,
}

/// <summary>
/// 提示框数据
/// </summary>
public class MessageBoxData
{
    public string Title { get; set; }

    public string Content { get; set; }

    /// <summary>
    /// 持续时间（0：不使用持续时间, 大于0 在确认按钮上显示持续时间）
    /// ex:OK(2) 每秒更新
    /// </summary>
    public int LastTime { get; set; }

    /// <summary>
    /// 对话框样式
    /// </summary>
    public MessageBoxStyle Style { get; set; }

    private string m_OKButtonName = "确定";

    /// <summary>
    /// 确定按钮名称
    /// </summary>
    public string OKButtonName
    {
        get { return m_OKButtonName; }
        set
        {
            if (!string.IsNullOrEmpty(value))
                m_OKButtonName = value;
        }
    }

    private string m_CancelButtonName = "取消";
    /// <summary>
    /// 取消按钮名称
    /// </summary>
    public string CancelButtonName
    {
        get { return m_CancelButtonName; }
        set
        {
            if (!string.IsNullOrEmpty(value))
                m_CancelButtonName = value;
        }
    }

    /// <summary>
    /// 关闭区域是否可用
    /// </summary>
    public bool EnableCloseArea { get; set; }

    /// <summary>
    /// 回掉处理
    /// </summary>
    public System.Action<MessageBoxResult> CallBack;

    /// <summary>
    /// Lua 的回调
    /// </summary>
    public System.Action<int> LuaCallBack;
}