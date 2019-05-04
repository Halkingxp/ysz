//***************************************************************
// 脚本名称：WindowNode
// 类创建人：周  波
// 创建日期：2015.12
// 功能描述：
//***************************************************************
using UnityEngine;
using System.Collections.Generic;
using System;

public class WindowNode
{
    private WindowBase m_WindowMonoBehaviour = null;
    /// <summary>
    /// 窗体脚本--设置窗体脚本的时候刷新脚本的 WindowNode
    /// </summary>
    public WindowBase WindowMonoBehaviour
    {
        get { return m_WindowMonoBehaviour; }
        set
        {
            if (value != null)
            {
                value.SetWindowNode(this);
            }
            m_WindowMonoBehaviour = value;
        }
    }

    /// <summary>
    /// 父窗体节点的ID
    /// </summary>
    public WindowNode ParentWindow { get; set; }

    private int m_WindowIndex = 0;
    public int WindowIndex
    {
        get { return m_WindowIndex; }
        set
        {
            if (value != m_WindowIndex)
            {
                m_WindowIndex = value;
                ResetWindowIndex(value);
            }
        }
    }

    /// <summary>
    /// 从新设置界面的顺序
    /// </summary>
    void ResetWindowIndex(int windowIndex)
    {
        if (WindowMonoBehaviour != null && WindowMonoBehaviour.isActiveAndEnabled)
        {
            WindowMonoBehaviour.SetWindowIndex(windowIndex);
        }
    }

    /// <summary>
    /// 是否根节点(区分虚拟根节点)
    /// </summary>
    public bool IsRootNode { get; private set; }

    /// <summary>
    /// 根节点类型，用于挂在那个节点下
    /// </summary>
    public BaseNodeType RootNodeType { get; set; }

    public WindowNode(BaseNodeType nodeType)
    {
        ChildWindows = new List<WindowNode>();
        WindowName = nodeType.ToString();
        RootNodeType = nodeType;
        IsRootNode = true;
    }

    public WindowNode(WindowNodeInitParam initParam)
    {
        ChildWindows = new List<WindowNode>();
        WindowName = initParam.WindowName;
        WindowAssetName = initParam.WindowAssetName;
        IsRootNode = false;
        m_WindowData = initParam.WindowData;
        ParentWindow = initParam.ParentNode;
        RootNodeType = initParam.ParentNode.RootNodeType;
        this.m_WindowLoadComplatedCallBack = initParam.LoadComplatedCallBack;
    }

    /// <summary>
    /// 窗体名称
    /// </summary>
    public string WindowName { get; private set; }
    /// <summary>
    /// 资源名称
    /// </summary>
    public string WindowAssetName { get; private set; }

    private object m_WindowData = null;
    /// <summary>
    /// 窗体的数据
    /// </summary>
    public object WindowData
    {
        get { return m_WindowData; }
        set
        {
            m_WindowData = value;
            RefreshWindowData(value);
        }
    }

    /// <summary>
    /// 窗体的对象
    /// </summary>
    public GameObject WindowGameObject { get; set; }

    /// <summary>
    /// 子节点
    /// </summary>
    public List<WindowNode> ChildWindows { get; private set; }

    /// <summary>
    /// 界面加载完成回调
    /// </summary>
    private System.Action<WindowNode> m_WindowLoadComplatedCallBack = null;

    /// <summary>
    /// 显示窗体
    /// </summary>
    public void ShowWindow()
    {
        if (WindowGameObject != null)
        {
            WindowGameObject.SetActive(true);
            ResetWindowIndex(m_WindowIndex);//刷新索引位置
            RefreshWindowData(WindowData);
            if (m_WindowLoadComplatedCallBack != null)
            {
                m_WindowLoadComplatedCallBack(this);
                m_WindowLoadComplatedCallBack = null;
            }
        }
    }

    /// <summary>
    /// 删除窗体
    /// </summary>
    public void CloseWindow()
    {
        if (WindowGameObject != null)
        {
            WindowGameObject.SetActive(false);
        }
        //清空事件列表
        m_WindowLoadComplatedCallBack = null;
    }

    /// <summary>
    /// 设置界面的数据
    /// 界面被创建出来后和被现实出时，会调用一次此函数
    /// </summary>
    /// <param name="data">窗体的值</param>
    protected void RefreshWindowData(object data)
    {
        if (WindowMonoBehaviour != null && WindowMonoBehaviour.isActiveAndEnabled)
        {
            WindowMonoBehaviour.RefreshWindowData(data);
        }
    }


}