using Common;
using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.Security;
using UnityEngine;

namespace HotFix
{
    public enum HotFixUpdaterState
    {
        /// <summary>
        /// 无
        /// </summary>
        None = 0,
        /// <summary>
        /// 载入本地版本文件
        /// </summary>
        LoadLocalVersionFile,
        /// <summary>
        /// 载入本地资源清单文件
        /// </summary>
        LoadLocalFileRecords,
        /// <summary>
        /// 载入远程资源清单资源包
        /// </summary>
        LoadRemoteVersionFile,
        /// <summary>
        /// 载入远程资源清单文件
        /// </summary>
        LoadRemoteFileRecords,
        /// <summary>
        /// 下载资源状态
        /// </summary>
        DownloadData,
        /// <summary>
        /// 清理过期资源
        /// </summary>
        ClearObsoleteAssets,
        /// <summary>
        /// 校验本地数据
        /// </summary>
        ValidateLocalData,
        /// <summary>
        /// 完成
        /// </summary>
        Done,
        /// <summary>
        /// 失败
        /// </summary>
        Failed,
    }

    /// <summary>
    /// 进度更新事件的参数
    /// </summary>
    public class HotfixProgressChangedEventArgs : EventArgs
    {
        public HotfixProgressChangedEventArgs(int progressPercentage, string tipsContent)
        {
            this.ProgressPercentage = progressPercentage;
            this.TipsContent = tipsContent;
        }

        /// <summary>
        /// 进度百分比
        /// </summary>
        public int ProgressPercentage { get; private set; }

        /// <summary>
        /// 提示的信息
        /// </summary>
        public string TipsContent { get; private set; }

        /// <summary>
        /// 用户自定义数据
        /// </summary>
        public object UserData { get; private set; }

    }

    public class HotFixUpdate : Kernel<HotFixUpdate>
    {
        const string DEFAULT_VERSION = "0.0.0";
        /// <summary>
        /// 进度更新事件
        /// </summary>
        public static event EventHandler<HotFix.HotfixProgressChangedEventArgs> HotfixProgressChangedEvent = null;

        /// <summary>
        /// 是否工作中
        /// </summary>
        public bool IsWorking { get; private set; }

        /// <summary>
        /// 是否载入了新的资源文件
        /// </summary>
        public bool IsLoadedNewAsset { get; private set; }

        private HotFixUpdaterState m_UpdaterState = HotFixUpdaterState.None;
        /// <summary>
        /// 是否是验证过的资源
        /// </summary>
        public bool IsValidatedAssets { get; private set; }

        /// <summary>
        /// 能否重试的更新错误
        /// </summary>
        private bool m_CanRetryUpdateFaild = true;

        /// <summary>
        /// 更新器的状态
        /// </summary>
        public HotFixUpdaterState UpdaterState
        {
            get { return m_UpdaterState; }
            private set
            {
                if (m_UpdaterState != value)
                {
                    Debug.LogWarningFormat("HotfixUpdater state:[{0}] ====>[{1}]", m_UpdaterState, value);
                }
                m_UpdaterState = value;
            }
        }

        /// <summary>
        /// 远程版本号
        /// </summary>
        private string m_LocalVersion = string.Empty;
        /// <summary>
        /// 本地版本号
        /// </summary>
        private string m_RemoteVersion = string.Empty;
        /// <summary>
        /// 本地安装包版本号
        /// </summary>
        private string m_InitVersion = string.Empty;

        /// <summary>
        /// 版本文件名称
        /// </summary>
        public const string VERSION_FILENAME = "version.txt";

        /// <summary>
        /// 文件列表文件名称
        /// </summary>
        public const string FILERECORD_FILENAME = "FileList.xml";

        /// <summary>
        /// 本地文件记录
        /// </summary>
        private Dictionary<string, FileRecord> m_LocalFileRecords = new Dictionary<string, FileRecord>();

        /// <summary>
        /// 远程文件记录
        /// </summary>
        private Dictionary<string, FileRecord> m_RemoteFileRecords = new Dictionary<string, FileRecord>();

