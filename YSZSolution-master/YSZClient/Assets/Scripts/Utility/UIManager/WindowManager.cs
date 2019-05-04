//***************************************************************
// 脚本名称：WindowManager
// 类创建人：周  波
// 创建日期：2015.12
// 功能描述：管理窗体界面
//***************************************************************
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System;
using Common.AssetSystem;

public enum BaseNodeType
{
    /// <summary>
    /// 登陆，大厅，游戏等ui用此等级
    /// </summary>
    Main = 0,

    /// <summary>
    /// 跑马灯专用
    /// </summary>
    AboveMain = 1,

    /// <summary>
    /// 普通的界面，如Hall UI，Game UI，商城UI等等
    /// </summary>
    Normal = 2,
    /// <summary>
    /// Normal 界面层之上的一层
    /// </summary>
    AboveNormal = 3,
    /// <summary>
    /// 界面浮出提示信息
    /// </summary>
    Tips = 4,
    /// <summary>
    /// 进度条界面
    /// </summary>
    Loading = 5,
    /// <summary>
    /// 错误提示界面，，如断网提示等
    /// </summary>
    Propmt = 6,
}

public class WindowManager : MonoBehaviour
{
    [Tooltip("是否跨场景销毁")]
    public bool makePersistent = true;

    #region 常量

    public static readonly Vector3 UIPositionDelta = new Vector3(100, 100, 0);

    /// <summary>
    /// 画布开始排序的序号
    /// </summary>
    public const int CanvasStartSortOrder = 5;
    /// <summary>
    /// UI 相机开始的层级
    /// </summary>
    public const int UICameraStartDepth = 10;

    public const string UIRootAsset = "[UIRoot]";

    public static void InitWindowManager()
    {
        if (m_Instance == null)
        {
            GameObject go = Resources.Load<GameObject>(UIRootAsset);
            GameObject uiroot = Instantiate(go);
            uiroot.name = UIRootAsset;
            Utility.ReSetTransform(uiroot.transform, null);
        }
    }

    #endregion

    #region 定义根节点

    // 所有的界面挂的根节点
    [SerializeField]
    Transform m_UIParentTransform = null;

    // 隐藏界面的挂结点
    [SerializeField]
    Transform m_HideNodeTransform = null;

    // 根节点信息
    WindowNode[] m_RootWindowNodes = null;

    [SerializeField]
    Transform m_UILightTransform = null;

    #endregion

    private int m_UILightCount = 0;

    public void AddUILight()
    {
        m_UILightCount++;
        if (m_UILightCount > 0)
        {
            if (m_UILightTransform != null)
            {
                m_UILightTransform.gameObject.SetActive(true);
            }
        }
    }

    public void RemoveUILight()
    {
        m_UILightCount--;
        if (m_UILightCount < 0)
        {
            Debug.LogError("UILightCount less than 0, please check it!");
            m_UILightCount = 0;
        }
        if (m_UILightCount == 0)
        {
            if (m_UILightTransform != null)
            {
                m_UILightTransform.gameObject.SetActive(false);
            }
        }
    }

    #region Manager Private Data

    /// <summary>
    /// 所有的窗体界面信息界面
    /// </summary>
    List<WindowNode> m_WindowNodeList = new List<WindowNode>();

    /// <summary>
    /// 缓存资源界面池
    /// </summary>
    WindowPool m_WindowPool = new WindowPool();

    #endregion

    private static WindowManager m_Instance = null;

    #region Engine Callbacks

    void Awake()
    {
        CheckInstance();
        Init();
    }

    void Start()
    {
        if (makePersistent)
            DontDestroyOnLoad(this.gameObject);
    }

    // this is called after Awake() OR after the script is recompiled (Recompile > Disable > Enable)
    void OnEnable()
    {
        CheckInstance();
    }

