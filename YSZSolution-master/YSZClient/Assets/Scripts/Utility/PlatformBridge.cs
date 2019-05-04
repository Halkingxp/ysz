//***************************************************************
// 脚本名称：PlatformBridge.cs
// 类创建人：hc
// 创建日期：2017.04
// 功能描述：用于和平台(ios, android)交互的桥梁类
//***************************************************************
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;

public class PlatformBridge : MonoBehaviour
{

    static PlatformBridge m_instance;
#if UNITY_IOS && !UNITY_EDITOR
    [DllImport("__Internal")]
    private static extern int iosBridge(int platformID, int functionEnum, string paramjson, string callbackGameObject, string callbackFunc);
#endif
    public static PlatformBridge Init()
    {
        // 在场景中创建同名的游戏对象,挂上本脚本
        if (m_instance == null)
        {
            GameObject obj = new GameObject();
            m_instance = obj.AddComponent<PlatformBridge>();
            obj.transform.position = Vector3.zero;
            obj.transform.rotation = Quaternion.Euler(0f, 0f, 0f);
            obj.transform.localScale = Vector3.one;
            obj.transform.name = "PlatformBridge";
        }
        return m_instance;
    }

    public int UnityCallPlatform(int platformID, int functionEnum, string paramjson)
    {
        try
        {
            Debug.Log("unity 调用 桥接器 UnityCallPlatform");
#if UNITY_IOS && !UNITY_EDITOR
            Debug.Log("调用apple objc接口");
            return iosBridge(platformID, functionEnum, paramjson, "PlatformBridge", "PlatformToUnity");
#endif

#if UNITY_ANDROID && !UNITY_EDITOR
            Debug.Log("调用android java接口");
            AndroidJavaClass jc = new AndroidJavaClass("com.unity3d.player.UnityPlayer");
	        AndroidJavaObject jo = jc.GetStatic<AndroidJavaObject>("currentActivity");
            return jo.Call<int>("androidBridge", platformID, functionEnum, paramjson);
#endif
            return 0;
        }
        catch (System.Exception ex)
        {
            Debug.LogException(ex);
            return 0;
        }
    }

    public void PlatformToUnity(string paramjson)
    {
        Debug.Log("平台回调unity桥接器方法 paramjson = " + paramjson);
        // 解析json 转换为lua的table
        Dictionary<string, object> dict = MiniJSON.Json.Deserialize(paramjson) as Dictionary<string, object>;
        if (dict == null || dict.Count == 0)
        {
            print("解析sdk传回的json出错");
            return;
        }
        var table = LuaManager.LuaEnv.NewTable();
        foreach (var item in dict)
        {
            print(string.Format("key = {0}, value = {1}", item.Key, item.Value));
            table.Set(item.Key, item.Value);
        }
        // 传回到lua 
        LuaManager.CallMethod("PlatformBridge", "CallBackFunc", table);
    }
}