        /// <summary>
        /// 需要更新的文件记录
        /// </summary>
        private List<FileRecord> m_NeedUpdateFileRecords = new List<FileRecord>();

        private int m_NeedDownCount = 0;

        /// <summary>
        /// 下一个进入的状态
        /// </summary>
        HotFixUpdaterState m_NextUpdateState = HotFixUpdaterState.None;
        /// <summary>
        /// 热更状态切换
        /// </summary>
        /// <param name="state"></param>
        void HotfixUpdaterSwitchToState(HotFixUpdaterState state)
        {
            m_NextUpdateState = state;
        }

        /// <summary>
        /// 热更失败状态切换
        /// </summary>
        /// <param name="canRetryUpdateFaild"></param>
        void HotfixUpdaterSwitchToFaildState(bool canRetryUpdateFaild = true)
        {
            this.m_CanRetryUpdateFaild = canRetryUpdateFaild;
            HotfixUpdaterSwitchToState(HotFixUpdaterState.Failed);
        }

        private void Update()
        {
            if (!IsWorking || m_NextUpdateState == HotFixUpdaterState.None || m_NextUpdateState == UpdaterState)
            {
                return;
            }

            UpdaterState = m_NextUpdateState;
            m_NextUpdateState = HotFixUpdaterState.None;

            switch (UpdaterState)
            {
                case HotFixUpdaterState.None:
                    break;
                case HotFixUpdaterState.LoadLocalVersionFile:
                    NotifyHotFixUpdateProgressChanged("校验版本信息", 20);
                    StartLoadLocalVersionFile();
                    break;
                case HotFixUpdaterState.LoadLocalFileRecords:
                    NotifyHotFixUpdateProgressChanged("校验版本信息", 40);
                    StartLoadLocalRecordFile();
                    break;
                case HotFixUpdaterState.LoadRemoteVersionFile:
                    NotifyHotFixUpdateProgressChanged("校验版本信息", 70);
                    StartLoadRemoteVersionFile();
                    break;
                case HotFixUpdaterState.LoadRemoteFileRecords:
                    NotifyHotFixUpdateProgressChanged("校验版本信息", 80);
                    StartLoadRemoteRecordFile();
                    break;
                case HotFixUpdaterState.DownloadData:
                    StartDownLoadRemoteUpdatedAssets();
                    break;
                case HotFixUpdaterState.ClearObsoleteAssets:
                    StartClearObsoleteAssetOfDownload();
                    break;
                case HotFixUpdaterState.ValidateLocalData:
                    StartValidateLocalAssetFiles();
                    break;
                case HotFixUpdaterState.Done:
                    NotifyHotFixUpdateProgressChanged("校验版本信息", 100);
                    HotfixUpdateComplated();
                    break;
                case HotFixUpdaterState.Failed:
                    HotfixUpdateFaild();
                    break;
                default:
                    break;
            }
        }

        /// <summary>
        /// 重置本地文件记录
        /// </summary>
        /// <param name="fileRecords"></param>
        void RestoreLocalFileRecords(Dictionary<string, FileRecord> fileRecords)
        {
            FileUtility.StoreFileRecords(FileUtility.GetAssetFilePath(FILERECORD_FILENAME, PathType.Local), fileRecords);
        }

        /// <summary>
        /// 游戏退出接口
        /// </summary>
        private void OnApplicationQuit()
        {
            StopAllCoroutines();
            WebClientDownloader.StopDownloader();
        }

        #region  First StartUp

