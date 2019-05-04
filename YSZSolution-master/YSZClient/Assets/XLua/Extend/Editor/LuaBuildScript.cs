using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;

public class LuaBuildScript
{

    private static string LuaPathOfResource = Application.dataPath + "/Resources/" + LuaConst.LuaDirInResources;

    private static string LuaPathOfPrimitive = Application.dataPath + "/Primitives/" + LuaConst.LuaDirInResources;

    [MenuItem("XLua/Copy Lua  files to Resources", false, 51)]
    public static void CopyLuaFilesToRes()
    {
        ClearAllLuaFiles();
        CopyLuaBytesFiles(LuaConst.LuaDir, LuaPathOfResource);
        AssetDatabase.Refresh();
        Debug.LogFormat("Complated to Copy lua files to [{0}]", LuaPathOfResource);
    }

    [MenuItem("XLua/Clear Lua  files", false, 53)]
    public static void ClearAllCopyedLuaFiles()
    {
        ClearAllLuaFiles();
        AssetDatabase.Refresh();
        Debug.Log("Clear lua files over");
    }

    [MenuItem("XLua/Copy Lua  files to Primitive", false, 55)]
    public static void CopyToPrimitiveLuaPath()
    {
        ClearAllLuaFiles();
        CopyLuaBytesFiles(LuaConst.LuaDir, LuaPathOfPrimitive);
        AssetDatabase.Refresh(ImportAssetOptions.ForceUpdate);
        Debug.LogFormat("Complated to Copy lua files to [{0}]", LuaPathOfResource);
    }

    [MenuItem("XLua/Reset Lua files asset bundle name", false, 57)]
    public static void ResetLuaAssetBundleNames()
    {
        // 给下面的所有lua 文件标注 AssetBundle 名称
        string[] files = Directory.GetFiles(LuaPathOfPrimitive, "*.lua.bytes", SearchOption.AllDirectories);
        foreach (string file in files)
        {
            RefreshPrimitvesLuaAssetBundleName(FileUtil.GetProjectRelativePath(file).Replace('\\', '/').Replace("//", "/"));
        }
        AssetDatabase.Refresh(ImportAssetOptions.ForceUpdate);
        Debug.LogFormat("Refresh lua assets bundle names of path[{0}]", LuaPathOfResource);
    }

    [MenuItem("XLua/Copy Lua files to Primitive and Reset ab name", false, 59)]
    public static void CopyLuafliesAndResetLuaAssetBundleNames()
    {
        CopyToPrimitiveLuaPath();
        ResetLuaAssetBundleNames();
    }

    static void CopyLuaBytesFiles(string sourceDir, string destDir, bool appendExt = true, string searchPattern = "*.lua", SearchOption option = SearchOption.AllDirectories)
    {
        if (!Directory.Exists(sourceDir))
        {
            return;
        }

        string[] files = Directory.GetFiles(sourceDir, searchPattern, option);
        int len = sourceDir.Length;

        if (sourceDir[len - 1] == '/' || sourceDir[len - 1] == '\\')
        {
            --len;
        }

        for (int i = 0; i < files.Length; i++)
        {
            string str = files[i].Remove(0, len);
            string dest = destDir + "/" + str;
            if (appendExt) dest += ".bytes";
            string dir = Path.GetDirectoryName(dest);
            Directory.CreateDirectory(dir);
            File.Copy(files[i], dest, true);
        }
    }

    public static void RefreshPrimitvesLuaAssetBundleName(string relativePath)
    {
        AssetImporter assetImporter = AssetImporter.GetAtPath(relativePath);
        if (assetImporter == null)
        {
            Debug.LogFormat("Can't find lua asset with relative path[{0}]", relativePath);
            return;
        }
        assetImporter.assetBundleName = LuaConst.LuaAssetBundleName;
    }

    static void ClearAllLuaFiles()
    {
        if (Directory.Exists(LuaPathOfResource))
        {
            Directory.Delete(LuaPathOfResource, true);
        }

        if (Directory.Exists(LuaPathOfPrimitive))
        {
            Directory.Delete(LuaPathOfPrimitive, true);
        }
    }

    public static string GetOS()
    {
        return LuaConst.OSDir;
    }
}
