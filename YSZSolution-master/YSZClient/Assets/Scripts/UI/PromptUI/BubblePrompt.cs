//***************************************************************
// 脚本名称：BubblePrompt.cs
// 类创建人：周  波
// 创建日期：2017.03
// 功能描述：气泡提示信息界面
//***************************************************************
using UnityEngine;
using System.Collections.Generic;
using UnityEngine.UI;

/// <summary>
/// 泡泡提示信息数据
/// </summary>
public class BubblePromptInfo
{
    /// <summary>
    /// 提示信息
    /// </summary>
    /// <param name="content">内容</param>
    /// <param name="owner">所属者</param>
    public BubblePromptInfo(string content, string owner)
    {
        this.Content = content;
        this.Owner = owner;
        this.AllowRepeat = false;
        this.Position = Vector3.zero;
    }

    /// <summary>
    /// 提示内容
    /// </summary>
    public string Content { get; set; }

    /// <summary>
    /// 位置点
    /// </summary>
    public Vector3 Position { get; set; }

    private float m_LastTime = 1.5f;
    /// <summary>
    /// 持续时间
    /// </summary>
    public float LastTime
    {
        get { return m_LastTime; }
        set { m_LastTime = Mathf.Max(value, 0.2f); }
    }

    private int m_Style = 1;
    /// <summary>
    /// 样式
    /// </summary>
    public int Style
    {
        get { return m_Style; }
        set { m_Style = Mathf.Max(value, 1); }
    }


    private int m_Priority = 0;
    /// <summary>
    /// 优先级别
    /// </summary>
    public int Priority
    {
        get { return m_Priority; }
        set { m_Priority = Mathf.Clamp(value, 0, 5); }
    }

    /// <summary>
    /// 保留时间
    /// </summary>
    public float HoldTime { get; set; }

    private float m_Interval = 0.5f;
    /// <summary>
    /// 间隔时间
    /// </summary>
    public float Interval
    {
        get { return m_Interval; }
        set { m_Interval = Mathf.Max(value, 0); }
    }

    /// <summary>
    /// 是否允许重复
    /// </summary>
    public bool AllowRepeat { get; set; }

    /// <summary>
    /// 所属者
    /// </summary>
    public string Owner { get; set; }

    /// <summary>
    /// 提示的对应GameObject
    /// </summary>
    public BubblePromptItem PromptItem { get; set; }
}

/// <summary>
/// 气泡提示
/// </summary>
public class BubblePrompt : WindowBase
{
    public readonly static string UIAssetName = "BubblePrompt";

    [SerializeField]
    BubblePromptItem[] styleRelativeItem = null;

    [SerializeField]
    RectTransform promptParentRectTrans = null;

    [SerializeField]
    float bubbleInterval = 0.4f;

    static BubblePrompt m_Instance = null;

    static bool isCreated = false;

    static List<BubblePromptInfo> m_PromptInfos = new List<BubblePromptInfo>();

    static List<BubblePromptInfo> m_PlayedPromptInfos = new List<BubblePromptInfo>();

    /// <summary>
    /// 显示提示信息
    /// </summary>
    /// <param name="content">提示内容</param>
    /// <param name="owner">所属者</param>
    public static void Show(string content, string owner)
    {
        Show(content, owner, Vector3.zero);
    }

    /// <summary>
    /// 显示提示信息
    /// </summary>
    /// <param name="content">提示内容</param>
    /// <param name="owner">所属者</param>
    /// <param name="position">位置信息</param>
    public static void Show(string content, string owner, Vector3 position)
    {
        Show(new BubblePromptInfo(content, owner) { Position = position });
    }