        /// <summary>
        /// 尝试从初始化目录更新资源
        /// </summary>        
        public IEnumerator TryUpdateAssetFromStreamingAssets()
        {
            // 拷贝包里的版本文件到本地
            yield return FileUtility.CopyStreamingAssetsToFile(FileUtility.GetAssetFilePath(HotFixUpdate.VERSION_FILENAME, PathType.InitData), FileUtility.GetAssetFilePath(HotFixUpdate.VERSION_FILENAME, PathType.Cache));
            m_InitVersion = FileUtility.ReadFileText(HotFixUpdate.VERSION_FILENAME, PathType.Cache);
            if (FileUtility.ExistsFile(FileUtility.GetAssetFilePath(VERSION_FILENAME, PathType.Local)))
            {
                m_LocalVersion = FileUtility.ReadFileText(VERSION_FILENAME, PathType.Local);
            }
            else
            {
                m_LocalVersion = DEFAULT_VERSION;
            }
            // 比较本地版本号和本地安装包的版本号            
            if (CheckVersion(m_InitVersion, m_LocalVersion) != -1)
            {
                // 拷贝包里的资源记录文件到本地
                yield return FileUtility.CopyStreamingAssetsToFile(FileUtility.GetAssetFilePath(HotFixUpdate.FILERECORD_FILENAME, PathType.InitData), FileUtility.GetAssetFilePath(HotFixUpdate.FILERECORD_FILENAME, PathType.Cache));
                string initRecordFileName = FileUtility.GetAssetFilePath(HotFixUpdate.FILERECORD_FILENAME, PathType.Cache);
                if (!FileUtility.ExistsFile(initRecordFileName))
                {
                    Application.Quit();
                }
                else
                {
                    string initRecordContent = FileUtility.ReadFileText(HotFixUpdate.FILERECORD_FILENAME, PathType.Cache);
                    var initFileRecords = ConvertToFileRecords(initRecordContent);
                    string localRecordContent = FileUtility.ReadFileText(FILERECORD_FILENAME, PathType.Local);
                    Dictionary<string, FileRecord> localFileRecords = new Dictionary<string, FileRecord>();
                    if (localRecordContent != null)
                    {
                        localFileRecords = ConvertToFileRecords(localRecordContent);
                    }
                    // 筛选出对应需要更新的文件记录信息
                    var needUpdateFileRecords = FilterNeedUpdateFileRecodes(initFileRecords, localFileRecords);
                    if (needUpdateFileRecords.Count > 0)
                    {
                        float deltaProgessValue = 100f / needUpdateFileRecords.Count;
                        NotifyHotFixUpdateProgressChangedOfCopyAppAssets(0);
                        for (int index = 0; index < needUpdateFileRecords.Count; index++)
                        {
                            FileRecord fileRecord = needUpdateFileRecords[index];
                            string fromFileName = FileUtility.GetAssetFilePath(fileRecord.FileName, PathType.InitData);
                            string toFileName = FileUtility.GetAssetFilePath(fileRecord.FileName, PathType.Local);
                            yield return StartCoroutine(FileUtility.CopyStreamingAssetsToFile(fromFileName, toFileName));
                            if (FileUtility.ExistsFile(toFileName))
                            {
                                localFileRecords[needUpdateFileRecords[index].FileName] = needUpdateFileRecords[index];
                            }
                            else
                            {
                                localFileRecords[needUpdateFileRecords[index].FileName] = needUpdateFileRecords[index];
                                localFileRecords[needUpdateFileRecords[index].FileName].MD5 = "";
                            }
                            NotifyHotFixUpdateProgressChangedOfCopyAppAssets((int)(index * deltaProgessValue));
                        }
                    }

                    RestoreLocalFileRecords(localFileRecords);
                    // 拷贝初始目录的版本文件到本地
                    yield return StartCoroutine(FileUtility.CopyStreamingAssetsToFile(FileUtility.GetAssetFilePath(VERSION_FILENAME, PathType.InitData), FileUtility.GetAssetFilePath(VERSION_FILENAME, PathType.Local)));
                    // 清理过期资源                    
                    yield return StartCoroutine(ClearObsoleteAssetData(initFileRecords, localFileRecords));
                }
            }
        }

