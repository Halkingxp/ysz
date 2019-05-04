using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;
using Common;
using Common.AssetSystem;

public class BuildScript
{
    public static void EncryptFiles(string outputPath)
    {
        if (AppDefineConst.IsEncrypted)
        {
            DirectoryInfo rootFolder = new DirectoryInfo(outputPath);
            if (rootFolder.Exists)
            {
                EditorUtility.DisplayProgressBar("Encrypt Asset", "Encrypt Asset...", 0);
                FileInfo[] fileInfos = rootFolder.GetFiles("*.*", SearchOption.AllDirectories);
                if (fileInfos.Length > 0)
                {
                    float delta = 100f / fileInfos.Length;
                    for (int i = 0; i < fileInfos.Length; i++)
                    {
                        FileInfo fileInfo = fileInfos[i];
                        if (fileInfo.Extension == ".meta" || fileInfo.Extension == ".manifest")
                            continue;
                        byte[] fileContent = FileUtility.ReadFileBytes(fileInfo.FullName);
                        fileContent = Utility.AESEncrypt(fileContent, AppDefineConst.AssetSecretKey);
                        FileUtility.WriteBytesToFile(fileInfo.FullName, fileContent, fileContent.Length);
                        EditorUtility.DisplayProgressBar("Encrypt Asset", "Encrypt Asset...", (i + 1) * delta);
                    }
                    EditorUtility.ClearProgressBar();
                }
            }
            Debug.LogFormat("<color=#00ee00ff>Asset Encrypt complated! Path:{0}</color>", rootFolder.FullName);
        }
    }

    /// <summary>
    /// 刷新资源记录清单文件
    /// </summary>
    public static void RefreshAssetRecords(string outputPath)
    {
        string[] allAssetBundleNames = AssetDatabase.GetAllAssetBundleNames();

        List<AssetRecordInfo> assetRecordList = new List<AssetRecordInfo>();

        for (int i = 0; i < allAssetBundleNames.Length; ++i)
        {
            string manifestPath = outputPath + "/" + allAssetBundleNames[i] + ".manifest";
            string[] assetPaths = GetAssetsPathInAssetBundle(manifestPath);
            for (int j = 0; j < assetPaths.Length; ++j)
            {
                string path = assetPaths[j];
                if (path.EndsWith(".prefab")// 预制件
                    || path.EndsWith(".bytes") || path.EndsWith(".txt") || path.EndsWith(".xml") // 配置文件或者Lua文件
                    || path.EndsWith(".mp3") || path.EndsWith(".wav") || path.EndsWith(".ogg") // 音效文件
                    || path.EndsWith(".unity") // 场景文件
                   )
                {
                    string assetRecordKey = AssetRecordInfo.ToAssetRecordKey(path);
                    AssetRecordInfo info = new AssetRecordInfo(assetRecordKey, allAssetBundleNames[i]);
                    assetRecordList.Add(info);
                }
            }
        }

        StoreAssetRecordsToFile(outputPath, assetRecordList);
    }

    /// <summary>
    /// 写入记录文件
    /// </summary>
    /// <param name="outputPath"></param>
    /// <param name="assetRecordList"></param>
    public static void StoreAssetRecordsToFile(string outputPath, List<AssetRecordInfo> assetRecordList)
    {
        System.Text.StringBuilder sb = new System.Text.StringBuilder();
        for (int i = 0; i < assetRecordList.Count; i++)
        {
            sb.Append(string.Format("#${0}#@{1}", assetRecordList[i].AssetName, assetRecordList[i].AssetBundleName));
        }
        byte[] bytes = Utility.UTF8StringToBytes(Utility.StringToUTF8String(sb.ToString()));
        // 写入到本地初始化目录
        FileUtility.WriteBytesToFile(outputPath + "/" + AppDefineConst.AssetRecordsFileName, bytes, bytes.Length);
    }

    /// <summary>
    /// 从资源包的Manifest文件中获取到其包含的所有资源路径
    /// </summary>
    /// <param name="assetBundleManifestPath">资源包Manifest文件路径</param>
    /// <returns>所有资源的路径</returns>
    static string[] GetAssetsPathInAssetBundle(string assetBundleManifestPath)
    {
        if (!File.Exists(assetBundleManifestPath))
        {
            return new string[] { };
        }
        List<string> assetPaths = new List<string>();

        StreamReader sr = File.OpenText(assetBundleManifestPath);
        string line = sr.ReadLine();
        while (!string.IsNullOrEmpty(line))
        {
            if (line.Equals("Dependencies"))
            {
                break;
            }

            if (line.Contains("- Assets/"))
            {
                line = line.Substring(2);
                assetPaths.Add(line);
            }

            line = sr.ReadLine();
        }

        sr.Close();
        return assetPaths.ToArray();
    }

    #region Menu Items

    const string kSimulateAssetBundlesMenu = "Tools/AssetBundles/Simulate AssetBundles";

    [MenuItem(kSimulateAssetBundlesMenu)]
    public static void ToggleSimulateAssetBundle()
    {
        AssetBundleManager.SimulateAssetBundleInEditor = !AssetBundleManager.SimulateAssetBundleInEditor;
    }

    [MenuItem(kSimulateAssetBundlesMenu, true)]
    public static bool ToggleSimulateAssetBundleValidate()
    {
        Menu.SetChecked(kSimulateAssetBundlesMenu, AssetBundleManager.SimulateAssetBundleInEditor);
        return true;
    }

    /// <summary>
    /// 制作资源包
    /// </summary>
    [MenuItem("Tools/AssetBundles/Build AssetBundle")]
    public static void BuildAssetBundles()
    {
        string outputPath = Path.Combine(AppDefineConst.LOCAL_INIT_DATA_PATH, AppDefineConst.AssetBundlesPath);

        if (Directory.Exists(outputPath))
        {
            Directory.Delete(outputPath, true);
        }
        Directory.CreateDirectory(outputPath);

        BuildPipeline.BuildAssetBundles(outputPath, 0, EditorUserBuildSettings.activeBuildTarget);
        RefreshAssetRecords(outputPath);
        EncryptFiles(outputPath);
        Debug.Log("<color=#00ee00ff>Success to build assetbundles.</color>");
        AssetDatabase.Refresh(ImportAssetOptions.ForceUpdate);
    }

    /// <summary>
    /// 清理掉所有的Mainfest 文件
    /// </summary>
    [MenuItem("Tools/AssetBundles/Clear manifest files")]
    public static void ClearAllManifestFiles()
    {
        string outputPath = Path.Combine(AppDefineConst.LOCAL_INIT_DATA_PATH, AppDefineConst.AssetBundlesPath);

        //DirectoryInfo directoryInfo = new DirectoryInfo(outputPath);
        if (Directory.Exists(outputPath))
        {

            string[] manifestFileArray = Directory.GetFiles(outputPath, "*.manifest", SearchOption.AllDirectories);
            foreach (var manifestFile in manifestFileArray)
            {
                // 查找同名的
                string manifestMetaFile = manifestFile + ".meta";
                if (File.Exists(manifestMetaFile))
                {
                    File.Delete(manifestMetaFile);
                }
                if (File.Exists(manifestFile))
                {
                    File.Delete(manifestFile);
                }
            }
        }

        Debug.Log("<color=#00ee00ff>Success to clear manifest files.</color>");
        AssetDatabase.Refresh(ImportAssetOptions.ForceUpdate);
    }


    #endregion
}
