using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Common.AssetSystem
{
    /// <summary>
    /// AssetBundle 资源管理器
    /// </summary>
    public partial class AssetBundleManager : ManagerBase<AssetBundleManager>
    {

#if UNITY_EDITOR        
        static int m_SimulateAssetBundleInEditor = -1;
        static string kSimulateAssetBundles = "SimulateAssetBundles";
        /// <summary>
        /// 编辑器模式下是否模拟资源包加载方式？（不需要真正打出资源包，避免每改动一个资源都打一次包的过程）
        /// </summary>
        public static bool SimulateAssetBundleInEditor
        {
            get
            {
                if (m_SimulateAssetBundleInEditor == -1)
                {
                    m_SimulateAssetBundleInEditor = UnityEditor.EditorPrefs.GetBool(kSimulateAssetBundles, true) ? 1 : 0;
                }

                return m_SimulateAssetBundleInEditor != 0;
            }
            set
            {
                int newValue = value ? 1 : 0;
                if (newValue != m_SimulateAssetBundleInEditor)
                {
                    m_SimulateAssetBundleInEditor = newValue;
                    UnityEditor.EditorPrefs.SetBool(kSimulateAssetBundles, value);
                }
            }
        }

        private List<string> m_SimulateIgnoreAssetKeys = new List<string>(new[] { ".lua" });

#endif

        #region Manager Interface

        protected override void Awake()
        {
            base.Awake();
            Launch();
        }

        protected override void LaunchProcess(Action finished)
        {
            StartCoroutine(LaunchProcessCoroutine(finished));
        }

        IEnumerator LaunchProcessCoroutine(Action finished)
        {
            // 加载MainManifest            
            LoadLocalAssetBundleMainfest();
            // 加载资源记录文件
            LoadAssetRecord();
            // 加载预加载的ab 及相关
            if (this.MainManifest != null)
            {
                string[] assetBundleNames = this.MainManifest.GetAllAssetBundles();
                for (int i = 0; i < assetBundleNames.Length; i++)
                {
                    string assetBundleName = assetBundleNames[i];
                    if (assetBundleName.StartsWith("pre_"))
                    {
                        LoadAssetBundleAndDependencies(assetBundleName, true);
                        DisposeTemporaryAssetBundles(false, false);
                        yield return 1;
                    }
                }
            }
            finished();
        }

        protected override void ShutdownProcess()
        {
            UnloadAllAssetBundles(true);
            m_AssetRecordDict.Clear();
            this.MainManifest = null;

            base.ShutdownProcess();
        }

        #endregion

        /// <summary>
        /// Asset bundle 资源清单
        /// </summary>
        public AssetBundleManifest MainManifest { get; private set; }

        /// <summary>
        /// 资源信息池（资源名，资源所在的资源包名）
        /// </summary>
        private Dictionary<string, AssetRecordInfo> m_AssetRecordDict = new Dictionary<string, AssetRecordInfo>();

        /// <summary>
        /// 常驻的AssetBundle
        /// </summary>
        private Dictionary<string, AssetBundle> m_PermanentAssetBundleDict = new Dictionary<string, AssetBundle>();

        /// <summary>
        /// 缓存的AssetBundle
        /// </summary>
        private Dictionary<string, AssetBundle> m_CacheAssetBundleDict = new Dictionary<string, AssetBundle>();

        /// <summary>
        /// 临时的AssetBundle
        /// </summary>
        private Dictionary<string, AssetBundle> m_TemporaryAssetBundleDict = new Dictionary<string, AssetBundle>();

        enum AssetBundleDictType
        {
            Permanent = 1,
            Cache,
            Temporary,
        }

        #region Load Asset

        /// <summary>
        /// 同步加载一个资源
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="asset">资源名称，不关注大小写</param>
        /// <param name="unloadAssetBundle"></param>
        /// <param name="unloadAllLoadedObjects"></param>
        /// <returns></returns>
        public T LoadAsset<T>(string asset, bool unloadAssetBundle = true, bool unloadAllLoadedObjects = false) where T : UnityEngine.Object
        {
            try
            {
                if (!IsReady)
                    return null;
                T result = null;
                AssetRecordInfo assetRecord = GetAssetRecordInfoByAsset(asset);
                if (assetRecord == null)
                    return null;
#if UNITY_EDITOR
                if (SimulateAssetBundleInEditor)
                {
                    result = UnityEditor.AssetDatabase.LoadAssetAtPath<T>(assetRecord.RelativePath);
                }
                else
#endif
                {
                    AssetBundle assetBundle = LoadAssetBundleAndDependenciesByAsset(assetRecord);
                    if (assetBundle != null)
                    {
                        result = assetBundle.LoadAsset<T>(asset);
                        DisposeTemporaryAssetBundles(unloadAssetBundle, unloadAllLoadedObjects);
                    }
                }
                return result;
            }
            catch (System.Exception ex)
            {
                Debug.LogErrorFormat("AssetBundleManager.LoadAsset is falid!\n{0}", ex.Message);
            }
            return null;
        }

        /// <summary>
        /// 异步加载一个资源
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="assetName"></param>
        /// <param name="unloadAssetBundle"></param>
        /// <param name="unloadAllLoadedObjects"></param>
        /// <returns></returns>
        public LoadAssetAsyncOperation LoadAssetAsync<T>(string assetName, bool unloadAssetBundle = true, bool unloadAllLoadedObjects = false) where T : UnityEngine.Object
        {
            try
            {
                if (!IsReady)
                    return null;

                LoadAssetAsyncOperation operation = null;
                AssetRecordInfo assetRecord = GetAssetRecordInfoByAsset(assetName);
                if (assetRecord == null)
                    return null;

#if UNITY_EDITOR
                if (SimulateAssetBundleInEditor)
                {
                    T asset = UnityEditor.AssetDatabase.LoadAssetAtPath<T>(assetRecord.RelativePath);
                    operation = new LoadAssetAsyncOperation(asset);
                }
                else
#endif
                {
                    AssetBundle assetBundle = LoadAssetBundleAndDependenciesByAsset(assetRecord);
                    AssetBundleRequest request = null;
                    if (assetBundle != null)
                    {
                        request = assetBundle.LoadAssetAsync<T>(assetRecord.AssetName);
                        DisposeTemporaryAssetBundles(unloadAssetBundle, unloadAllLoadedObjects);
                    }
                    operation = new LoadAssetAsyncOperation(request);
                }
                return operation;
            }
            catch (System.Exception ex)
            {
                Debug.LogErrorFormat("AssetBundleManager.LoadAsset is falid!\n{0}", ex.Message);
            }
            return null;
        }

        /// <summary>
        /// 加载本地的Mainfest 文件
        /// </summary>
        void LoadLocalAssetBundleMainfest()
        {
#if UNITY_EDITOR
            if (SimulateAssetBundleInEditor)// 模拟运行时不需要加载本地Mainfest 文件
            {
                return;
            }
#endif
            AssetBundle assetBundle = LoadAssetBundle(AppDefineConst.AssetBundleManifestName, false);
            if (assetBundle != null)
            {
                this.MainManifest = assetBundle.LoadAsset<AssetBundleManifest>("AssetBundleManifest");
                assetBundle.Unload(false);
            }
            if (this.MainManifest == null)
            {
                Debug.LogError("LoadLocalAssetBundleMainfest: the MainManifest was null, please check and fix it!");
            }
        }

        /// <summary>
        /// 通过 资源名 获取AssetBundle名称
        /// </summary>
        /// <param name="assetName">资源名</param>
        /// <returns></returns>
        string GetAssetBundleNameByAsset(string assetName)
        {
            if (m_AssetRecordDict.ContainsKey(assetName))
            {
                return m_AssetRecordDict[assetName].AssetBundleName;
            }
            else
            {
                return m_AssetRecordDict[assetName].RelativePath;
            }
        }

        /// <summary>
        /// 获取资源记录信息
        /// </summary>
        /// <param name="assetRecordKey"></param>
        /// <returns></returns>
        AssetRecordInfo GetAssetRecordInfoByAsset(string assetRecordKey)
        {
#if UNITY_EDITOR
            if (SimulateAssetBundleInEditor)
            {
                foreach (string ignoreKey in m_SimulateIgnoreAssetKeys)
                {
                    if (assetRecordKey.Contains(ignoreKey))
                        return null;
                }
            }
#endif
            if (m_AssetRecordDict.ContainsKey(assetRecordKey))
            {
                return m_AssetRecordDict[assetRecordKey];
            }
            else
            {
                Debug.LogErrorFormat("Can't find asset record key[{0}] in AssetRecords, please check it!", assetRecordKey);
                return null;
            }
        }

        /// <summary>
        /// 加载AB 包 并加载所有的依赖项
        /// </summary>
        /// <param name="assetName"></param>
        /// <returns></returns>
        AssetBundle LoadAssetBundleAndDependenciesByAsset(AssetRecordInfo assetRecord)
        {
            if (assetRecord == null)
                return null;
            // 加载所有的依赖项
            return LoadAssetBundleAndDependencies(assetRecord.AssetBundleName, false);
        }

        /// <summary>
        /// 加载AssetBundle和相关的依赖项
        /// </summary>
        /// <param name="assetBundleName"></param>
        /// <returns></returns>
        AssetBundle LoadAssetBundleAndDependencies(string assetBundleName, bool isPreLoadAssetBundle)
        {
            if (MainManifest == null)
                return null;
            string[] dependencies = MainManifest.GetAllDependencies(assetBundleName);

            for (int index = 0; index < dependencies.Length; index++)
            {
                if (LoadAssetBundle(dependencies[index], isPreLoadAssetBundle) == null)
                {
                    Debug.LogErrorFormat("{0}'s Dependencie AssetBundle can't find. Name is {1}, please check it!", assetBundleName, dependencies[index]);
                    return null;
                }
            }
            return LoadAssetBundle(assetBundleName, isPreLoadAssetBundle);
        }

        /// <summary>
        /// 加载 AssetBundle
        /// </summary>
        /// <param name="assetBundleName">AssetBundle 名称</param>
        /// <param name="isPreLoadAssetBundle">是否预先加载的assetBundle</param>
        /// <returns></returns>
        AssetBundle LoadAssetBundle(string assetBundleName, bool isPreLoadAssetBundle)
        {
            AssetBundle assetBundle = null;
            // 判断常驻资源字典中是否存在
            if (m_PermanentAssetBundleDict.ContainsKey(assetBundleName))
            {
                assetBundle = m_PermanentAssetBundleDict[assetBundleName];
                if (assetBundle != null)
                    return assetBundle;
                else
                    m_PermanentAssetBundleDict.Remove(assetBundleName);
            }
            // 判断缓存资源字典中是否存在
            if (m_CacheAssetBundleDict.ContainsKey(assetBundleName))
            {
                assetBundle = m_CacheAssetBundleDict[assetBundleName];
                if (assetBundle != null)
                    return assetBundle;
                else
                    m_CacheAssetBundleDict.Remove(assetBundleName);
            }
            //判断临时资源字典中是否存在
            if (m_TemporaryAssetBundleDict.ContainsKey(assetBundleName))
            {
                assetBundle = m_TemporaryAssetBundleDict[assetBundleName];
                if (assetBundle != null)
                    return assetBundle;
                else
                    m_TemporaryAssetBundleDict.Remove(assetBundleName);
            }

            assetBundle = InternalLoadAssetBundleFromFile(assetBundleName);

            if (assetBundle != null)
            {
                // 将资源添加到不同的字典中
                if (IsPermanentAssetBundle(assetBundleName) || isPreLoadAssetBundle)
                {
                    m_PermanentAssetBundleDict.Add(assetBundleName, assetBundle);
                }
                else
                {
                    m_TemporaryAssetBundleDict.Add(assetBundleName, assetBundle);
                }
            }

            return assetBundle;
        }

        /// <summary>
        /// 是否是不销毁资源
        /// </summary>
        /// <param name="assetBundleName"></param>
        /// <returns></returns>
        bool IsPermanentAssetBundle(string assetBundleName)
        {
            return false;
        }

        /// <summary>
        /// 从文件加载 AssetBundle 文件
        /// </summary>
        /// <param name="assetBundleName"></param>
        /// <returns></returns>
        AssetBundle InternalLoadAssetBundleFromFile(string assetBundleName)
        {
            AssetBundle assetBundle = null;
            string assetBundleFullPath = GetAssetBundleFileFullPath(assetBundleName);
            byte[] fileContent = FileUtility.ReadFileBytes(assetBundleFullPath);
            if (fileContent != null)
            {
                if (AppDefineConst.IsEncrypted)
                {
                    fileContent = Utility.AESDecrypt(fileContent, AppDefineConst.AssetSecretKey);
                }
                assetBundle = AssetBundle.LoadFromMemory(fileContent);
            }
            return assetBundle;
        }

        /// <summary>
        /// 获取AssetBundle文件的全路径
        /// </summary>
        /// <param name="fileName"></param>
        /// <returns></returns>
        public static string GetAssetBundleFileFullPath(string fileName)
        {
#if UNITY_EDITOR
            if (!AppDefineConst.OpenHotfix) // 编辑器模式下，未开启热更时，加载初始路径资源
            {
                return string.Format("{0}/{1}/{2}", AppDefineConst.LOCAL_INIT_DATA_PATH, AppDefineConst.AssetBundlesPath, fileName);
            }
            else
#endif
            {
                return string.Format("{0}/{1}/{2}", AppDefineConst.LOCAL_DATA_PATH, AppDefineConst.AssetBundlesPath, fileName);
            }
        }

        #endregion

        #region Asset Record

        /// <summary>
        /// 加载资源记录文件
        /// </summary>
        void LoadAssetRecord()
        {
#if UNITY_EDITOR
            if (SimulateAssetBundleInEditor)
            {
                string[] assetBundleNameArray = UnityEditor.AssetDatabase.GetAllAssetBundleNames();
                for (int index = 0; index < assetBundleNameArray.Length; index++)
                {
                    string[] assetNameArray = UnityEditor.AssetDatabase.GetAssetPathsFromAssetBundle(assetBundleNameArray[index]);
                    for (int i = 0; i < assetNameArray.Length; i++)
                    {
                        string assetName = assetNameArray[i];
                        if (
                            // 预知件
                            assetName.EndsWith(".prefab")
                            // 二进制文件和 Lua 文件
                            || assetName.EndsWith(".bytes")
                            // 音效文件
                            || assetName.EndsWith(".wav") || assetName.EndsWith(".map") || assetName.EndsWith(".ogg")
                            )
                        {
                            string assetRecordKey = AssetRecordInfo.ToAssetRecordKey(assetNameArray[i]);
                            if (m_AssetRecordDict.ContainsKey(assetRecordKey))
                            {
                                Debug.LogErrorFormat("Some asset with the same assetrecordkey[{0}], please check and fix it! in path:\n{1}\n{2}", assetRecordKey, m_AssetRecordDict[assetRecordKey].RelativePath, assetNameArray[i]);
                            }
                            else
                            {
                                m_AssetRecordDict.Add(assetRecordKey, new AssetRecordInfo(assetRecordKey, assetBundleNameArray[index], assetNameArray[i]));
                            }
                        }
                    }
                }
            }
            else
#endif
            {
                byte[] contentBytes = FileUtility.ReadFileBytes(GetAssetBundleFileFullPath(AppDefineConst.AssetRecordsFileName));

                if (AppDefineConst.IsEncrypted)
                {
                    contentBytes = Utility.AESDecrypt(contentBytes, AppDefineConst.AssetSecretKey);
                }

                string fileContent = Utility.BytesToUTF8String(contentBytes);
                if (string.IsNullOrEmpty(fileContent))
                {
                    Debug.LogError("Load Asset Reocrds file error, please check and fix it!");
                    return;
                }

                string[] assetRecordInfoArray = fileContent.Split(new string[] { "#$" }, StringSplitOptions.RemoveEmptyEntries);
                for (int index = 0; index < assetRecordInfoArray.Length; index++)
                {
                    string[] recordItems = assetRecordInfoArray[index].Split(new string[] { "#@" }, StringSplitOptions.None);
                    if (recordItems.Length > 1)
                    {
                        string assetRecordKey = recordItems[0].Trim();
                        string assetBundleName = recordItems[1].Trim();
                        if (m_AssetRecordDict.ContainsKey(assetRecordKey))
                        {
                            Debug.LogErrorFormat("Some asset with the same assetrecordkey[{0}], please check and fix it! in assetBundleName:\n{1}\n{2}", assetRecordKey, m_AssetRecordDict[assetRecordKey].AssetBundleName, assetBundleName);
                        }
                        else
                        {
                            m_AssetRecordDict.Add(assetRecordKey, new AssetRecordInfo(assetRecordKey, assetBundleName));
                        }
                    }
                }
            }
        }

        #endregion

        #region Unload AssetBundle

        /// <summary>
        /// 释放所有的AssetBundle 资源
        /// </summary>
        /// <param name="unloadAllLoadedObjects"></param>
        public void UnloadAllAssetBundles(bool unloadAllLoadedObjects)
        {
            UnloadAssetBundles(unloadAllLoadedObjects, AssetBundleDictType.Temporary);
            UnloadAssetBundles(unloadAllLoadedObjects, AssetBundleDictType.Cache);
            UnloadAssetBundles(unloadAllLoadedObjects, AssetBundleDictType.Permanent);
        }

        /// <summary>
        /// 释放对应字典中的 AssetBundle 资源
        /// </summary>
        /// <param name="unloadAllLoadedObjects"></param>
        /// <param name="dictType"></param>
        void UnloadAssetBundles(bool unloadAllLoadedObjects, AssetBundleDictType dictType)
        {
            Dictionary<string, AssetBundle> dict = null;
            switch (dictType)
            {
                case AssetBundleDictType.Permanent:
                    dict = m_PermanentAssetBundleDict;
                    break;
                case AssetBundleDictType.Cache:
                    dict = m_CacheAssetBundleDict;
                    break;
                case AssetBundleDictType.Temporary:
                    dict = m_TemporaryAssetBundleDict;
                    break;
                default:
                    break;
            }
            if (dict == null)
                return;

            var enumerator = dict.Values.GetEnumerator();
            while (enumerator.MoveNext())
            {
                if (enumerator.Current != null)
                {
                    enumerator.Current.Unload(unloadAllLoadedObjects);
                }
            }
            enumerator.Dispose();
            dict.Clear();
        }

        /// <summary>
        /// 释放掉AssetBundle
        /// </summary>
        /// <param name="assetBundleName"></param>
        /// <param name="unloadAllLoadedObjects"></param>
        public void UnloadAssetBundle(string assetBundleName, bool unloadAllLoadedObjects)
        {
            AssetBundle ab = null;
            if (m_PermanentAssetBundleDict.TryGetValue(assetBundleName, out ab))
                m_PermanentAssetBundleDict.Remove(assetBundleName);
            else if (m_CacheAssetBundleDict.TryGetValue(assetBundleName, out ab))
                m_CacheAssetBundleDict.Remove(assetBundleName);
            else if (m_TemporaryAssetBundleDict.TryGetValue(assetBundleName, out ab))
                m_TemporaryAssetBundleDict.Remove(assetBundleName);

            if (ab != null)
            {
                ab.Unload(unloadAllLoadedObjects);
            }
        }

        /// <summary>
        /// 保存临时资源到缓存资源字典
        /// </summary>
        void SaveTemporaryAssetBundlesToCache()
        {
            var enumerator = m_TemporaryAssetBundleDict.GetEnumerator();
            while (enumerator.MoveNext())
            {
                m_CacheAssetBundleDict.Add(enumerator.Current.Key, enumerator.Current.Value);
            }
            enumerator.Dispose();
            m_TemporaryAssetBundleDict.Clear();
        }

        /// <summary>
        /// 释放临时资源
        /// </summary>
        /// <param name="unloadAssetBundle">是否释放资源，不释放，则放入缓存字典中</param>
        /// <param name="unloadAllLoadedObjects"></param>
        void DisposeTemporaryAssetBundles(bool unloadAssetBundle, bool unloadAllLoadedObjects)
        {
            if (unloadAssetBundle)
                UnloadAssetBundles(unloadAllLoadedObjects, AssetBundleDictType.Temporary);
            else
                SaveTemporaryAssetBundlesToCache();
        }

        #endregion


    }

    public class AssetRecordInfo
    {
        public AssetRecordInfo(string assetKey, string assetBundleName)
            : this(assetKey, assetBundleName, null)
        {
        }

        public AssetRecordInfo(string assetKey, string assetBundleName, string relativePath)
        {
            this.AssetName = assetKey;
            this.AssetBundleName = assetBundleName;
            this.RelativePath = relativePath;
        }

        /// <summary>
        /// 资源名称
        /// </summary>
        public string AssetName { get; private set; }

        /// <summary>
        /// 包名称
        /// </summary>
        public string AssetBundleName { get; private set; }

        /// <summary>
        /// 相对路径
        /// </summary>
        public string RelativePath { get; private set; }

        public static string ToAssetRecordKey(string fileName)
        {
            fileName = fileName.Replace('\\', '/');
            int lastIndex = fileName.LastIndexOf('/');
            string recordKey = string.Empty;
            if (lastIndex > -1)
            {
                recordKey = fileName.Substring(lastIndex + 1);
            }
            else
            {
                recordKey = fileName;
            }

            if (recordKey.Contains("."))
            {
                recordKey = recordKey.Substring(0, recordKey.LastIndexOf('.'));
            }

            return recordKey;
        }
    }
}
