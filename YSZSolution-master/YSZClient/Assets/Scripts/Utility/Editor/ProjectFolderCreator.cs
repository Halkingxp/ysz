//***************************************************************
// 脚本名称：ProjectFolderCreator
// 类创建人：周  波
// 创建日期：2016.03
// 功能描述：创建文件夹
//***************************************************************
using UnityEngine;
using UnityEditor;
using System.IO;
using System.Collections;

public class ProjectFolderCreator
{
    /// <summary>
    /// UI 的标准文件夹
    /// </summary>
    static string[] UIAssetSubFolders = new string[] { "Prefab", "UIAtlas" };
    /// <summary>
    /// 地形文件夹
    /// </summary>
    static string[] TerrainSubFolders = new string[] { "FBX", "Material", "Prefab", "Texture" };
    /// <summary>
    /// 游戏精灵资源的子目录
    /// </summary>
    static string[] GameSpriteSubFolders = new string[] { "Animation", "FBX", "Material", "Prefab", "Texture" };

    [MenuItem("Assets/Folder Creator/GameSprite Sub Folder")]
    static void CreateGameSpriteForlders()
    {
        CreateSubFolders(GameSpriteSubFolders);
    }

    [MenuItem("Assets/Folder Creator/UI Sub Folder")]
    static void CreateUIAssetSubForlders()
    {
        CreateSubFolders(UIAssetSubFolders);
    }

    [MenuItem("Assets/Folder Creator/Terrain Sub Folder")]
    static void CreateTerrainSubForlders()
    {
        CreateSubFolders(TerrainSubFolders);
    }

    static void CreateSubFolders(string[] folderNames)
    {
        string selectPath = GetCurrentSelectAssetPath();
        if (selectPath != null)
        {
            foreach (string item in folderNames)
            {
                if (AssetDatabase.IsValidFolder(selectPath + "/" + item))
                {
                    continue;
                }
                AssetDatabase.CreateFolder(selectPath, item);
            }
        }
    }

    static string GetCurrentSelectAssetPath()
    {
        string[] assetGUIDArray = Selection.assetGUIDs;
        if (assetGUIDArray.Length == 1)
        {
            string assetPath = AssetDatabase.GUIDToAssetPath(assetGUIDArray[0]);
            if (File.Exists(assetPath)) // 说明是文件，取其路径
            {
                assetPath = Path.GetDirectoryName(assetPath);
            }
            return assetPath;
        }
        return string.Empty;
    }
}