        /// <summary>
        /// 首次加载进度提示
        /// </summary>
        /// <param name="progressPercentage"></param>
        void NotifyHotFixUpdateProgressChangedOfCopyAppAssets(int progressPercentage)
        {
            NotifyHotFixUpdateProgressChanged(string.Format("首次加载耗时较长，请耐心等待({0}%)", progressPercentage.ToString().PadLeft(2, ' ')), progressPercentage);
        }

        #endregion

        #region Update Remote Assets

        /// <summary>
        /// 尝试从远程服务器更新资源
        /// </summary>
        /// <returns></returns>
        public void TryStartUpdateRemoteAssetsToLocal()
        {
            IsWorking = true;
            IsLoadedNewAsset = false;
            m_NextUpdateState = HotFixUpdaterState.None;
            UpdaterState = HotFixUpdaterState.None;

            m_LocalFileRecords.Clear();
            m_RemoteFileRecords.Clear();
            m_NeedUpdateFileRecords.Clear();
            m_NeedDownCount = 0;
            m_RemoteVersion = m_LocalVersion = DEFAULT_VERSION;
            IsValidatedAssets = false;
            HotfixUpdaterSwitchToState(HotFixUpdaterState.LoadLocalVersionFile);
        }

        #region Load local version file

        /// <summary>
        /// 开始加载本地版本记录文件
        /// </summary>
        void StartLoadLocalVersionFile()
        {
            m_LocalVersion = FileUtility.ReadFileText(VERSION_FILENAME, PathType.Local);
            HotfixUpdaterSwitchToState(HotFixUpdaterState.LoadLocalFileRecords);
        }

        #endregion

        #region Load local record file

        /// <summary>
        /// 开始加载本地文件记录文件
        /// </summary>
        void StartLoadLocalRecordFile()
        {
            m_LocalFileRecords = ConvertToFileRecords(FileUtility.ReadFileText(FILERECORD_FILENAME, PathType.Local));
            HotfixUpdaterSwitchToState(HotFixUpdaterState.LoadRemoteVersionFile);
        }

        #endregion

        #region Download remote version file

        public void StartLoadRemoteVersionFile()
        {
            WebClientDownloader.AppendDownloadFile(VERSION_FILENAME, DownLoadVersionFile_Complated, null);
        }

        /// <summary>
        /// 远程版本文件下载完成
        /// </summary>
        /// <param name="fileName"></param>
        /// <param name="e"></param>
        void DownLoadVersionFile_Complated(string fileName, AsyncCompletedEventArgs e)
        {
            if (fileName != VERSION_FILENAME)
                return;

            if (e.Error != null)
            {
                Debug.LogErrorFormat("Load remote version error: {0} ", e.Error.Message);
                // 进入到本地文件校验环节
                HotfixUpdaterSwitchToState(HotFixUpdaterState.ValidateLocalData);
            }
            else if (e.Cancelled)
            {
                HotfixUpdaterSwitchToFaildState(true);
            }
            else
            {
                m_RemoteVersion = FileUtility.ReadFileText(VERSION_FILENAME, PathType.Cache);

                int versionResult = CheckVersion(m_RemoteVersion, m_LocalVersion);
                if (versionResult == 2)
                {
                    // 弹出 更新失败，需要前往重新下载游戏                    
                    HotfixUpdaterSwitchToFaildState(false);
                }
                else if (versionResult == 1)
                {
                    // 进入更新文件列表                    
                    HotfixUpdaterSwitchToState(HotFixUpdaterState.LoadRemoteFileRecords);
                }
                else
                {
                    HotfixUpdaterSwitchToState(HotFixUpdaterState.ValidateLocalData);
                }
            }
        }

        #endregion

        #region Download remote record file

        /// <summary>
        /// 开始加载远程的列表文件
        /// </summary>
        void StartLoadRemoteRecordFile()
        {
            WebClientDownloader.AppendDownloadFile(FILERECORD_FILENAME, DownLoadFileRecords_Complated, null);
        }

