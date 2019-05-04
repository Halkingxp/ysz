using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

/// <summary>
/// Asset bundle 名称刷新帮助
/// </summary>
public class AssetBundleNameHandler
{
    #region 刷新UI 资源的AssetBundle 名称

    /// <summary>
    /// 刷新资源的AssetBundle 名称
    /// </summary>
    [MenuItem("Tools/Refresh AB Name/All Asset Bundle name", priority = 1)]
    public static void RefreshAssetBundleName()
    {
        RefreshUISpritesAssetBundleName();
        RefreshExportedUISpritePrefabAssetBundleName();
        RefreshAudioAssetBundleName();
    }

    /// <summary>
    /// 导出UISprite 的AssetBundleName
    /// </summary>
    [MenuItem("Tools/Refresh AB Name/UI Sprite Asset", priority = 11)]
    public static void RefreshUISpritesAssetBundleName()
    {
        // 需要处理掉开头的 Assets 路径
        if (Directory.Exists(EditorAppDefine.UIAssetRoot))
        {
            string[] fileFullNameArray = Directory.GetFiles(EditorAppDefine.UIAssetRoot, "*.*", SearchOption.AllDirectories);

            EditorUtility.DisplayProgressBar("设置AB名称", "正在设置AssetName名称中...", 0f);
            for (int index = 0; index < fileFullNameArray.Length; index++)
            {
                string fileFullName = fileFullNameArray[index];
                EditorUtility.DisplayProgressBar("设置AB名称", "正在设置AssetName名称中...", 1f * index / fileFullNameArray.Length);
                if (fileFullName.EndsWith(".meta"))
                {
                    continue;
                }

                string relativePath = FileUtil.GetProjectRelativePath(fileFullName);
                TextureImporter textureImporter = AssetImporter.GetAtPath(relativePath) as TextureImporter;
                if (textureImporter != null)
                {
                    if (textureImporter.textureType == TextureImporterType.Sprite)
                    {
                        if (!string.IsNullOrEmpty(textureImporter.spritePackingTag))
                        {
                            textureImporter.assetBundleName = "texture_" + textureImporter.spritePackingTag + EditorAppDefine.AssetBundleExtension;
                        }
                    }
                }
            }
            EditorUtility.ClearProgressBar();

            AssetDatabase.RemoveUnusedAssetBundleNames();
            AssetDatabase.Refresh(ImportAssetOptions.ForceUpdate);
        }
    }

    /// <summary>
    /// 导出UISprite 的AssetBundleName
    /// </summary>
    [MenuItem("Tools/Refresh AB Name/Clear UI Sprite Asset", priority = 55)]
    public static void ClearUISpritesAssetBundleName()
    {
        // 需要处理掉开头的 Assets 路径
        if (Directory.Exists(EditorAppDefine.UIAssetRoot))
        {
            string[] fileFullNameArray = Directory.GetFiles(EditorAppDefine.UIAssetRoot, "*.*", SearchOption.AllDirectories);

            EditorUtility.DisplayProgressBar("设置AB名称", "正在设置AssetName名称中...", 0f);
            for (int index = 0; index < fileFullNameArray.Length; index++)
            {
                string fileFullName = fileFullNameArray[index];
                EditorUtility.DisplayProgressBar("设置AB名称", "正在设置AssetName名称中...", 1f * index / fileFullNameArray.Length);
                if (fileFullName.EndsWith(".meta"))
                {
                    continue;
                }

                string relativePath = FileUtil.GetProjectRelativePath(fileFullName);
                TextureImporter textureImporter = AssetImporter.GetAtPath(relativePath) as TextureImporter;
                if (textureImporter != null)
                {
                    if (textureImporter.textureType == TextureImporterType.Sprite)
                    {
                        if (!string.IsNullOrEmpty(textureImporter.assetBundleName))
                        {
                            textureImporter.assetBundleName = "";
                        }
                    }
                }
            }
            EditorUtility.ClearProgressBar();

            AssetDatabase.RemoveUnusedAssetBundleNames();
            AssetDatabase.Refresh(ImportAssetOptions.ForceUpdate);
        }
    }

