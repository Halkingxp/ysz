using UnityEngine;
using System.IO;
using System;
using System.Collections;
using System.Text;
#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Common
{
    public enum PathType
    {
        /// <summary>
        /// 本地
        /// </summary>
        Local = 0,
        /// <summary>
        /// 缓存
        /// </summary>
        Cache = 1,
        /// <summary>
        /// 远程
        /// </summary>
        Remote = 2,
        /// <summary>
        /// 资源初始路径
        /// </summary>
        InitData = 3,
    }

    /// <summary>
    /// 文件记录信息
    /// </summary>
    public class FileRecord
    {
        /// <summary>
        /// 文件名称
        /// </summary>
        public string FileName { get; set; }

        /// <summary>
        /// 文件MD5码
        /// </summary>
        public string MD5 { get; set; }

        /// <summary>
        /// 文件大小
        /// </summary>
        public long Size { get; set; }
    }

    public class FileUtility
    {
        /// <summary>
        /// 获取资源文件路径
        /// </summary>
        /// <param name="fileName"></param>
        /// <param name="pathType"></param>
        /// <returns></returns>
        public static string GetAssetFilePath(string fileName, PathType pathType)
        {
            string rootPath = string.Empty;
            switch (pathType)
            {
                case PathType.Cache:
                    rootPath = AppDefineConst.LOCAL_TEMP_PATH;
                    break;
                case PathType.Remote:
                    rootPath = AppDefineConst.REMOTE_DATA_PATH;
                    break;
                case PathType.InitData:
                    rootPath = AppDefineConst.LOCAL_INIT_DATA_PATH;
                    break;
                case PathType.Local:
                default:
                    rootPath = AppDefineConst.LOCAL_DATA_PATH;
                    break;
            }
            return string.Format("{0}/{1}", rootPath.TrimEnd('/'), fileName.TrimStart('/'));
        }

        /// <summary>
        /// 转换文件路径
        /// </summary>
        /// <param name="fullName">文件路径</param>
        /// <param name="from">原始路径</param>
        /// <param name="to">转换为的路径</param>
        /// <returns></returns>
        public static string ConvertAssetFilePath(string fullName, PathType from, PathType to)
        {
            string rootPath = string.Empty;
            switch (from)
            {
                case PathType.Cache:
                    rootPath = AppDefineConst.LOCAL_TEMP_PATH;
                    break;
                case PathType.Remote:
                    rootPath = AppDefineConst.REMOTE_DATA_PATH;
                    break;
                case PathType.InitData:
                    rootPath = AppDefineConst.LOCAL_INIT_DATA_PATH;
                    break;
                case PathType.Local:
                default:
                    rootPath = AppDefineConst.LOCAL_DATA_PATH;
                    break;
            }

            return GetAssetFilePath(fullName.Replace(rootPath, ""), to);
        }

        /// <summary>
        /// 读取文件内容
        /// </summary>
        /// <param name="fileName">文件的相对路径</param>
        /// <param name="pathType">文件类型(仅支持 Local 和 Cache)</param>
        /// <returns></returns>
        public static string ReadFileText(string fileName, PathType pathType)
        {
            string fileFullPath = GetAssetFilePath(fileName, pathType);
            return ReadFileTextByFullName(fileFullPath);
        }

        public static string ReadFileTextByFullName(string fileFillName)
        {
            if (File.Exists(fileFillName))
            {
                return File.ReadAllText(fileFillName);
            }
            else
            {
                return null;
            }
        }

        public static byte[] ReadFileBytes(string fileFullName)
        {
            if (File.Exists(fileFullName))
            {
                return File.ReadAllBytes(fileFullName);
            }
            else
            {
                return null;
            }
        }

        public static byte[] ReadFileBytes(string fileName, PathType pathType)
        {
            string fileFullPath = GetAssetFilePath(fileName, pathType);
            return ReadFileBytes(fileFullPath);
        }

        public static void CreateDirectory(string path)
        {
            string fileFullPath = Path.GetFullPath(path);
            string directoryName = Path.GetDirectoryName(fileFullPath);
            if (!Directory.Exists(directoryName))
                Directory.CreateDirectory(directoryName);
        }

        /// <summary>
        ///   拷贝文件
        /// </summary>
        public static bool CopyFile(string src, string dest, bool overwrite = false)
        {
            //不存在则返回
            if (!File.Exists(src))
                return false;

            //保证路径存在
            string directory = Path.GetDirectoryName(dest);
            if (!Directory.Exists(directory))
                Directory.CreateDirectory(directory);
            File.Copy(src, dest, overwrite);
            return true;
        }

        public static bool CopyFileByPathType(string fileName, PathType from, PathType to)
        {
            return CopyFile(GetAssetFilePath(fileName, from), GetAssetFilePath(fileName, to), true);
        }

        /// <summary>
        ///   创建本地AssetBundle文件
        /// </summary>
        /// <param name="path">文件全局路径</param>
        /// <param name="bytes">写入的内容.</param>
        /// <param name="length">写入长度.</param>
        static void CreateAssetbundleFile(string path, byte[] bytes, int length)
        {
            FileInfo t = new FileInfo(path);
            using (Stream sw = t.Open(FileMode.Create, FileAccess.ReadWrite))
            {
                if (bytes != null && length > 0)
                {
                    //以行的形式写入信息
                    sw.Write(bytes, 0, length);
                }
            }
        }

        /// <summary>
        ///   读取本地AssetBundle文件
        /// </summary>
        static IEnumerator LoadAssetbundleFromLocal(string path, string name)
        {
            WWW w = new WWW("file:///" + path + "/" + name);

            yield return w;

            if (w.isDone)
            {
                GameObject.Instantiate(w.assetBundle.mainAsset);
            }
        }

        /// <summary>
        ///   
        /// </summary>
        public static IEnumerator CopyStreamingAssetsToFile(string src, string dest)
        {
#if UNITY_EDITOR || UNITY_STANDALONE_WIN || UNITY_IPHONE
            src = "file:///" + src;
#endif
            using (WWW w = new WWW(src))
            {
                yield return w;

                if (string.IsNullOrEmpty(w.error))
                {
                    while (w.isDone == false)
                        yield return null;

                    FileUtility.WriteBytesToFile(dest, w.bytes, w.bytes.Length);
                }
                else
                {
                    Debug.LogWarningFormat("Copy steameing asset file[{0}] error[1]!", src, w.error);
                }
            }
        }

        /// <summary>
        /// 写入文件
        /// </summary>
        /// <param name="path">文件全局路径</param>
        /// <param name="text">写入的内容.</param>
        public static void WriteTextToFile(string path, string text)
        {
            var bytes = System.Text.Encoding.UTF8.GetBytes(text);
            WriteBytesToFile(path, bytes, bytes.Length);
        }

        /// <summary>
        /// 写入文件
        /// </summary>
        /// <param name="path">文件全局路径</param>
        /// <param name="bytes">写入的内容.</param>
        /// <param name="length">写入长度.</param>
        public static void WriteBytesToFile(string path, byte[] bytes, int length)
        {
            string directory = Path.GetDirectoryName(path);
            if (!Directory.Exists(directory))
                Directory.CreateDirectory(directory);

            FileInfo t = new FileInfo(path);
            using (Stream sw = t.Open(FileMode.Create, FileAccess.ReadWrite))
            {
                if (bytes != null && length > 0)
                {
                    //以行的形式写入信息
                    sw.Write(bytes, 0, length);
                }
            }
        }

        /// <summary>
        /// 判断文件是否存在
        /// </summary>
        /// <param name="fileName"></param>
        /// <returns></returns>
        public static bool ExistsFile(string fileName)
        {
            return File.Exists(fileName);
        }

        public static bool ExistsFileOfType(string fileName, PathType type)
        {
            return ExistsFile(GetAssetFilePath(fileName, type));
        }

        /// <summary>
        /// 判断文件夹是否存在
        /// </summary>
        /// <param name="path"></param>
        /// <returns></returns>
        public static bool ExistsDirectory(string path)
        {
            return Directory.Exists(path);
        }

        /// <summary>
        /// 获取文件的MD5码
        /// </summary>
        /// <param name="fileName"></param>
        /// <returns></returns>
        public static string GetMD5HashFromFile(string fileName, PathType type)
        {
            string fileFullName = GetAssetFilePath(fileName, type);
            return GetMD5HashOfFile(fileFullName);
        }

        /// <summary>
        /// 获取文件的MD5码
        /// </summary>
        /// <param name="fileFullName"></param>
        /// <returns></returns>
        public static string GetMD5HashOfFile(string fileFullName)
        {
            try
            {
                FileStream file = new FileStream(fileFullName, FileMode.Open);
                System.Security.Cryptography.MD5 md5 = new System.Security.Cryptography.MD5CryptoServiceProvider();
                byte[] retVal = md5.ComputeHash(file);
                file.Close();

                StringBuilder sb = new StringBuilder();
                for (int i = 0; i < retVal.Length; i++)
                {
                    sb.Append(retVal[i].ToString("x2"));
                }
                return sb.ToString();
            }
            catch (Exception ex)
            {
                Debug.LogException(ex);
                return null;
            }
        }

        public static bool DeleteFileOfType(string fileName, PathType pathType)
        {
            try
            {
                string fileFullName = GetAssetFilePath(fileName, pathType);
                if (File.Exists(fileFullName))
                {
                    File.Delete(fileFullName);
                }
                return true;
            }
            catch (Exception ex)
            {
                Debug.LogException(ex);
                return false;
            }
        }

        /// <summary>
        /// 删除文件.
        /// </summary>
        /// <param name="path">删除完整文件夹路径.</param>
        /// <param name="name">删除文件的名称.</param>
        public static void DeleteFile(string path, string name)
        {
            File.Delete(path + name);
        }
        /// <summary>
        /// 删除文件
        /// </summary>
        /// <param name="path"></param>
        /// <param name="filesName"></param>
        /// <returns></returns>
        public static bool DeleteFiles(string path, string filesName)
        {
            bool isDelete = false;
            try
            {
                if (Directory.Exists(path))
                {
                    if (File.Exists(path + "\\" + filesName))
                    {
                        File.Delete(path + "\\" + filesName);
                        isDelete = true;
                    }
                }
            }
            catch
            {
                return isDelete;
            }
            return isDelete;
        }

        /// <summary>
        /// 删除文件夹
        /// </summary>
        /// <param name="path"></param>
        /// <param name="recursive"></param>
        public static void DeleteDirectory(string path, bool recursive = true)
        {
            if (Directory.Exists(path))
            {
                Directory.Delete(path, recursive);
            }
        }

        /// <summary>
        /// 本地时候包含初始信息
        /// </summary>
        /// <returns></returns>
        public static bool IsLocalContainsInitRes()
        {
            // 本地数据目录时候包含
            return ExistsDirectory(AppDefineConst.LOCAL_DATA_PATH);
        }

        /// <summary>
        /// 存储文件记录信息
        /// </summary>
        /// <param name="saveFileName">存储路径</param>
        /// <param name="fileRecords">文件记录字典</param>
        public static void StoreFileRecords(string saveFileName, System.Collections.Generic.Dictionary<string, FileRecord> fileRecords)
        {
            StringBuilder content = new StringBuilder();
            content.AppendLine("<?xml version='1.0' standalone='yes' ?>");
            content.AppendLine("<FILES>");
            foreach (var item in fileRecords)
            {
                FileRecord record = item.Value;
                content.AppendLine("	<FILE>");
                content.AppendLine("		<NAME>" + record.FileName + "</NAME>");
                content.AppendLine("		<MD5>" + record.MD5 + "</MD5>");
                content.AppendLine("		<SIZE>" + record.Size + "</SIZE>");
                content.AppendLine("	</FILE>");
            }
            content.AppendLine("</FILES>");

            FileUtility.WriteTextToFile(saveFileName, content.ToString());
        }

    }
}