        /// <summary>
        /// 远程文件列表下载完成
        /// </summary>
        /// <param name="fileName"></param>
        /// <param name="e"></param>
        void DownLoadFileRecords_Complated(string fileName, AsyncCompletedEventArgs e)
        {
            if (fileName != FILERECORD_FILENAME) return;

            if (e.Error != null)
            {
                Debug.LogErrorFormat("Load remote records error: {0} ", e.Error.Message);
                HotfixUpdaterSwitchToFaildState(true);
            }
            else if (e.Cancelled)
            {
                HotfixUpdaterSwitchToFaildState(true);
            }
            else
            {
                m_RemoteFileRecords = ConvertToFileRecords(FileUtility.ReadFileText(FILERECORD_FILENAME, PathType.Cache));
                HotfixUpdaterSwitchToState(HotFixUpdaterState.DownloadData);
            }
        }

        #endregion

        #region Download remote asset files

        void StartDownLoadRemoteUpdatedAssets()
        {
            m_NeedUpdateFileRecords = FilterNeedUpdateFileRecodes(m_RemoteFileRecords, m_LocalFileRecords);
            if (m_NeedUpdateFileRecords.Count > 0)
            {
                m_NeedDownCount = m_NeedUpdateFileRecords.Count;
                for (int i = m_NeedUpdateFileRecords.Count - 1; i >= 0; i--)
                {
                    FileRecord record = m_NeedUpdateFileRecords[i];
                    WebClientDownloader.AppendDownloadFile(record.FileName, DownloadAssetFile_Complated, null);
                }
                IsLoadedNewAsset = true;
            }
            else
            {
                // 拷贝远程版本号到本地
                FileUtility.CopyFileByPathType(VERSION_FILENAME, PathType.Cache, PathType.Local);
                HotfixUpdaterSwitchToState(HotFixUpdaterState.ValidateLocalData);
            }
        }

        Queue<FileRecord> complatedFileRecords = new Queue<FileRecord>();
        /// <summary>
        /// 完成多少个之后回填本地记录信息
        /// </summary>
        int ComplatedDownloadSaveCount = 5;

        void DownloadAssetFile_Complated(string fileName, AsyncCompletedEventArgs e)
        {
            FileRecord record = m_NeedUpdateFileRecords.Find(temp => temp.FileName == fileName);
            if (record == null) return;

            if (e.Error != null)
            {
                Debug.LogErrorFormat("download remote file:[{0}] error[{1}]", fileName, e.Error.Message);
                WebClientDownloader.StopDownloader();
                HotfixUpdaterSwitchToFaildState(true);
            }
            else if (e.Cancelled)
            {
                HotfixUpdaterSwitchToFaildState(true);
            }
            else
            {
                m_NeedUpdateFileRecords.Remove(record);

                if (FileUtility.CopyFileByPathType(record.FileName, PathType.Cache, PathType.Local))
                {
                    complatedFileRecords.Enqueue(record);
                }
                int complatedCount = m_NeedDownCount - m_NeedUpdateFileRecords.Count;
                NotifyHotFixUpdateProgressChanged(string.Format("下载更新({0}/{1})", complatedCount, m_NeedDownCount), complatedCount * 100f / m_NeedDownCount);
                if (m_NeedUpdateFileRecords.Count == 0)
                {
                    DownloadComplatedRestore();
                    // 下载完成了
                    FileUtility.CopyFileByPathType(VERSION_FILENAME, PathType.Cache, PathType.Local);
                    HotfixUpdaterSwitchToState(HotFixUpdaterState.ClearObsoleteAssets);
                }
                else if (complatedFileRecords.Count >= ComplatedDownloadSaveCount)
                {
                    DownloadComplatedRestore();
                }
            }
        }

        /// <summary>
        /// 下载完成回存资源列表信息
        /// </summary>
        void DownloadComplatedRestore()
        {
            while (complatedFileRecords.Count > 0)
            {
                FileRecord record = complatedFileRecords.Dequeue();
                m_LocalFileRecords[record.FileName] = record;
            }

            RestoreLocalFileRecords(m_LocalFileRecords);
        }

        #endregion

        #region Clear obsolete asset files