    bool CheckInstance()
    {
        if (m_Instance == null)
        {
            m_Instance = this;
        }
        else if (m_Instance != this)
        {
            Debug.LogWarning("There is already an instance of WindowManager created (" + m_Instance.name + "). Destroying new one.");
            Destroy(this.gameObject);
            return false;
        }
        return true;
    }

    #endregion

    public static WindowManager Instance
    {
        get
        {
            if (m_Instance == null)
            {
                Debug.LogError("The instance was null of WindowManager, When you get it instance, please check it!");
            }
            return m_Instance;
        }
    }

    #region Init Base Window Node

    public void Init()
    {
        int max = (int)BaseNodeType.Propmt;
        m_RootWindowNodes = new WindowNode[max + 1];
        for (int i = 0; i <= max; i++)
        {
            WindowNode node = new WindowNode((BaseNodeType)i);
            m_WindowNodeList.Add(node);
            m_RootWindowNodes[i] = node;
        }
    }

    #endregion

    #region OpenWindow
    /// <summary>
    /// 开启UI
    /// </summary>
    /// <param name="windowName"></param>
    /// <param name="nodeType"></param>
    /// <returns></returns>
    public WindowNode OpenWindow(string windowName, BaseNodeType nodeType = BaseNodeType.Normal)
    {

        return OpenWindow(new WindowNodeInitParam(windowName) { NodeType = nodeType });
    }

    /// <summary>
    /// 开启UI
    /// </summary>
    /// <param name="windowName"></param>
    /// <param name="parentNode"></param>
    /// <returns></returns>
    public WindowNode OpenWindow(string windowName, WindowNode parentNode)
    {
        return OpenWindow(new WindowNodeInitParam(windowName) { ParentNode = parentNode });
    }
    /// <summary>
    /// 开启UI
    /// </summary>
    /// <param name="initParam"></param>
    /// <returns></returns>
    public WindowNode OpenWindow(WindowNodeInitParam initParam)
    {
        if (initParam == null)
            return null;
        if (initParam.ParentNode == null)
        {
            initParam.ParentNode = GetBaseWindowNodeByNodeType(initParam.NodeType);
        }
        WindowNode windowNode = new WindowNode(initParam);
        windowNode.ParentWindow = initParam.ParentNode;
        SetWindowNodeInfo(windowNode, initParam.NearNode, initParam.NearNodeIsPreNode);
        ResetAllWindowIndex();
        // 统计SDK
        EventDispatcher.Instance.TriggerEvent("OpenWindowEvent", initParam.WindowName);
        return windowNode;
    }
    /// <summary>
    /// 重置UI的WindowIndex
    /// </summary>
    void ResetAllWindowIndex()
    {
        for (int i = 0; i < m_WindowNodeList.Count; i++)
        {
            m_WindowNodeList[i].WindowIndex = i;
        }
    }

    /// <summary>
    /// 设置UI节点数据
    /// </summary>
    /// <param name="windowNode"></param>
    /// <param name="nearNode"></param>
    /// <param name="nearNodeIsPreNode"></param>
    void SetWindowNodeInfo(WindowNode windowNode, WindowNode nearNode, bool nearNodeIsPreNode)
    {
        WindowNode preNearNode = null;
        // 附近节点为空或者父节点不包括此附近节点
        if (nearNode == null || !windowNode.ParentWindow.ChildWindows.Contains(nearNode))
        {
            preNearNode = windowNode.ParentWindow.ChildWindows.Count == 0 ? windowNode.ParentWindow : windowNode.ParentWindow.ChildWindows[windowNode.ParentWindow.ChildWindows.Count - 1];
            while (preNearNode.ChildWindows.Count > 0)
            {
                preNearNode = preNearNode.ChildWindows[preNearNode.ChildWindows.Count - 1];
            }
            windowNode.ParentWindow.ChildWindows.Add(windowNode);
        }
        else
        {
            int index = windowNode.ParentWindow.ChildWindows.IndexOf(nearNode);
            if (!nearNodeIsPreNode)// 新节点在 靠近节点的后面
            {
                preNearNode = nearNode;
                index += 1;
            }
            else // 新的节点在靠近节点的前面
            {
                preNearNode = index == 0 ? windowNode.ParentWindow : windowNode.ParentWindow.ChildWindows[index - 1];
            }

            while (preNearNode.ChildWindows.Count > 0)
            {
                preNearNode = preNearNode.ChildWindows[preNearNode.ChildWindows.Count - 1];
            }
            windowNode.ParentWindow.ChildWindows.Insert(index, windowNode);
        }
        m_WindowNodeList.Insert(m_WindowNodeList.IndexOf(preNearNode) + 1, windowNode);
        SetWindowNodeGameObject(windowNode);
    }

