using Common.AssetSystem;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class LuaAsynFuncMgr : MonoBehaviour
{
    static LuaAsynFuncMgr m_instance;
    public static LuaAsynFuncMgr Instance
    {
        get
        {
            if (m_instance == null)
            {
                GameObject obj = new GameObject();
                m_instance = obj.AddComponent<LuaAsynFuncMgr>();
                obj.transform.position = Vector3.zero;
                obj.transform.rotation = Quaternion.Euler(0f, 0f, 0f);
                obj.transform.localScale = Vector3.one;
            }
            return m_instance;
        }
    }


    void Awake()
    {

    }

    // 初始化管理器
    public void Init()
    {

    }

    public void LoadAudioClip(string name, System.Action<AudioClip, string> callback)
    {
        StartCoroutine(ELoadAudioClip(name, callback));
    }

    IEnumerator ELoadAudioClip(string key, System.Action<AudioClip, string> callback)
    {
        AssetBundleManager assetBundleManager = AssetBundleManager.Instance;
        if (assetBundleManager == null)
        {
            Debug.LogErrorFormat("Load window asset[{0}] error[AssetBundleManager is null when window been loading]. windowNode[ID:{1}] be clear!", key, key);
        }

        LoadAssetAsyncOperation operation = assetBundleManager.LoadAssetAsync<AudioClip>(key, false);
        if (operation != null && !operation.IsDone)
        {
            yield return operation;
        }

        if (operation != null && operation.IsDone)
        {
            AudioClip resource = operation.GetAsset<AudioClip>();
            if (resource != null)
            {
                if (callback != null)
                {
                    callback(resource, key);
                }
            }
            else
            {
                Debug.LogErrorFormat("Load Audio asset[{0}] error[Asset was null]. ", key);
            }
        }
        else
        {
            Debug.LogErrorFormat("Load Audio asset[{0}] error.", key);
        }
    }

    public void HttpGet(string url, System.Action<string> callback)
    {
        StartCoroutine(SendGet(url, callback));
    }

    IEnumerator SendGet(string _url, System.Action<string> callback)
    {
        WWW getData = new WWW(_url);
        yield return getData;
        if (getData.text != null)
        {
            callback(getData.text);
        }
        else
        {
            callback(getData.error);
        }
    }

    public void HttpPost(string url, XLua.LuaTable table, System.Action<string> callback)
    {
        StartCoroutine(SendPost(url, table, callback));
    }

    IEnumerator SendPost(string url, XLua.LuaTable table, System.Action<string> callback)
    {
        WWWForm form = new WWWForm();
        var keys = table.GetKeys<string>();
        foreach (string key in keys)
        {
            print(string.Format("key = {0}, value = {1}", key, table.Get<string>(key)));
            form.AddField(key, table.Get<string>(key));
        }
        WWW getData = new WWW(url, form);
        yield return getData;
        print("getData.error = " + getData.error);
        print("getData.text = " + getData.text);
        if (getData.text != null)
        {
            callback(getData.text);
        }
        else
        {
            callback(getData.error);
        }
        
    }

    public string MakeJson(XLua.LuaTable table)
    {
        var keys = table.GetKeys<string>();
        Dictionary<string, string> tempdict = new Dictionary<string, string>();
        foreach (string key in keys)
        {
            print(string.Format("key = {0}, value = {1}", key, table.Get<string>(key)));
            tempdict.Add(key, table.Get<string>(key));
        }
        return MiniJSON.Json.Serialize(tempdict);
    }
}