        /// <summary>
        /// 清理下载时残留的资源信息
        /// </summary>
        void StartClearObsoleteAssetOfDownload()
        {
            StartCoroutine(ClearObsoleteAssetData(m_RemoteFileRecords, m_LocalFileRecords));
        }

        int PreFrameClearAssetCount = 20;
        /// <summary>
        /// 清理过期的资源信息
        /// </summary>
        /// <param name="newFileRecords"></param>
        /// <param name="oldFileRecords"></param>
        /// <returns></returns>
        IEnumerator ClearObsoleteAssetData(Dictionary<string, FileRecord> newFileRecords, Dictionary<string, FileRecord> oldFileRecords)
        {
            List<FileRecord> obsoleteList = FilterObsoleteFileRecodes(newFileRecords, oldFileRecords);
            int handleCount = 0;
            if (obsoleteList.Count > 0)
            {
                float deltaPercentage = 100f / obsoleteList.Count;
                for (int i = 0; i < obsoleteList.Count; i++)
                {
                    if (handleCount >= PreFrameClearAssetCount)
                    {
                        yield return 1;
                        handleCount = 0;
                        NotifyHotFixUpdateProgressChanged("清理资源...", i * deltaPercentage);
                    }
                    handleCount++;
                    if (FileUtility.DeleteFileOfType(obsoleteList[i].FileName, PathType.Local))
                    {
                        if (oldFileRecords.ContainsKey(obsoleteList[i].FileName))
                        {
                            oldFileRecords.Remove(obsoleteList[i].FileName);
                        }
                    }
                }
                obsoleteList.Clear();
                RestoreLocalFileRecords(oldFileRecords);
            }

            // 清理本地临时文件路径
            FileUtility.DeleteDirectory(AppDefineConst.LOCAL_TEMP_PATH, true);
            HotfixUpdaterSwitchToState(HotFixUpdaterState.ValidateLocalData);
        }

        #endregion

        #region Validate local asset files

        /// <summary>
        /// 校验本地资源文件
        /// </summary>
        void StartValidateLocalAssetFiles()
        {
            StartCoroutine(ValidateLoadAssetsCoroutine());
        }

        /// <summary>
        /// 每帧校验文件的最大数量
        /// </summary>
        const int PerFrameValidateMax = 5;

        IEnumerator ValidateLoadAssetsCoroutine()
        {
            bool isContainsErrorFile = false;

            if (m_LocalFileRecords.Count > 0)
            {
                int handleCount = 0;
                int index = 0;
                float deltaProgessValue = 100f / m_LocalFileRecords.Count;
                foreach (var item in m_LocalFileRecords)
                {
                    index++;
                    handleCount++;
                    if (handleCount < PerFrameValidateMax)
                    {
                        FileRecord record = item.Value;
                        // 文件不存在，MD5为空，或者不相等
                        if (!FileUtility.ExistsFileOfType(record.FileName, PathType.Local)
                            || string.IsNullOrEmpty(record.MD5)
                            || record.MD5 != FileUtility.GetMD5HashFromFile(record.FileName, PathType.Local))
                        {
                            Debug.LogErrorFormat("File error:{0}", record.FileName);
                            isContainsErrorFile = true;
                            record.MD5 = "";// 将MD5码置空，便于下次重新来过时可以更新到该资源
                        }
                    }
                    else
                    {
                        yield return 1;
                        NotifyHotFixUpdateProgressChanged("验证本地资源...", index * deltaProgessValue);
                        handleCount = 0;
                    }
                }
                NotifyHotFixUpdateProgressChanged("验证本地资源...", 100);
            }

            if (isContainsErrorFile)
            {
                RestoreLocalFileRecords(m_LocalFileRecords);
                // 验证资源失败
                HotfixUpdaterSwitchToFaildState(true);
            }
            else
            {
                HotfixUpdaterSwitchToState(HotFixUpdaterState.Done);
            }

        }

        #endregion

        #region 更新完成

