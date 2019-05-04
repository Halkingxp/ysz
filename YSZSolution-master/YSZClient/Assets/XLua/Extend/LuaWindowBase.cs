/*
 * Tencent is pleased to support the open source community by making xLua available.
 * Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.
 * Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 * http://opensource.org/licenses/MIT
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using XLua;
using System;

/// <summary>
/// Lua UI节点
/// </summary>
[LuaCallCSharp]
public class LuaWindowBase : WindowBase
{
    public string ScriptName = "";
    public Injection[] injections;

    private Action luaStart;
    private Action luaUpdate;
    private Action luaOnDestroy;
    private Action luaWindowOpened;
    private Action luaWindowClosed;
    private Action<object> luaRefreshWindowData;

    private bool isStarted = false;
    private LuaTable scriptEnv;



    void CallLuaStart()
    {
        if (luaStart != null)
        {
            luaStart();
        }
    }

    void BindingLuaScript()
    {
        if (string.IsNullOrEmpty(ScriptName))
            return;
        byte[] luaContent = LuaManager.Instance.LoadCustomLuaFile(ScriptName);
        LuaEnv luaEnv = LuaManager.LuaEnv;
        scriptEnv = luaEnv.NewTable();
        LuaTable meta = luaEnv.NewTable();
        meta.Set("__index", luaEnv.Global);
        scriptEnv.SetMetaTable(meta);
        meta.Dispose();

        scriptEnv.Set("this", this);
        foreach (var injection in injections)
        {
            scriptEnv.Set(injection.name, injection.value);
        }

        luaEnv.DoString(Utility.BytesToUTF8String(luaContent), ScriptName, scriptEnv);

        Action luaAwake = scriptEnv.Get<Action>("Awake");
        scriptEnv.Get("Start", out luaStart);
        scriptEnv.Get("Update", out luaUpdate);
        scriptEnv.Get("OnDestroy", out luaOnDestroy);
        scriptEnv.Get("WindowOpened", out luaWindowOpened);
        scriptEnv.Get("WindowClosed", out luaWindowClosed);
        scriptEnv.Get("RefreshWindowData", out luaRefreshWindowData);

        if (luaAwake != null)
        {
            luaAwake();
        }

        if (isStarted)
        {
            CallLuaStart();
        }
    }


    protected override void WindowOpened()
    {
        base.WindowOpened();
        if (luaWindowOpened != null)
        {
            luaWindowOpened();
        }
    }

    protected override void WindowClosed()
    {
        base.WindowClosed();
        if (luaWindowClosed != null)
        {
            luaWindowClosed();
        }
    }

    public override void RefreshWindowData(object windowData)
    {
        base.RefreshWindowData(windowData);
        if (luaRefreshWindowData != null)
        {
            luaRefreshWindowData(windowData);
        }
    }

    public virtual void DelayInvoke(float delayTime, Action callBack)
    {
        if (delayTime > 0)
        {
            int delayID = GetCoroutineID();
            Coroutine cor = StartCoroutine(DelayCoroutine(delayID, delayTime, callBack));
            coroutineDict.Add(delayID, cor);
        }
        else
        {
            if (callBack != null)
                callBack();
        }
    }

    private int mCoroutineID = 0;
    private int GetCoroutineID()
    {
        mCoroutineID++;
        if (mCoroutineID == 100000)
            mCoroutineID = 1;
        return mCoroutineID;
    }

    Dictionary<int, Coroutine> coroutineDict = new Dictionary<int, Coroutine>();

    public void StopAllDelayInvoke()
    {
        foreach (var item in coroutineDict)
        {
            if (item.Value != null)
            {
                StopCoroutine(item.Value);
            }
        }
        coroutineDict.Clear();
    }

    protected IEnumerator DelayCoroutine(int delayID, float delayTime, Action callBack)
    {
        if (delayTime > 0)
            yield return new WaitForSeconds(delayTime);
        if (coroutineDict.ContainsKey(delayID))
        {
            if (callBack != null)
                callBack();
            coroutineDict[delayID] = null;
            coroutineDict.Remove(delayID);
        }
    }

    void Awake()
    {
        BindingLuaScript();
    }

    protected override void Start()
    {
        base.Start();
        isStarted = true;
        CallLuaStart();
    }

    void Update()
    {
        if (luaUpdate != null)
        {
            luaUpdate();
        }
    }

    void OnDestroy()
    {
        if (luaOnDestroy != null)
        {
            luaOnDestroy();
        }

        luaOnDestroy = null;
        luaUpdate = null;
        luaStart = null;

        if (scriptEnv != null)
        {
            scriptEnv.Dispose();
        }
        injections = null;
    }
}