    /// <summary>
    /// 刷新导出Sprite 预制件 的AssetBundle名称
    /// </summary>
    [MenuItem("Tools/Refresh AB Name/UI Sprite Prefab", priority = 12)]
    public static void RefreshExportedUISpritePrefabAssetBundleName()
    {
        // 需要处理掉开头的 Assets 路径
        if (Directory.Exists(EditorAppDefine.UIExportSpritePrefabRoot))
        {
            string[] fileFullNameArray = Directory.GetFiles(EditorAppDefine.UIExportSpritePrefabRoot, "*.prefab", SearchOption.AllDirectories);

            EditorUtility.DisplayProgressBar("设置AB名称", "正在设置AssetName名称中...", 0f);
            for (int index = 0; index < fileFullNameArray.Length; index++)
            {
                string fileFullName = fileFullNameArray[index];
                EditorUtility.DisplayProgressBar("设置AB名称", "正在设置AssetName名称中...", 1f * index / fileFullNameArray.Length);
                string relativePath = FileUtil.GetProjectRelativePath(fileFullName);
                AssetImporter importer = AssetImporter.GetAtPath(relativePath) as AssetImporter;

                if (importer != null)
                {
                    GameObject asset = AssetDatabase.LoadAssetAtPath<GameObject>(relativePath);
                    if (asset != null)
                    {
                        // 尝试同它所在的图片资源包名
                        var spriteRenderer = asset.GetComponent<SpriteRenderer>();
                        if (spriteRenderer != null)
                        {
                            Sprite sprite = asset.GetComponent<SpriteRenderer>().sprite;
                            string spritePath = AssetDatabase.GetAssetPath(sprite);

                            TextureImporter textureImporter = AssetImporter.GetAtPath(spritePath) as TextureImporter;
                            if (textureImporter != null)
                            {
                                if (textureImporter.textureType == TextureImporterType.Sprite)
                                {
                                    if (!string.IsNullOrEmpty(textureImporter.spritePackingTag))
                                    {
                                        importer.assetBundleName = "sprite_" + textureImporter.spritePackingTag + EditorAppDefine.AssetBundleExtension;
                                        continue;
                                    }
                                }
                            }
                        }

                        importer.assetBundleName = asset.name + EditorAppDefine.AssetBundleExtension;
                    }
                }
            }
            EditorUtility.ClearProgressBar();

            AssetDatabase.RemoveUnusedAssetBundleNames();
            AssetDatabase.Refresh(ImportAssetOptions.ForceUpdate);
        }
    }

    /// <summary>
    /// 刷新音效资源名称
    /// </summary>
    [MenuItem("Tools/Refresh AB Name/Refresh Audio AB Name", priority = 21)]
    public static void RefreshAudioAssetBundleName()
    {
        // 需要处理掉开头的 Assets 路径
        if (Directory.Exists(EditorAppDefine.AudioAssetRoot))
        {
            string[] fileFullNameArray = Directory.GetFiles(EditorAppDefine.AudioAssetRoot, "*.*", SearchOption.AllDirectories);

            EditorUtility.DisplayProgressBar("设置音效AB名称", "正在设置AssetName名称中...", 0f);
            for (int index = 0; index < fileFullNameArray.Length; index++)
            {
                string fileFullName = fileFullNameArray[index];
                EditorUtility.DisplayProgressBar("设置音效AB名称", "正在设置AssetName名称中...", 1f * index / fileFullNameArray.Length);
                if (fileFullName.EndsWith(".meta"))
                {
                    continue;
                }

                string relativePath = FileUtil.GetProjectRelativePath(fileFullName);
                AudioImporter importer = AssetImporter.GetAtPath(relativePath) as AudioImporter;
                if (importer != null)
                {
                    string dirctoryName = Path.GetDirectoryName(relativePath).Replace('\\', '/');
                    int findIndex = dirctoryName.LastIndexOf('/');
                    if (findIndex != -1)
                    {
                        string abName = dirctoryName.Substring(findIndex + 1);
                        importer.assetBundleName = "audio_" + abName + EditorAppDefine.AssetBundleExtension;
                    }
                    else
                    {
                        importer.assetBundleName = Path.GetFileNameWithoutExtension(relativePath) + EditorAppDefine.AssetBundleExtension;
                    }
                }
            }
            EditorUtility.ClearProgressBar();

            AssetDatabase.RemoveUnusedAssetBundleNames();
            AssetDatabase.Refresh(ImportAssetOptions.ForceUpdate);
        }
    }

    /// <summary>
    /// 
    /// </summary>
    [MenuItem("Tools/Refresh AB Name/Refresh UI Prefab", priority = 23)]
    public static void RefreshUIPrefabAssetBundleBundleName()
    {
        // 需要处理掉开头的 Assets 路径
        if (Directory.Exists(EditorAppDefine.UIAssetRoot))
        {
            string[] fileFullNameArray = Directory.GetFiles(EditorAppDefine.UIAssetRoot, "*.prefab", SearchOption.AllDirectories);

            EditorUtility.DisplayProgressBar("设置界面AB名称", "正在设置AssetName名称中...", 0f);
            for (int index = 0; index < fileFullNameArray.Length; index++)
            {
                string fileFullName = fileFullNameArray[index];
                EditorUtility.DisplayProgressBar("设置界面AB名称", "正在设置AssetName名称中...", 1f * index / fileFullNameArray.Length);

                string relativePath = FileUtil.GetProjectRelativePath(fileFullName);
                AssetImporter importer = AssetImporter.GetAtPath(relativePath) as AssetImporter;
                if (importer != null)
                {
                    string abName = Path.GetFileNameWithoutExtension(fileFullName);
                    importer.assetBundleName = "prefab_" + abName + EditorAppDefine.AssetBundleExtension;
                }
            }
            EditorUtility.ClearProgressBar();

            AssetDatabase.RemoveUnusedAssetBundleNames();
            AssetDatabase.Refresh(ImportAssetOptions.ForceUpdate);
        }
    }

    #endregion
}