        void HotfixUpdateComplated()
        {
            IsValidatedAssets = true;
            IsWorking = false;
        }

        #endregion

        #region 更新失败

        int m_UpdateFaildRetryTimes = 1;

        void HotfixUpdateFaild()
        {
            Debug.LogError("HotfixUpdateFaild");
            IsValidatedAssets = false;
            if (m_CanRetryUpdateFaild)
            {
                ShowRetryUpdaterFaildMessageBox();
            }
            else
            {
                ShowCannotUpdateFaildMessageBox();
            }
        }

        void ShowRetryUpdaterFaildMessageBox()
        {
            MessageBoxData boxData = new MessageBoxData();
            boxData.Title = "错误";
            boxData.Content = "更新资源错误，是否重试?";
            boxData.OKButtonName = "重试";
            boxData.CancelButtonName = "关闭";
            boxData.Style = MessageBoxStyle.OKCancel;
            boxData.CallBack = (result) =>
            {
                switch (result)
                {
                    case MessageBoxResult.OK:
                        if (this.m_UpdateFaildRetryTimes >= 3)
                        {
                            ShowCannotUpdateFaildMessageBox();
                        }
                        else
                        {
                            m_UpdateFaildRetryTimes++;
                            TryStartUpdateRemoteAssetsToLocal();
                        }
                        break;
                    case MessageBoxResult.Cancel:
                    default:
                        Application.Quit();
                        break;
                }
            };
            MessageBoxUI.Show(boxData, null);
        }

        /// <summary>
        /// 显示不能更新的错误提示
        /// </summary>
        void ShowCannotUpdateFaildMessageBox()
        {
            MessageBoxData boxData = new MessageBoxData();
            boxData.Title = "更新失败";
            boxData.Content = "客户端更新失败，请重新下载游戏包!";
            boxData.OKButtonName = "重新下载";
            boxData.CancelButtonName = "退出游戏";
            boxData.Style = MessageBoxStyle.OKCancel;
            boxData.CallBack = (result) =>
            {
                switch (result)
                {
                    case MessageBoxResult.OK:
                        Application.OpenURL(AppDefineConst.GameUrl);
                        Application.Quit();
                        break;
                    case MessageBoxResult.Cancel:
                    default:
                        Application.Quit();
                        break;
                }
            };
            MessageBoxUI.Show(boxData, null);
        }

        #endregion

        /// <summary>
        /// 校验版本号
        /// </summary>
        /// <param name="newVersionStr">新版本号</param>
        /// <param name="oldVersionStr">旧版本号</param>
        /// <returns>-1：不需要更新 0: 版本一致，1：更新，2：强制更新</returns>
        public static int CheckVersion(string newVersionStr, string oldVersionStr)
        {
            if (string.IsNullOrEmpty(newVersionStr))
                newVersionStr = DEFAULT_VERSION;
            if (string.IsNullOrEmpty(oldVersionStr))
                oldVersionStr = DEFAULT_VERSION;
            Version newVersion = new Version(newVersionStr);
            Version oldVersion = new Version(oldVersionStr);
            Debug.LogFormat("new:[{0}] old:[{1}]", newVersion, oldVersion);
            if (oldVersion < newVersion) // 旧的版本小于新的版本，需要更新
            {
                //1, 2 位版本号变化，需要强制重新下载 3, 4 位版本号变化，只需要更新
                if (oldVersion.Major != newVersion.Major)
                {
                    return 2;
                }
                else
                {
                    if (oldVersion.Minor != newVersion.Minor)
                    {
                        return 2;
                    }
                }
                return 1;
            }
            else if (oldVersion == newVersion)
            {
                return 0; // 旧版本和新版本一致，不需要更新
            }
            else
            {
                return -1; // 旧版本大于新版本，不需要更新
            }
        }

