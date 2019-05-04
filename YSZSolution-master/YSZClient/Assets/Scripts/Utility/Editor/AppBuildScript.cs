using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System;

/// <summary>
/// 集成工具的编译功能，便于打包程序
/// </summary>
public class AppBuildScript : MonoBehaviour
{
    [MenuItem("BuildApk/Step1(Clear Lua)", priority = 10)]
    static void BuildStepOne()
    {
        // 清理当前资源相关内容        
        CSObjectWrapEditor.Generator.ClearAll();
        LuaBuildScript.ClearAllCopyedLuaFiles();
    }

    [MenuItem("BuildApk/Step2(Gen Lua)", priority = 20)]
    static void BuildStepTwo()
    {
        CSObjectWrapEditor.Generator.GenAll();
        LuaBuildScript.CopyLuafliesAndResetLuaAssetBundleNames();
    }

    [MenuItem("BuildApk/Step3(Create ab and base files)", priority = 30)]
    static void BuildStepThree()
    {
        AssetBundleNameHandler.RefreshAssetBundleName();
        BuildScript.BuildAssetBundles();
        BuildScript.ClearAllManifestFiles();
        HotfixUpdateEditor.GenerateHotfixFileRecords();
        HotfixUpdateEditor.GenerateVersionFile();
    }

    [MenuItem("BuildApk/Step4(Copy hotfix files)", priority = 40)]
    static void BuildStepFour()
    {
        HotfixUpdateEditor.CopyFilesToHotFixFolder();
    }
}