    /// <summary>
    /// 获取WindowNode
    /// </summary>
    /// <param name="nodeType"></param>
    /// <returns></returns>
    WindowNode GetBaseWindowNodeByNodeType(BaseNodeType nodeType)
    {
        int value = (int)nodeType;
        if (value < m_RootWindowNodes.Length && value > -1)
            return m_RootWindowNodes[value];
        else
            return null;
    }

    /// <summary>
    /// 设置WindowNode数据
    /// </summary>
    /// <param name="windowNode"></param>
    void SetWindowNodeGameObject(WindowNode windowNode)
    {
        GameObject poolGameObject = m_WindowPool.GetWindowGameObject(windowNode.WindowName);
        if (poolGameObject != null)
        {
            SetWindowNodeGameObject(windowNode, poolGameObject);
        }
        else
        {
            StartCoroutine(LoadWindowGameObjectByWindowNode(windowNode));
        }
    }
    /// <summary>
    /// 加载WindowNode
    /// 
    /// </summary>
    /// <param name="windowNode"></param>
    /// <returns></returns>
    IEnumerator LoadWindowGameObjectByWindowNode(WindowNode windowNode)
    {
        AssetBundleManager assetBundleManager = AssetBundleManager.Instance;
        if (assetBundleManager == null)
        {
            Debug.LogErrorFormat("Load window asset[{0}] error[AssetBundleManager is null when window been loading]. windowNode[ID:{1}] be clear!", windowNode.WindowAssetName, windowNode.WindowName);
            CloseWindow(windowNode.WindowName, false, false);
            yield break;
        }
        LoadAssetAsyncOperation operation = assetBundleManager.LoadAssetAsync<GameObject>(windowNode.WindowAssetName, false);
        if (operation != null && !operation.IsDone)
        {
            yield return operation;
        }
        if (m_WindowNodeList.Contains(windowNode))
        {
            if (operation != null && operation.IsDone)
            {
                UnityEngine.Object resource = operation.GetAsset<UnityEngine.Object>();
                if (resource != null)
                {
                    GameObject windowGameObject = Instantiate(resource) as GameObject;
                    if (windowGameObject != null)
                    {
                        SetWindowNodeGameObject(windowNode, windowGameObject);
                    }
                    else
                    {
                        Debug.LogErrorFormat("Load window asset[{0}] error[Asset was not a gameObject]. windowNode[ID:{1}] be clear!", windowNode.WindowAssetName, windowNode.WindowName);
                        CloseWindow(windowNode.WindowName, false, false);
                    }
                }
                else
                {
                    Debug.LogErrorFormat("Load window asset[{0}] error[Asset was null]. windowNode[ID:{1}] be clear!", windowNode.WindowAssetName, windowNode.WindowName);
                    CloseWindow(windowNode.WindowName, false, false);
                }
            }
            else
            {
                Debug.LogErrorFormat("Load window asset[{0}] error. windowNode[ID:{1}] be clear!", windowNode.WindowAssetName, windowNode.WindowName);
                CloseWindow(windowNode.WindowName, false, false);
            }
        }
        else
        {
            // 在加载的过程中，本窗体已经被删除掉了
        }
    }