    /// <summary>
    /// 显示提示信息
    /// </summary>
    /// <param name="promptInfo">提示信息</param>
    public static void Show(BubblePromptInfo promptInfo)
    {
        if (promptInfo == null)
            return;

        if (!promptInfo.AllowRepeat)
        {
            if (m_PromptInfos.Find(temp => temp.Content == promptInfo.Content) != null)
                return;

            if (m_PlayedPromptInfos.Find(temp => temp.Content == promptInfo.Content) != null)
                return;
        }

        //存在的时间 = 持续时间 + 保持时间
        promptInfo.HoldTime = promptInfo.LastTime + promptInfo.HoldTime;

        if (m_PromptInfos.Count > 0)
        {
            bool isInserted = false;
            for (int index = m_PromptInfos.Count - 1; index >= 0; index--)
            {
                if (m_PromptInfos[index].Priority >= promptInfo.Priority)
                {
                    m_PromptInfos.Insert(index + 1, promptInfo);
                    isInserted = true;
                    break;
                }
            }
            if (!isInserted)
            {
                m_PromptInfos.Insert(0, promptInfo);
            }
        }
        else
        {
            m_PromptInfos.Add(promptInfo);
        }

        OpenBubblePrompt();
    }

    /// <summary>
    /// 清除掉指定所属者的提示信息
    /// </summary>
    /// <param name="owner">所属者</param>
    public static void ClearPrompt(string owner)
    {
        m_PromptInfos.RemoveAll(temp => temp.Owner == owner);
        for (int i = m_PlayedPromptInfos.Count - 1; i >= 0; i--)
        {
            if (m_PlayedPromptInfos[i].Owner == owner)
            {
                if (m_PlayedPromptInfos[i].PromptItem != null)
                {
                    m_PlayedPromptInfos[i].PromptItem.DestroyBubble();
                }
            }
            m_PlayedPromptInfos.RemoveAt(i);
        }
    }

    bool isWorking = false;

    /// <summary>
    /// 打开提示界面
    /// </summary>
    static void OpenBubblePrompt()
    {
        if (m_Instance == null && !isCreated)
        {
            isCreated = true;
            WindowNodeInitParam initParam = new WindowNodeInitParam(UIAssetName);
            initParam.NodeType = BaseNodeType.Tips;
            WindowManager.Instance.OpenWindow(initParam);
        }
    }

    /// <summary>
    /// UI 被开启
    /// </summary>
    protected override void WindowOpened()
    {
        base.WindowOpened();
        m_Instance = this;

    }

    /// <summary>
    /// UI 被关闭
    /// </summary>
    protected override void WindowClosed()
    {
        base.WindowClosed();
        m_PromptInfos.Clear();
        m_Instance = null;
        isCreated = false;
        m_PromptInfos.Clear();
        m_PlayedPromptInfos.Clear();
    }

    public void ShowBubble()
    {
        if (m_PromptInfos.Count > 0)
        {
            BubblePromptInfo info = m_PromptInfos[0];
            m_PromptInfos.RemoveAt(0);
            m_PlayedPromptInfos.Add(info);
            BubblePromptItem promptItem = null;
            if (styleRelativeItem.Length >= info.Style)
            {
                promptItem = styleRelativeItem[info.Style - 1];
            }
            else
            {
                promptItem = styleRelativeItem[0];
            }

            if (promptItem != null)
            {
                BubblePromptItem instanceItem = Instantiate<BubblePromptItem>(promptItem);
                Utility.ReSetTransform(instanceItem.transform, promptParentRectTrans);
                instanceItem.transform.localPosition = info.Position;
                instanceItem.SetBubblePromptItemInfo(info.Content, info.LastTime);
                info.PromptItem = instanceItem;
            }

            Invoke("ShowBubble", bubbleInterval);
        }
        else
        {
            isWorking = false;
        }
    }

    private void Update()
    {
        if (!isWorking)
        {
            if (m_PromptInfos.Count > 0)
            {
                isWorking = true;
                ShowBubble();
            }
        }

        if (m_PlayedPromptInfos.Count > 0)
        {
            for (int index = m_PlayedPromptInfos.Count - 1; index >= 0; index--)
            {
                m_PlayedPromptInfos[index].HoldTime -= Time.deltaTime;
                if (m_PlayedPromptInfos[index].HoldTime <= 0)
                {
                    m_PlayedPromptInfos.RemoveAt(index);
                }
            }
        }
    }

}
