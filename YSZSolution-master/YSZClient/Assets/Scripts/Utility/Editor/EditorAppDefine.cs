using UnityEngine;

/// <summary>
/// 程序编辑定义
/// </summary>
public class EditorAppDefine
{
    /// <summary>
    /// UI 资源的根节点
    /// </summary>
    public static string UIAssetRoot = Application.dataPath + "/Primitives/UI";

    /// <summary>
    /// AssetBundle 文件的后缀名
    /// </summary>
    public static string AssetBundleExtension = ".abc";

    /// <summary>
    /// 界面导出的图片预制件根目录
    /// </summary>
    public static string UIExportSpritePrefabRoot = Application.dataPath + "/Primitives/UISpritePrefab";

    /// <summary>
    /// 音效资源根目录
    /// </summary>
    public static string AudioAssetRoot = Application.dataPath + "/Primitives/Audio";

    /// <summary>
    /// CSharp 脚本存放位置
    /// </summary>
    public static string CSharpScriptRoot = Application.dataPath + "/Scripts";
}