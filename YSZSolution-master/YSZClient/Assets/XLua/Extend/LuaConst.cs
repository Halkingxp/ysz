using System.Collections;
using System.Collections.Generic;
using UnityEngine;
/// <summary>
/// lua 常用配置
/// </summary>
public class LuaConst
{
    /// <summary>
    /// lua逻辑代码目录
    /// </summary>
    public static string LuaDir = Application.dataPath + "/LuaScript/";
    /// <summary>
    /// lua热更目录
    /// </summary>
    public static string HotFixLuaDir = Application.persistentDataPath + "/Lua/";
    
    /// <summary>
    /// Lua 文件 在 Resources 路径中的相对路径
    /// </summary>
    public static string LuaDirInResources = "/Lua/";
    /// <summary>
    /// 存储文件夹
    /// </summary>
    public static string OSDir
    {
        get
        {
#if UNITY_STANDALONE
            return "Win";
#elif UNITY_ANDROID
            return "Android";
#elif UNITY_IPHONE
            return "IOS";
#else
            return "";
#endif
        }
    }

    /// <summary>
    /// lua 的 AB包名称
    /// </summary>
    public const string LuaAssetBundleName = "luascript.abc";
}