        /// <summary>
        /// 转换文件列表内容为文件记录信息
        /// </summary>
        /// <param name="content"></param>
        /// <returns></returns>
        public static Dictionary<string, FileRecord> ConvertToFileRecords(string content)
        {
            Dictionary<string, FileRecord> fileRecords = new Dictionary<string, FileRecord>();
            Mono.Xml.SecurityParser sp = new Mono.Xml.SecurityParser();
            if (string.IsNullOrEmpty(content))
                return fileRecords;
            sp.LoadXml(content);
            SecurityElement root = sp.ToXml();
            if (root.Children != null)
            {
                foreach (SecurityElement child in root.Children)
                {
                    SecurityElement fileName = child.SearchForChildByTag("NAME");
                    SecurityElement md5 = child.SearchForChildByTag("MD5");
                    SecurityElement size = child.SearchForChildByTag("SIZE");

                    if (fileName == null || md5 == null || size == null)
                    {
                        Debug.LogError("'FileList.xml' has error!");
                        continue;
                    }

                    FileRecord record = new FileRecord();
                    record.FileName = fileName.Text;
                    record.MD5 = md5.Text;
                    record.Size = long.Parse(size.Text);
                    fileRecords.Add(record.FileName, record);
                }
            }
            return fileRecords;
        }

        /// <summary>
        /// 筛选出过期的资源文件
        /// </summary>
        /// <returns></returns>
        List<FileRecord> FilterObsoleteFileRecodes(Dictionary<string, FileRecord> newFileRecords, Dictionary<string, FileRecord> oldFileRecords)
        {
            List<FileRecord> fileRecordList = new List<FileRecord>();
            // 筛选出需要更新的文件
            foreach (var item in oldFileRecords)
            {
                if (!newFileRecords.ContainsKey(item.Key))
                {
                    fileRecordList.Add(item.Value);
                }
            }

            return fileRecordList;
        }

        /// <summary>
        /// 筛选出需要更新的文件
        /// </summary>
        /// <returns></returns>
        List<FileRecord> FilterNeedUpdateFileRecodes(Dictionary<string, FileRecord> newFileRecords, Dictionary<string, FileRecord> oldFileRecords)
        {
            List<FileRecord> fileRecordList = new List<FileRecord>();
            // 筛选出需要更新的文件
            foreach (var item in newFileRecords)
            {
                if (oldFileRecords.ContainsKey(item.Key))
                {
                    if (oldFileRecords[item.Key].MD5 == item.Value.MD5)
                    {
                        continue;
                    }
                }
                fileRecordList.Add(item.Value);
            }

            return fileRecordList;
        }

        #endregion

        #region Notify Hotfix Progess Changed
        /// <summary>
        /// 热更进度变化
        /// </summary>
        /// <param name="tipsContent"></param>
        /// <param name="progressPercentage"></param>
        void NotifyHotFixUpdateProgressChanged(string tipsContent, float progressPercentage)
        {
            if (HotfixProgressChangedEvent != null)
            {
                HotfixProgressChangedEvent(this, new HotfixProgressChangedEventArgs((int)progressPercentage, tipsContent));
            }
        }

        #endregion

        /// <summary>
        /// 重新检查程序版本号
        /// </summary>
        public static void RecheckAppVersion(Action<int> checkComplated)
        {
            string localVersion = FileUtility.ReadFileText(VERSION_FILENAME, PathType.Local);
            Action<string, AsyncCompletedEventArgs> complated = (fileName, e) =>
             {
                 if (fileName != VERSION_FILENAME)
                 {
                     return;
                 }

                 string remoteVersion = localVersion;
                 if (e.Error != null)
                 {
                     Debug.LogErrorFormat("load remote version error:[{0}]", e.Error.Message);
                     remoteVersion = localVersion;
                 }
                 else if (!e.Cancelled)
                 {
                     remoteVersion = FileUtility.ReadFileText(VERSION_FILENAME, PathType.Cache);
                 }
                 if (checkComplated != null)
                 {
                     checkComplated(CheckVersion(remoteVersion, localVersion));
                 }
             };
            WebClientDownloader.AppendDownloadFile(VERSION_FILENAME, complated, null);
        }
    }
}