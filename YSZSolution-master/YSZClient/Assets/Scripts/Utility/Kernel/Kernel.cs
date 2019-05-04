//***************************************************************
// 类名：核心对象基类
// 作者：钟汶洁
// 日期：2014.12
// 注意：如果子类实现了自己的Awake()，那么子类需要在自己的Awake()中调用一下AssignInstance()
//***************************************************************

using UnityEngine;
using System.Collections;

public abstract class Kernel<T> : MonoBehaviour where T : MonoBehaviour
{
    static T s_Instance;

    // 获取单键引用
    public static T Instance()
    {
        return s_Instance;
    }

    // 给静态实例赋值
    protected void AssignInstance()
    {
        if (s_Instance != null)
        {
            Debug.LogError("Kernel is created repeatly!");
            Object.Destroy(this);
            return;
        }
        else
        {
            s_Instance = gameObject.GetComponent<T>();
        }
    }

    void Awake()
    {
        // 如果子类实现了自己的Awake()，那么子类需要在自己的Awake()中调用一下AssignInstance()
        AssignInstance();
    }
}
