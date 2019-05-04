using UnityEngine;

/// <summary>
/// 程序固定基本信息定义
/// </summary>
public partial class AppDefineConst
{
    /// <summary>
    /// 是否已启动
    /// </summary>
    public static bool IsAppStartUped = false;

    /// <summary>
    /// 编译类型(用于区分不同的版本包更新资源,1金花赢三张 2百家赢三张 3爆炸赢三张 4 发发赢三张 5 发哥赢三张)
    /// </summary>
    public static string CompileType = "1";

    /// <summary>
    /// 远程资源的根目录
    /// </summary>
    public static string m_RemoteUrl = "http://jhysz.update.changlaith.com/UAssets";                // 正式包资源更新地址
    //public static string m_RemoteUrl = "http://jhysz.v10101up.changlaith.com/UAssets";                // ios审核服资源更新地址

    /// <summary>
    /// 游戏官网
    /// </summary>
    //public static string GameUrl = "http://www.clysz.game.changlaith.com/downloadurl/download.php?gameID=1";
    public static string GameUrl = "http://www.clysz.game.changlaith.com/downpage/new_version.php";

    /// <summary>
    /// 分享链接参数GameID(决定玩家分享属于哪个游戏编号)(1金花赢三张 2百家赢三张 3爆炸赢三张 4 发发赢三张 5 发哥赢三张)
    /// </summary>
    public static int GameID = 1;

    /// <summary>
    /// 是否开启盛付通(1开启 0不开启)
    /// </summary>
    public static int IsOpenSFT = 0;

    /// <summary>
    /// 默认的选择的房间(0 大厅初始状态 1 闷鸡厅 2组局厅 3聚龙厅)
    /// </summary>
    public static int DefaultSelectType = 0;

    /// <summary>
    /// 游戏名称
    /// </summary>
    public static string APPName = "常来赢三张";


    /// <summary>
    /// 盛付通支付url
    /// 常来赢三张:http://www.pay.changlaith.com/Pay/snda/CreateAndPay.php
    /// </summary>
    public static string SFTPayUrl = "http://www.pay.changlaith.com/Pay/snda/CreateAndPay.php";

    /// <summary>
    /// 小棍支付url
    /// 常来赢三张:http://www.pay.changlaith.com/Pay/xiaogun/CreateOrder.php
    /// </summary>
    public static string XiaoGunPayUrl = "http://www.pay.changlaith.com/Pay/xiaogun/CreateOrder.php";

    /// <summary>
    /// 是否加密
    /// </summary>
    public static bool IsEncrypted = true;

    /// <summary>
    /// 是否开启热更
    /// </summary>
    public static bool OpenHotfix = true;

    /// <summary>
    /// 资源密码
    /// </summary>
    public static string AssetSecretKey = "207102htialyszjh";

    /// <summary>
    /// AB 资源所在路径位置
    /// </summary>
    public static string AssetBundlesPath = "AssetBundles";

    /// <summary>
    /// 资源清单的名称
    /// </summary>
    public static string AssetBundleManifestName
    {
        get { return AssetBundlesPath; }
    }

    /// <summary>
    /// 资源记录文件
    /// </summary>
    public static string AssetRecordsFileName
    {
        get { return "AssetRecords.bytes"; }
    }

    /// <summary>
    /// 资源包根目录--打包是使用到的路径
    /// </summary>
    public static string PrimitivesPath
    {
        get { return Application.dataPath + "/Primitives"; }
    }

    /// <summary>
    /// 获取平台字符串
    /// </summary>
    /// <returns></returns>
    static string GetPlatformString()
    {
#if UNITY_EDITOR
        switch (UnityEditor.EditorUserBuildSettings.activeBuildTarget)
        {
            case UnityEditor.BuildTarget.Android:
                return "Android";
            case UnityEditor.BuildTarget.iOS:
                return "IOS";
            case UnityEditor.BuildTarget.StandaloneWindows:
            case UnityEditor.BuildTarget.StandaloneWindows64:
            case UnityEditor.BuildTarget.StandaloneOSXIntel64:
            case UnityEditor.BuildTarget.StandaloneOSXIntel:
            case UnityEditor.BuildTarget.StandaloneOSXUniversal:
            case UnityEditor.BuildTarget.StandaloneLinux64:
            case UnityEditor.BuildTarget.StandaloneLinux:
            case UnityEditor.BuildTarget.StandaloneLinuxUniversal:
                return "Windows";
            default:
                return null;
        }
#else
        switch (Application.platform)
        {
            case RuntimePlatform.Android:
                return "Android";
            case RuntimePlatform.IPhonePlayer:
                return "IOS";
            case RuntimePlatform.WindowsPlayer:
            case RuntimePlatform.WindowsEditor:
            case RuntimePlatform.LinuxEditor:
            case RuntimePlatform.OSXEditor:
                return "Windows";
            default:
                return null;
        }
#endif
    }

    private static string m_PlatfromPath = GetPlatformString();
    /// <summary>
    /// 平台路径
    /// </summary>
    public static string PlatformPath
    {
        get { return m_PlatfromPath; }
    }

    /// <summary>
    /// 远程更新路径
    /// </summary>
    private static string m_Remote_Data_Path = string.Format("{0}/{1}/{2}", m_RemoteUrl, CompileType, PlatformPath);
    /// <summary>
    /// 远程更新数据根目录
    /// </summary>
    public static string REMOTE_DATA_PATH
    {
        get { return m_Remote_Data_Path; }
    }

    private static string m_Local_Init_Data_Path = string.Format("{0}/{1}", Application.streamingAssetsPath, PlatformPath);
    /// <summary>
    /// 本地初始数据根目录(streamingAssetsPath + PlatformPath)
    /// </summary>
    public static string LOCAL_INIT_DATA_PATH
    {
        get { return m_Local_Init_Data_Path; }
    }

    private static string m_Loacl_Data_Path = string.Format("{0}/{1}/{2}", Application.persistentDataPath, PlatformPath, "Cache/Data");
    /// <summary>
    /// 本地数据根目录
    /// </summary>
    public static string LOCAL_DATA_PATH
    {
        get { return m_Loacl_Data_Path; }
    }

    private static string m_Local_Temp_Path = string.Format("{0}/{1}/{2}", Application.persistentDataPath, PlatformPath, "Cache/Temp");
    /// <summary>
    /// 本地数据临时根目录
    /// </summary>
    public static string LOCAL_TEMP_PATH
    {
        get { return m_Local_Temp_Path; }
    }
}