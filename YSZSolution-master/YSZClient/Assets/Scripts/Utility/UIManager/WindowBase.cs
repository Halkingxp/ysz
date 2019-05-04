//***************************************************************
// 脚本名称：WindowBase
// 类创建人：周  波
// 创建日期：2015.12
// 功能描述：
//***************************************************************
using UnityEngine;

/// <summary>
/// UI节点基类
/// </summary>
public class WindowBase : MonoBehaviour
{
    /// <summary>
    /// 自身的摄像机
    /// </summary>
    public Camera MyUICamera = null;
    /// <summary>
    /// 自身的Canvas 画布
    /// </summary>
    public Canvas MyCanvas = null;

    /// <summary>
    /// 是否使用界面灯光
    /// </summary>
    [SerializeField]
    bool IsUseUIReaderLight = false;

    #region WindowManager SetWindows



    internal void SetWindowIndex(int index)
    {
        if (MyUICamera != null)
            this.MyUICamera.depth = index + WindowManager.UICameraStartDepth;
        if (MyCanvas != null)
            this.MyCanvas.sortingOrder = index + WindowManager.CanvasStartSortOrder;
        this.transform.localPosition = index * WindowManager.UIPositionDelta;
    }

    /// <summary>
    /// 设置窗体节点
    /// </summary>
    /// <param name="windowNode"></param>
    internal void SetWindowNode(WindowNode windowNode)
    {
        WindowNode = windowNode;
    }

    #endregion

    public WindowNode WindowNode { get; private set; }

    /// <summary>
    /// 刷新界面数据
    /// </summary>
    /// <param name="windowData"></param>
    public virtual void RefreshWindowData(object windowData)
    {
    }

    /// <summary>
    /// 释放资源
    /// </summary>
    public virtual void Dispose()
    {
        WindowNode = null;
    }

    /// <summary>
    /// 窗体打开时调用(在窗体被创建出来后，显示的时候调用)
    /// </summary>
    protected virtual void WindowOpened()
    {
    }

    void AddUILight()
    {
        if (IsUseUIReaderLight)
        {
            if (WindowManager.Instance != null)
            {
                WindowManager.Instance.AddUILight();
            }
        }
    }

    void RemoveUILight()
    {
        if (IsUseUIReaderLight)
        {
            if (WindowManager.Instance != null)
            {
                WindowManager.Instance.RemoveUILight();
            }
        }
    }

    /// <summary>
    /// 窗体关闭时调用(在窗体被关闭的时候调用，隐藏的时候调用)
    /// </summary>
    protected virtual void WindowClosed()
    {

    }

    /// <summary>
    /// 获取脚本上的Camera 和 脚本上的Canvas 脚本
    /// </summary>
    protected virtual void Start()
    {
        if (MyUICamera == null)
        {
            MyUICamera = transform.GetComponentInChildren<Camera>();
        }
        if (MyCanvas == null)
        {
            MyCanvas = transform.GetComponentInChildren<Canvas>();
        }
        if (MyUICamera == null)
        {
            Debug.LogErrorFormat("Can't find UI Camera in Window[{0}], please check it!", this.GetType().Name);
        }
        if (MyCanvas == null)
        {
            Debug.LogErrorFormat("Can't find UI Canvas in Window[{0}], please check it!", this.GetType().Name);
        }
    }

    [System.Obsolete("Use WindowOpened method replace!")]
    protected void OnEnable()
    {
        AddUILight();
        WindowOpened();
    }

    [System.Obsolete("Use WindowClosed method replace!")]
    protected void OnDisable()
    {
        RemoveUILight();
        WindowClosed();
    }

}