    /// <summary>
    /// 设置WindowNode父节点
    /// </summary>
    /// <param name="windowNode"></param>
    /// <param name="windowGameObject"></param>
    private void SetWindowNodeGameObject(WindowNode windowNode, GameObject windowGameObject)
    {
        Transform windowTransform = windowGameObject.transform;
        windowTransform.SetParent(m_UIParentTransform, false);
        windowTransform.name = windowNode.WindowName;
        windowNode.WindowGameObject = windowGameObject;
        //SetTransformSiblingIndex(windowNode, windowTransform);
        windowNode.WindowMonoBehaviour = windowTransform.GetComponent<WindowBase>();
        windowNode.ShowWindow();
    }

    /// <summary>
    /// 设置
    /// </summary>
    /// <param name="windowNode"></param>
    /// <param name="transform"></param>
    void SetTransformSiblingIndex(WindowNode windowNode, Transform transform)
    {
        int index = 0;
        for (int i = 0; i < m_WindowNodeList.Count; i++)
        {
            if (m_WindowNodeList[i].IsRootNode)
                continue;
            if (m_WindowNodeList[i] == windowNode)
            {
                break;
            }
            index++;
        }
        transform.SetSiblingIndex(index);
    }

    #endregion

    #region FindWindowNode

    /// <summary>
    /// 通过名称查找WindowNode
    /// </summary>
    /// <param name="windowName">窗口名称</param>
    /// <returns>返回同名窗体列表中，最后一个窗体ID的WindowNode，如果未找到则返回Null</returns>
    public WindowNode FindWindowNodeByName(string windowName)
    {
        return m_WindowNodeList.Find(temp => temp.WindowName == windowName);
    }

    /// <summary>
    /// 泛型查找
    /// </summary>
    /// <typeparam name="T"></typeparam>
    /// <returns></returns>
    public T FindWindowBaseByType<T>() where T : WindowBase
    {
        WindowNode node = m_WindowNodeList.Find(temp => temp.WindowMonoBehaviour is T);

        if (node != null)
            return node.WindowMonoBehaviour as T;
        else
            return null;
    }

    #endregion

    #region CloseWindow
    /// <summary>
    /// 关闭UI
    /// </summary>
    /// <param name="windowName"></param>
    /// <param name="isReleaseToPool"></param>
    /// <param name="isRemoveParentNode"></param>
    public void CloseWindow(string windowName, bool isReleaseToPool, bool isRemoveParentNode = false)
    {
        // 统计SDK
        WindowNode findNode = m_WindowNodeList.Find(temp => temp.WindowName == windowName);
        if (findNode == null)
            return;
        if (isRemoveParentNode)
        {
            while (!findNode.ParentWindow.IsRootNode)// 循环找父节点
            {
                findNode = findNode.ParentWindow;
            }
        }
        RemoveWindowNode(findNode, isReleaseToPool);
        ResetAllWindowIndex();
        EventDispatcher.Instance.TriggerEvent("CloseWindowEvent", windowName);
    }

    /// <summary>
    /// 清理Window Node 信息
    /// </summary>
    /// <param name="windowNode">窗体节点信息</param>
    void RemoveWindowNode(WindowNode windowNode, bool isReleaseToPool)
    {
        for (int index = windowNode.ChildWindows.Count - 1; index >= 0; index--)
        {
            RemoveWindowNode(windowNode.ChildWindows[index], isReleaseToPool);
        }

        windowNode.CloseWindow();
        if (windowNode.WindowGameObject != null)
        {
            if (isReleaseToPool)
            {
                windowNode.WindowGameObject.transform.SetParent(m_HideNodeTransform, false);
                m_WindowPool.ReleaseGameObject(windowNode.WindowName, windowNode.WindowGameObject);
            }
            else
            {
                Destroy(windowNode.WindowGameObject);
            }
        }

        windowNode.ParentWindow.ChildWindows.Remove(windowNode);// 从父节点删除当前结点
        windowNode.ParentWindow = null;
        m_WindowNodeList.Remove(windowNode);
        windowNode.ChildWindows.Clear();
        windowNode.WindowData = null;
        windowNode.WindowGameObject = null;
        windowNode = null;
    }

