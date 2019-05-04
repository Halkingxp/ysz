using UnityEngine;

namespace Common.AssetSystem
{
    public class LoadAssetAsyncOperation : CustomYieldInstruction
    {
        private UnityEngine.Object m_Asset = null;

        private AssetBundleRequest m_AssetBundleRequest = null;

        /// <summary>
        /// 是否完成
        /// </summary>
        public bool IsDone { get; private set; }        

        public LoadAssetAsyncOperation(AssetBundleRequest request)
        {
            if (request != null)
            {
                this.m_AssetBundleRequest = request;
                this.IsDone = m_AssetBundleRequest.isDone;
            }
            else
            {
                IsDone = true;
            }
        }

        public LoadAssetAsyncOperation(Object asset)
        {
            this.m_Asset = asset;
            IsDone = true;
        }

        public override bool keepWaiting
        {
            get
            {
                if (!IsDone && m_AssetBundleRequest != null)
                {
                    IsDone = m_AssetBundleRequest.isDone;
                }

                return !IsDone;
            }
        }

        /// <summary>
        /// 获取资源
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <returns></returns>
        public T GetAsset<T>() where T : Object
        {
            if (!IsDone)
            {
                return null;
            }
            else
            {
                if (m_AssetBundleRequest != null)
                {
                    return m_AssetBundleRequest.asset as T;
                }
                else if (m_Asset != null)
                {
                    return m_Asset as T;
                }
                else
                {
                    return null;
                }
            }
        }
    }
}
