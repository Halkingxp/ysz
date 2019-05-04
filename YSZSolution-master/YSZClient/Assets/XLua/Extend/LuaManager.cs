//***************************************************************
// 脚本名称：LuaManager.cs
// 类创建人：周  波
// 创建日期：2017.02
// 功能描述：定义和管理Lua 相关内容
//***************************************************************
using System;
using System.IO;
using UnityEngine;
using XLua;
/// <summary>
/// lua全局管理器
/// </summary>
public class LuaManager : Common.ManagerBase<LuaManager>
{
    /// <summary>
    /// 上次GC 的时间
    /// </summary>
    internal static float lastGCTime = 0;
    /// <summary>
    /// GC 的时间间隔(s)
    /// </summary>
    internal const float GCInterval = 1;

    protected override void LaunchProcess(Action finished)
    {
        LuaEnv.AddLoader((ref string filename) =>
        {
            return LoadCustomLuaFile(filename);
        });
        base.LaunchProcess(finished);
    }

    protected override void LaunchFinished()
    {
        LuaEnv.DoString("require 'StartUp'", "LuaManager");
        base.LaunchFinished();
    }

    protected override void ShutdownProcess()
    {
        base.ShutdownProcess();
        CallMethod("StartUp", "Shutdown");
        if (LuaEnv != null)
        {
            LuaEnv.Global.Dispose();
            LuaEnv.Tick();
            LuaEnv.GC();
            LuaEnv = new LuaEnv();
        }
    }

    protected override void OnDestroy()
    {
        base.OnDestroy();
    }

    protected override void OnApplicationQuit()
    {
        base.OnApplicationQuit();
        LuaEnv = null;
    }

    /// <summary>
    /// 从缓存字典里加载
    /// </summary>
    /// <param name="fileName"></param>
    /// <returns></returns>
    byte[] LoadFormAssetBundle(string fileName)
    {
        string loadFileName = string.Empty;
        if (fileName.EndsWith(".lua"))
        {
            loadFileName = fileName;
        }
        else
        {
            loadFileName = fileName + ".lua";
        }
        int index = loadFileName.LastIndexOf('/');
        if (index != -1)
        {
            loadFileName = loadFileName.Substring(index + 1);
        }

        TextAsset asset = Common.AssetSystem.AssetBundleManager.Instance.LoadAsset<TextAsset>(loadFileName, false);
        if (asset != null)
            return asset.bytes;
        else
            return null;
    }

    /// <summary>
    /// 加载自定义的Lua文件
    /// </summary>
    /// <param name="luaFileName"></param>
    /// <returns></returns>
    public byte[] LoadCustomLuaFile(string filename)
    {
        // 从缓存中加载
        byte[] result = LoadFormAssetBundle(filename);
        if (result != null)
        {
            return result;
        }

        string loadFileName = string.Empty;
        if (filename.EndsWith(".lua"))
        {
            loadFileName = filename;
        }
        else
        {
            loadFileName = filename + ".lua";
        }

#if UNITY_EDITOR        
        // 从Lua原始目录加载
        string fileFullName = (LuaConst.LuaDir + "/" + loadFileName).Replace("//", "/");
        if (File.Exists(fileFullName))
        {
            return File.ReadAllBytes(fileFullName);
        }
        else
        {
            Debug.LogErrorFormat("Don't exsit lua file:[{0}]", fileFullName);
            return null;
        }
#else
        // 从Resource 目录加载
        string fileFullName = (LuaConst.LuaDirInResources + "/" + loadFileName).Replace("//", "/").TrimStart('/');
        // Load with Unity3D resources
        UnityEngine.TextAsset file = (UnityEngine.TextAsset)UnityEngine.Resources.Load(fileFullName);
        if (file != null)
        {
            return file.bytes;
        }
        else
        {
            Debug.LogErrorFormat("Custom lua resource path can't find lua file[{0}]", filename);
            return null;
        }


#endif

    }

    private static LuaEnv m_LuaEnv = new LuaEnv();

    public static LuaEnv LuaEnv
    {
        get { return m_LuaEnv; }
        private set { m_LuaEnv = value; }
    }

    void Update()
    {
        if (LuaEnv != null)
        {
            if (Time.time - lastGCTime > GCInterval)
            {
                if (LuaEnv != null)
                {
                    LuaEnv.Tick();
                    lastGCTime = Time.time;
                }
            }
        }
        if (null != UpdateEvent)
        {
            UpdateEvent(Time.deltaTime);
        }
    }


    public void StartUp()
    {
        CallMethod("StartUp", "Main");
    }

    public static event System.Action<float> UpdateEvent = null;

    /// <summary>
    /// 执行方法
    /// </summary>
    /// <param name="moduleName"></param>
    /// <param name="methodName"></param>
    /// <param name="args"></param>
    /// <returns></returns>
    public static object[] CallMethod(string moduleName, string methodName, params object[] args)
    {
        if (Instance != null)
        {
            LuaFunction func = LuaEnv.Global.GetInPath<LuaFunction>(string.Format("{0}.{1}", moduleName, methodName));
            if (func != null)
            {
                return func.Call(args);
            }
        }
        return null;
    }
}