    /// <summary>
    /// 关闭窗体
    /// </summary>
    /// <param name="windowNode">窗体节点信息</param>
    /// <param name="isRemoveParentNode">是否关闭父节点</param>
    public void CloseWindow(WindowNode windowNode, bool isReleaseToPool = true, bool isRemoveParentNode = false)
    {
        if (windowNode == null)
            return;
        CloseWindow(windowNode.WindowName, isReleaseToPool, isRemoveParentNode);
    }

    /// <summary>
    /// 清除掉所有打开的界面
    /// </summary>
    /// <param name="unCloseWindowNames">不关闭的窗体</param>
    public void CloseAllWindows(List<string> unCloseWindowNames = null)
    {
        for (int i = 0; i < m_RootWindowNodes.Length; i++)
        {
            for (int j = m_RootWindowNodes[i].ChildWindows.Count - 1; j >= 0; j--)
            {
                if (unCloseWindowNames != null && unCloseWindowNames.Contains(m_RootWindowNodes[i].ChildWindows[j].WindowAssetName))
                {
                    continue;
                }
                RemoveWindowNode(m_RootWindowNodes[i].ChildWindows[j], false);
            }
        }
        ResetAllWindowIndex();
    }

    #endregion

    #region WindowPool

    public class WindowPool
    {
        public WindowPool()
        {
        }

        private Dictionary<string, GameObject> resourceDict = new Dictionary<string, GameObject>();

        public GameObject GetWindowGameObject(string windowName)
        {
            GameObject windowGameObject = null;
            if (resourceDict.ContainsKey(windowName))
            {
                windowGameObject = resourceDict[windowName];
                resourceDict.Remove(windowName);
            }
            return windowGameObject;
        }

        public bool ReleaseGameObject(string windowName, GameObject saveGameObject)
        {
            if (saveGameObject == null || string.IsNullOrEmpty(windowName)) return false;

            if (resourceDict.ContainsKey(windowName))
            {
                GameObject.Destroy(saveGameObject);
                return false;
            }
            else
            {
                resourceDict.Add(windowName, saveGameObject);
                return true;
            }
        }
    }

    #endregion


}

/// <summary>
/// 窗体初始化参数
/// </summary>
public class WindowNodeInitParam
{
    /// <summary>
    /// 初始化
    /// </summary>
    /// <param name="windowName">窗体名称</param>
    public WindowNodeInitParam(string windowName)
    {
        this.WindowAssetName = this.WindowName = windowName;
        NodeType = BaseNodeType.Normal;
        WindowData = null;
        LoadComplatedCallBack = null;
        ParentNode = null;
        NearNode = null;
        NearNodeIsPreNode = true;
    }
    /// <summary>
    /// 窗体名称
    /// </summary>
    public string WindowName { get; private set; }
    /// <summary>
    /// 窗体资源名称
    /// </summary>
    public string WindowAssetName { get; private set; }
    /// <summary>
    /// 所在的根节点类型
    /// </summary>
    public BaseNodeType NodeType { get; set; }
    /// <summary>
    /// 窗体数据
    /// </summary>
    public object WindowData { get; set; }
    /// <summary>
    /// 加载完成回调
    /// </summary>
    public System.Action<WindowNode> LoadComplatedCallBack { get; set; }
    /// <summary>
    /// 父节点
    /// </summary>
    public WindowNode ParentNode { get; set; }
    /// <summary>
    /// 靠近的节点
    /// </summary>
    public WindowNode NearNode { get; set; }
    /// <summary>
    /// 靠近的节点是否在当前结点之前
    /// </summary>
    public bool NearNodeIsPreNode { get; set; }
}
