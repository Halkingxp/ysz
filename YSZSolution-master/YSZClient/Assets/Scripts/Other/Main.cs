//***************************************************************
// 脚本名称：
// 类创建人：
// 创建日期：
// 功能描述：
//***************************************************************
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using HotFix;
using UnityEngine.UI;
using Common.AssetSystem;

public class Main : MonoBehaviour
{
    [SerializeField]
    bool isOpenHotFix = true;

    [SerializeField]
    Text m_FirstHandleProgressTips = null;

    [SerializeField]
    public bool logEnabled = true;


    void Awake()
    {
        Debug.logger.logEnabled = logEnabled;
        // 游戏帧率设置
        Application.targetFrameRate = 30;
        // 清理掉所有的事件绑定
        EventDispatcher.Instance.ClearAllEventListener();
    }

    private void Start()
    {
        if (m_FirstHandleProgressTips != null)
        {
            m_FirstHandleProgressTips.gameObject.SetActive(false);
        }

        // 非编辑器模式，默认为开启热更新
#if !UNITY_EDITOR
        isOpenHotFix = true;
#endif

        StartCoroutine(StartUp());
    }

    private IEnumerator StartUp()
    {
        KernelManager kernelMgr = KernelManager.Instance();
        if (kernelMgr == null)
        {
            kernelMgr = new KernelManager();
        }
        HotFixUpdate hotFixUpdater = kernelMgr.AddKernel<HotFixUpdate>();
        if (!AppDefineConst.IsAppStartUped)
        {
            kernelMgr.AddKernel<GameManager>();
            kernelMgr.AddKernel<TimeManager>();
            WindowManager.InitWindowManager();

            if (isOpenHotFix)// 判断是否需要拷贝初始资源
            {
                HotFixUpdate.HotfixProgressChangedEvent += HotFixUpdate_HotfixProgressChangedEvent;
                yield return StartCoroutine(HotFixUpdate.Instance().TryUpdateAssetFromStreamingAssets());
                HotFixUpdate.HotfixProgressChangedEvent -= HotFixUpdate_HotfixProgressChangedEvent;
                if (m_FirstHandleProgressTips != null)
                {
                    m_FirstHandleProgressTips.gameObject.SetActive(false);
                }
            }
        }
        else
        {
            WindowManager.Instance.CloseAllWindows();
        }

        // 注册资源管理器
        AssetBundleManager assetBundleMgr = AssetBundleManager.Instance;
        while (!assetBundleMgr.IsReady)
        {
            yield return 1;
        }

        if (assetBundleMgr.LaunchFailed)
        {
            Application.Quit();
        }

        UILoading.Show();

        if (isOpenHotFix)
        {
            hotFixUpdater.TryStartUpdateRemoteAssetsToLocal();
            while (hotFixUpdater.IsWorking)
            {
                yield return 1;
            }
            // 更新管理器完成了
            if (hotFixUpdater.UpdaterState == HotFixUpdaterState.Done)
            {
                if (!hotFixUpdater.IsValidatedAssets)
                {
                    Debug.LogError("HotfixUpdate error, the assets was not validated!");
                    Application.Quit();
                    yield break;
                }
                // 有更新资源,需要重新加载资源管理器
                if (hotFixUpdater.IsLoadedNewAsset)
                {
                    WindowManager.Instance.CloseWindow(UILoading.UIAssetName, false);
                    HotFixUpdate_HotfixProgressChangedEvent(null, new HotfixProgressChangedEventArgs(50, "载入新的游戏资源..."));
                    AssetBundleManager.Instance.ReLaunch();
                    while (!AssetBundleManager.Instance.IsReady)
                    {
                        yield return 1;
                    }
                    if (AssetBundleManager.Instance.LaunchFailed)
                    {
                        Application.Quit();
                    }
                    UILoading.Show();
                }
            }
        }

        // 初始化网络管理器
        kernelMgr.AddKernel<Net.ConnectManager>();
        Net.ConnectManager.Instance().CloseAllNetworkClient();
        // 初始化对象池管理器
        LuaAsynFuncMgr.Instance.Init();
        // 初始化Lua管理器
        if (!AppDefineConst.IsAppStartUped)
            LuaManager.Instance.Launch();
        else
            LuaManager.Instance.ReLaunch();

        while (!LuaManager.Instance.IsReady)
        {
            yield return 1;
        }
        if (LuaManager.Instance.LaunchFailed)
        {
            Application.Quit();
        }
        yield return 1;
        LuaManager.Instance.StartUp();

        kernelMgr.DeleteKernel<HotFixUpdate>();
        GameObject.Destroy(this);

        GameObject splashObj = GameObject.Find("SplashUI");
        if (splashObj != null)
        {
            GameObject.Destroy(splashObj);
        }

        AppDefineConst.IsAppStartUped = true;
    }

    void HotFixUpdate_HotfixProgressChangedEvent(object sender, HotfixProgressChangedEventArgs e)
    {
        if (m_FirstHandleProgressTips != null)
        {
            m_FirstHandleProgressTips.gameObject.SetActive(true);
            m_FirstHandleProgressTips.text = e.TipsContent;
        }
    }
}