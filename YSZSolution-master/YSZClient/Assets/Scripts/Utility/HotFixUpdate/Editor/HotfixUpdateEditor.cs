using Common;
using HotFix;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

/// <summary>
/// 热更新相关编辑功能
/// </summary>
public class HotfixUpdateEditor
{
    /// <summary>
    /// 忽略的文件后缀名称
    /// </summary>
    public static List<string> IgnoreFileExtensions = new List<string>() { ".meta" };

    /// <summary>
    /// 忽略的文件信息
    /// </summary>
    public static List<string> IgnoreFiles = new List<string>() { HotFixUpdate.FILERECORD_FILENAME, HotFixUpdate.VERSION_FILENAME };

    /// <summary>
    /// 生成热更新文件列表
    /// </summary>
    [MenuItem("Tools/HotfixUpdate/Generate File Records")]
    public static void GenerateHotfixFileRecords()
    {
        // 文件记录列表
        Dictionary<string, FileRecord> fileRecords = new Dictionary<string, FileRecord>();
        DirectoryInfo rootFolder = new DirectoryInfo(AppDefineConst.LOCAL_INIT_DATA_PATH);
        if (rootFolder.Exists)
        {
            FileInfo[] fileInfos = rootFolder.GetFiles("*.*", SearchOption.AllDirectories);
            foreach (FileInfo fileInfo in fileInfos)
            {
                if (IgnoreFileExtensions.Contains(fileInfo.Extension))
                {
                    continue;
                }
                if (IgnoreFiles.Contains(fileInfo.Name))
                {
                    continue;
                }
                string fileName = fileInfo.FullName.Replace("\\", "/").Replace(AppDefineConst.LOCAL_INIT_DATA_PATH.Replace("\\", "/"), "").TrimStart('/');
                string md5Hash = FileUtility.GetMD5HashOfFile(fileInfo.FullName);
                long fileSize = fileInfo.Length;
                if (!fileRecords.ContainsKey(fileName))
                {
                    fileRecords.Add(fileName, new FileRecord() { FileName = fileName, MD5 = md5Hash, Size = fileSize });
                }
                else
                {
                    Debug.LogErrorFormat("Have the same file[{0}] in asset, please check it!", fileName);
                }
            }
        }

        FileUtility.StoreFileRecords(FileUtility.GetAssetFilePath(HotFixUpdate.FILERECORD_FILENAME, PathType.InitData), fileRecords);
        Debug.Log("<color=#00ee00ff>Success to generate file records!</color>");
        AssetDatabase.Refresh(ImportAssetOptions.ForceUpdate);
    }

    /// <summary>
    /// 生成版本文件
    /// </summary>
    [MenuItem("Tools/HotfixUpdate/Generate Version File")]
    public static void GenerateVersionFile()
    {
        string version = string.IsNullOrEmpty(PlayerSettings.bundleVersion) ? "1.0.1" : PlayerSettings.bundleVersion;
        FileUtility.WriteTextToFile(FileUtility.GetAssetFilePath(HotFixUpdate.VERSION_FILENAME, PathType.InitData), version);
        Debug.Log("<color=#00ee00ff>Success to generate version flie!</color>");
        AssetDatabase.Refresh(ImportAssetOptions.ForceUpdate);
    }



    /// <summary>
    /// 拷贝文件到本地上传路径
    /// </summary>
    [MenuItem("Tools/HotfixUpdate/Copy file to Update Folder")]
    public static void CopyFilesToHotFixFolder()
    {
        // 本地上传更新根路径
        string localUpdateRootPath = Path.GetFullPath(Application.dataPath + "/../UpdateFiles/" + AppDefineConst.PlatformPath);

        if (Directory.Exists(localUpdateRootPath))
        {
            Directory.Delete(localUpdateRootPath, true);
        }

        // 创建文件夹
        Directory.CreateDirectory(localUpdateRootPath);

        DirectoryInfo rootFolder = new DirectoryInfo(AppDefineConst.LOCAL_INIT_DATA_PATH);
        if (rootFolder.Exists)
        {
            EditorUtility.DisplayProgressBar("Copy update assets", "Copy Update assets...", 0);
            FileInfo[] fileInfos = rootFolder.GetFiles("*.*", SearchOption.AllDirectories);
            if (fileInfos.Length > 0)
            {
                float delta = 100f / fileInfos.Length;
                for (int i = 0; i < fileInfos.Length; i++)
                {
                    FileInfo fileInfo = fileInfos[i];
                    if (fileInfo.Extension == ".meta")
                        continue;
                    string fileName = fileInfo.FullName.Replace("\\", "/").Replace(AppDefineConst.LOCAL_INIT_DATA_PATH.Replace("\\", "/"), "").TrimStart('/');

                    FileUtility.CopyFile(fileInfo.FullName, localUpdateRootPath + "/" + fileName);
                    EditorUtility.DisplayProgressBar("Copy update assets", "Copy Update assets...", (i + 1) * delta);
                }
                EditorUtility.ClearProgressBar();
            }
        }

        Debug.LogFormat("<color=#00ee00ff>Success to copy need update assets! Path:{0}</color>", localUpdateRootPath);
    }
}