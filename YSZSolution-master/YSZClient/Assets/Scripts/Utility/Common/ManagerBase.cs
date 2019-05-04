//***************************************************************
// 脚本名称：
// 类创建人：
// 创建日期：
// 功能描述：
//***************************************************************
using UnityEngine;

namespace Common
{
    /// <summary>
    /// 单例管理器基类
    /// </summary>
    /// <typeparam name="T"></typeparam>
    public abstract class ManagerBase<T> : MonoBehaviour where T : ManagerBase<T>
    {
        private static T m_Instance = null;
        private static bool m_IsDestroyed = false;

        protected ManagerBase()
        {
            m_IsDestroyed = false;
        }

        /// <summary>
        /// Awake 函数
        /// </summary>
        protected virtual void Awake()
        {
        }

        /// <summary>
        /// OnDestroy 函数
        /// </summary>
        protected virtual void OnDestroy()
        {
            ShutDown();
        }

        /// <summary>
        /// 管理器实例
        /// </summary>
        public static T Instance
        {
            get
            {
                if (m_Instance == null && !m_IsDestroyed)
                {
                    m_Instance = GameObject.FindObjectOfType<T>();
                    if (m_Instance == null)
                    {
                        m_Instance = new GameObject("mgr::" + typeof(T).Name, typeof(T)).GetComponent<T>();
                    }

                    DontDestroyOnLoad(m_Instance);
                }

                return m_Instance;
            }
        }

        /// <summary>
        ///   确保在程序退出时销毁实例。
        /// </summary>
        protected virtual void OnApplicationQuit()
        {
            m_Instance = null;
            m_IsDestroyed = true;
        }

        private bool m_IsReady = false;
        /// <summary>
        /// 管理器时候已经就绪
        /// </summary>
        public bool IsReady
        {
            get { return m_IsReady; }
            protected set { m_IsReady = value; }
        }

        private bool m_IsLaunching = false;
        /// <summary>
        /// 启动中
        /// </summary>
        public bool IsLaunching
        {
            get { return m_IsLaunching; }
            protected set { m_IsLaunching = value; }
        }

        private bool m_LaunchFailed = false;
        /// <summary>
        /// 启动错误
        /// </summary>
        public bool LaunchFailed
        {
            get { return m_LaunchFailed; }
            protected set { m_LaunchFailed = value; }
        }

        private bool m_CanReLaunch = true;
        /// <summary>
        /// 能否重启管理器
        /// </summary>
        public bool CanReLaunch
        {
            get { return m_CanReLaunch; }
            protected set { m_CanReLaunch = value; }
        }

        /// <summary>
        /// 重启管理器
        /// </summary>
        public bool ReLaunch()
        {
            // 本身能重启且管理器已启动
            if (CanReLaunch && IsReady)
            {
                ShutDown();
                Launch();
                return true;
            }
            else
            {
                return false;
            }
        }

        /// <summary>
        /// 启动管理器
        /// </summary>
        public void Launch()
        {
            if (IsLaunching || IsReady) // 如果真正启动或者已经启动则返回
            {
                return;
            }

            IsLaunching = true;
            IsReady = false;
            LaunchFailed = false;
            LaunchProcess(LaunchFinished);
        }

        /// <summary>
        /// 启动管理器过程
        /// </summary>
        protected virtual void LaunchProcess(System.Action finished)
        {
            if (finished != null)
            {
                finished();
            }
        }

        /// <summary>
        /// 启动管理器完成
        /// </summary>
        protected virtual void LaunchFinished()
        {
            IsLaunching = false;
            IsReady = true;
        }

        /// <summary>
        /// 关闭管理器
        /// </summary>
        protected void ShutDown()
        {
            StopAllCoroutines();
            ShutdownProcess();
            IsLaunching = false;
            IsReady = false;
            LaunchFailed = false;
        }

        /// <summary>
        /// 关闭管理器过程
        /// </summary>
        protected virtual void ShutdownProcess()
        {
        }


    }
}