using Common;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Net;
using UnityEngine;

namespace HotFix
{
    /// <summary>
    /// 下载文件缓存信息
    /// </summary>
    class DownloadCacheInfo
    {
        /// <summary>
        /// 初始化下载信息
        /// </summary>
        /// <param name="key"></param>
        public DownloadCacheInfo(string key, string fileName)
        {
            this.Key = key;
            this.FileName = fileName;
        }
        /// <summary>
        /// 唯一key
        /// </summary>
        public string Key { get; private set; }

        /// <summary>
        /// 文件名称
        /// </summary>
        public string FileName { get; set; }

        /// <summary>
        /// 远程路径字符串
        /// </summary>
        public string RemoteFileFullName
        {
            get
            {
                return FileUtility.GetAssetFilePath(FileName, PathType.Remote);
            }
        }

        /// <summary>
        /// 本地Cache 路径字符串
        /// </summary>
        public string CacheFileFullName
        {
            get
            {
                string cacheFullName = FileUtility.GetAssetFilePath(FileName, PathType.Cache);
                FileUtility.CreateDirectory(cacheFullName);
                return cacheFullName;
            }
        }

        /// <summary>
        /// 完成通知
        /// </summary>
        public Action<string, AsyncCompletedEventArgs> ComplatedCallBack { get; set; }

        /// <summary>
        /// 进度更新事件
        /// </summary>
        public Action<string, DownloadProgressChangedEventArgs> ProgressChanged { get; set; }
    }

    /// <summary>
    /// 远程下载client
    /// </summary>
    public class WebClientDownloader
    {
        /// <summary>
        /// 等待下载的队列
        /// </summary>
        static List<DownloadCacheInfo> m_WaitingDownloadList = new List<DownloadCacheInfo>();

        /// <summary>
        /// 锁的对象
        /// </summary>
        static object m_LockObject = new object();

        /// <summary>
        /// 当前下载的文件信息
        /// </summary>
        static DownloadCacheInfo m_CurrentDownload = null;

        /// <summary>
        /// WebClient 下载器
        /// </summary>
        static WebClient m_Downloader = null;

        /// <summary>
        /// 下载文件完成通知
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        static void DownloadFile_Complated(object sender, AsyncCompletedEventArgs e)
        {
            try
            {
                if (m_CurrentDownload != null && m_CurrentDownload.ComplatedCallBack != null)
                {
                    m_CurrentDownload.ComplatedCallBack(m_CurrentDownload.Key, e);
                }
            }
            catch (Exception ex)
            {
                Debug.LogException(ex);
            }
            finally
            {
                m_CurrentDownload = null;
                TryStartDownloadOneFile();
            }
        }

        /// <summary>
        /// 下载文件进度更新
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        static void DownloadFile_ProgressChanged(object sender, DownloadProgressChangedEventArgs e)
        {
            if (m_CurrentDownload != null && m_CurrentDownload.ProgressChanged != null)
            {
                try
                {
                    m_CurrentDownload.ProgressChanged(m_CurrentDownload.Key, e);
                }
                catch (Exception ex)
                {
                    Debug.LogException(ex);
                }
            }
        }

        /// <summary>
        /// 尝试下载文件
        /// </summary>
        static void TryStartDownloadOneFile()
        {
            if (m_CurrentDownload == null)
            {
                if (m_WaitingDownloadList.Count > 0)
                {
                    lock (m_LockObject)
                    {
                        m_CurrentDownload = m_WaitingDownloadList[0];
                        m_WaitingDownloadList.RemoveAt(0);
                    }
                    if (m_Downloader == null)
                    {
                        m_Downloader = new WebClient();
                        m_Downloader.DownloadFileCompleted += DownloadFile_Complated;
                        m_Downloader.DownloadProgressChanged += DownloadFile_ProgressChanged;
                    }
                    m_Downloader.DownloadFileAsync(new Uri(m_CurrentDownload.RemoteFileFullName), m_CurrentDownload.CacheFileFullName);
                }
                else
                {
                    ReleaseDownLoader();
                }
            }
        }

        /// <summary>
        /// 添加到下载队列中
        /// </summary>
        /// <param name="fileName">文件名称</param>
        /// <param name="complated">完成通知</param>
        /// <param name="progressChanged">进度更新</param>
        /// <returns></returns>
        public static void AppendDownloadFile(string fileName, Action<string, AsyncCompletedEventArgs> complated = null, Action<string, DownloadProgressChangedEventArgs> progressChanged = null)
        {
            DownloadCacheInfo cacheInfo = null;
            if (m_CurrentDownload != null && m_CurrentDownload.Key == fileName)
            {
                cacheInfo = m_CurrentDownload;
            }
            else
            {
                m_WaitingDownloadList.Find(temp => temp.Key == fileName);
            }

            if (cacheInfo == null)
            {
                cacheInfo = new DownloadCacheInfo(fileName, fileName);
                m_WaitingDownloadList.Add(cacheInfo);
            }
            if (complated != null)
            {
                if (cacheInfo.ComplatedCallBack != null)
                {
                    cacheInfo.ComplatedCallBack += complated;
                }
                else
                {
                    cacheInfo.ComplatedCallBack = complated;
                }
            }

            if (progressChanged != null)
            {
                if (cacheInfo.ProgressChanged != null)
                {
                    cacheInfo.ProgressChanged += progressChanged;
                }
                else
                {
                    cacheInfo.ProgressChanged = progressChanged;
                }
            }

            TryStartDownloadOneFile();
        }

        /// <summary>
        /// 释放下载器
        /// </summary>
        static void ReleaseDownLoader()
        {
            if (m_Downloader != null)
            {
                m_Downloader.Dispose();
                m_Downloader = null;
            }
        }

        /// <summary>
        /// 重置下载器
        /// </summary>
        public static void ResetDownLoader()
        {
            m_WaitingDownloadList.Clear();
            ReleaseDownLoader();
        }

        /// <summary>
        /// 停止下载
        /// </summary>
        public static void StopDownloader()
        {
            lock (m_LockObject)
            {
                for (int i = 0; i < m_WaitingDownloadList.Count; i++)
                {
                    DownloadCacheInfo cacheInfo = m_WaitingDownloadList[i];
                    if (cacheInfo.ComplatedCallBack != null)
                    {
                        try
                        {
                            m_CurrentDownload.ComplatedCallBack(m_CurrentDownload.Key, new AsyncCompletedEventArgs(null, true, null));
                        }
                        catch (Exception ex)
                        {
                            Debug.LogException(ex);
                        }
                    }
                }
                m_WaitingDownloadList.Clear();
            }
            if (m_Downloader != null)
            {
                m_Downloader.CancelAsync();
            }
        }

        /// <summary>
        /// 停止下载某个name文件
        /// </summary>
        /// <param name="fileName"></param>
        public static void StopDownloadFile(string fileName)
        {
            Debug.LogError(m_CurrentDownload.FileName);
            if (m_CurrentDownload != null && m_CurrentDownload.Key == fileName)
            {
                m_Downloader.CancelAsync();
            }
            else
            {
                lock (m_LockObject)
                {
                    DownloadCacheInfo cacheInfo = m_WaitingDownloadList.Find((temp) => fileName == temp.Key);
                    m_WaitingDownloadList.Remove(cacheInfo);
                    if (cacheInfo.ComplatedCallBack != null)
                    {
                        try
                        {
                            cacheInfo.ComplatedCallBack(cacheInfo.Key, new AsyncCompletedEventArgs(null, true, null));
                        }
                        catch (Exception ex)
                        {
                            Debug.LogException(ex);
                        }
                    }
                }
            }
        }
    }
}